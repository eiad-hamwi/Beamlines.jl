# Tracking functions in this file to be moved to other package

#= Beamline does not know about particles going through it. =#
export Bunch, Linear, track!, ELECTRON, POSITRON, PROTON, ANTIPROTON

include("utils.jl")
include("types.jl")

struct Linear end

MAX_TEMPS(::Linear) = 1

function track!(bunch::Bunch{A}, bl::Beamline; work=nothing) where {A}
  # Preallocate the temporaries if not provided
  if isnothing(work)
    n_temps = 0
    for ele in bl.line
      cur_n_temps = MAX_TEMPS(ele.tracking_method) 
      n_temps = cur_n_temps > n_temps ? cur_n_temps : n_temps
    end
    N_particle = A == AoS ? size(bunch.v, 2) : size(bunch.v, 1)
    work = map(t->zeros(eltype(bunch.v), N_particle), 1:n_temps)
  end

  for ele in bl.line
    track!(bunch, ele; work=work)
  end
  return bunch
end

function track!(bunch::Bunch{A}, ele::LineElement; work=nothing) where {A}
  # Dispatch on the tracking method:
  return track!(bunch, ele, ele.tracking_method; work=work)
end

function track!(bunch::Bunch{A}, ele::LineElement, ::Linear; work=nothing) where {A}
  # Unpack the line element
  ma = ele.AlignmentParams
  bm = ele.BMultipoleParams
  bp = ele.BendParams
  L = ele.L
  Brho_ref = ele.Brho_ref

  # Function barrier (this function is now fully compiled)
  # For some reason, inlining this is faster/zero allocs
  # copy-paste is slower and so is @noinline so I guess LLVM is 
  # doing some kind of constant propagation while inlining this?
  return @inline _track_linear!(bunch, ma, bm, bp, L, Brho_ref; work=work)
end

# Don't do anything if no AlignmentParams

#=
# in = true for enter, false for exit

=#

function _track_linear!(
  bunch::Bunch{A}, 
  ma::Union{AlignmentParams,Nothing},
  bm::Union{BMultipoleParams,Nothing}, 
  bp::Union{BendParams,Nothing},
  L, 
  Brho_ref;
  work=nothing,
) where {A}

  if !isnothing(bp)
    error("Bend tracking not implemented yet")
  end
  v = A == AoS ? transpose(bunch.v) : bunch.v
  N_particle = size(v, 1)
  gamma_0 = calc_gamma(bunch.species, bunch.Brho_0)

  if !isnothing(ma)
    launch_kernel!(misalign!, N_particle, v, nothing, ma.x_offset, ma.y_offset, -1)
  end

  if isnothing(bm) || length(bm.bdict) == 0 # Drift
    launch_kernel!(linear_drift!, N_particle, v, nothing, L, gamma_0)
  else
    if length(bm.bdict) > 1 || !haskey(bm.bdict, 2)
      error("Currently only quadrupole tracking is supported")
    end

    bm1 = bm.bdict[2]
    if bm1.tilt != 0
      error("Currently multipole tilts not supported")
    end

    # Tracking should work with B-fields. The lattice has no understanding of a particle beam
    # or the different types of particles shooting through

    # The Bunch struct itself can store the normalization factor of its own phase space coordinates 
    # but that may in general be different from the lattice.

    # So we always just get the B-fields from the lattice
    B1 = bm1.strength
    if bm1.normalized
      B1 *= Brho_ref
    end
    if bm1.integrated
      B1 /= L
    end

    # Now get K1 from the bunch itself:
    K1 = B1/bunch.Brho_0

    if K1 >= 0
      fqi = 1 #v.x
      fpi = 2 #v.px
      dqi = 3 #v.y
      dpi = 4 #v.py
      sqrtk = sqrt(K1)
    else
      fqi = 3 #v.y
      fpi = 4 #v.py
      dqi = 1 #v.x
      dpi = 2 #v.px
      sqrtk = sqrt(-K1)
    end
    wq = isnothing(work) ? [zeros(eltype(v), N_particle)] : work
    launch_kernel!(linear_quad!, N_particle, v, wq, fqi, fpi, dqi, dpi, sqrtk, L, gamma_0)
  end

  if !isnothing(ma)
    launch_kernel!(misalign!, N_particle, v, nothing, ma.x_offset, ma.y_offset, 1)
  end

  return bunch
end

const REGISTER_SIZE = VectorizationBase.register_size()

@inline function launch_kernel!(f!::F, N_particle, v::A, work, args...) where {F,A}
  lanesize = Int(REGISTER_SIZE/sizeof(eltype(A))) # should be static
  if A <: SIMD.FastContiguousArray && eltype(A) <: SIMD.ScalarTypes && lanesize != 0 # do SIMD
    lane = VecRange{lanesize}(0)
    rmn = rem(N_particle, lanesize)
    N_SIMD = N_particle - rmn
    for i in 1:lanesize:N_SIMD
      f!(lane+i, N_particle, v, work, args...)
    end
    # Do the remainder
    for i in N_SIMD+1:N_particle
      f!(i, N_particle, v, work, args...)
    end
  else
    for i in 1:N_particle
      f!(i, N_particle, v, work, args...)
    end
  end
  return v
end

# sgn = -1 if entering, 1 if exiting
function misalign!(i, N_particle, v, work, x_offset, y_offset, sgn) #x_rot, y_rot, tilt,
  @assert last(i) <= N_particle "Out of bounds!"  # Use last because VecRange SIMD
  @assert sgn == -1 || sgn == 1 "Incorrect value for sgn (use -1 if entering, 1 if exiting)"
  @inbounds begin
    @FastGTPSA! v[i,1] += sgn*ma.x_offset
    @FastGTPSA! v[i,3] += sgn*ma.y_offset
  end
  return v
end

# Drift kernel
@inline function linear_drift!(i, N_particle, v, work, L, gamma_0)
  @assert last(i) <= N_particle "Out of bounds!"  # Use last because VecRange SIMD
  @inbounds begin
    @FastGTPSA! v[i,1] += v[i,2] * L
    @FastGTPSA! v[i,3] += v[i,4] * L
    @FastGTPSA! v[i,5] += v[i,6] * L/gamma_0
  end
  return v
end

# Quadrupole kernel
@inline function linear_quad!(i, N_particle, v, work, fqi, fpi, dqi, dpi, sqrtk, L, gamma_0)
  @assert last(i) <= N_particle "Out of bounds!"  # Use last because VecRange SIMD
  @assert all(t->t<=4 && t>=1, (fqi, fpi, dqi, dpi)) "Invalid focus/defocus indices for quadrupole"
  @assert length(work) >= 1 && length(work[1]) == N_particle "At least 1 work vector of length $N_particle is required for linear_quad!"
  @inbounds begin
    @FastGTPSA! work[1][i]  = 0 + v[i,fqi]
    @FastGTPSA! v[i,fqi] = cos(sqrtk*L)*v[i,fqi] + L*sincu(sqrtk*L)*v[i,fpi]
    @FastGTPSA! v[i,fpi] = -sqrtk*sin(sqrtk*L)*work[1][i] + cos(sqrtk*L)*v[i,fpi]
    @FastGTPSA! work[1][i]  = 0 + v[i,dqi]
    @FastGTPSA! v[i,dqi] = cosh(sqrtk*L)*v[i,dqi] + L*sinhcu(sqrtk*L)*v[i,dpi]
    @FastGTPSA! v[i,dpi] = sqrtk*sinh(sqrtk*L)*work[1][i] + cosh(sqrtk*L)*v[i,dpi]
    @FastGTPSA! v[i,5] = v[i,5] + v[i,6] * L/gamma_0
  end 
  return v
end