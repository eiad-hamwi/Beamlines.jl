# Tracking functions in this file to be moved to other package

#= Beamline does not know about particles going through it. =#

using StructArrays
export Bunch, Particle, Linear, track!, ELECTRON, POSITRON, PROTON, ANTIPROTON

include("utils.jl")
include("types.jl")

struct Linear end

MAX_TEMPS(::Linear) = 1

function track!(bunch::Bunch{A}, bl::Beamline, bunch0::Bunch{B}; work=deepcopy(bunch0)) where {A,B}
  # Preallocate the temporaries if not provided
  #=
  if isnothing(work)
    n_temps = 0
    for ele in bl.line
      cur_n_temps = MAX_TEMPS(ele.tracking_method) 
      n_temps = cur_n_temps > n_temps ? cur_n_temps : n_temps
    end
    work = map(t->zero(bunch.v.x), 1:n_temps)
  end
=#
  
  b1 = bunch
  for ele in bl.line
    @noinline track!(b1, ele, work; work=work)
    b1, work = work, b1
  end

  # if odd number of elements then bunch is good
  if iseven(length(bl.line))
    bunch.species = b1.species
    bunch.Brho_0 = b1.Brho_0
    #bunch.v .= b1.v
    copy!(bunch.v, b1.v)
  end
  return bunch
end

function track!(bunch::Bunch{A}, ele::LineElement, bunch0::Bunch{B}; work=nothing) where {A,B}
  # Dispatch on the tracking method:
  return track!(bunch, ele, bunch0, ele.tracking_method; work=work)
end

function track!(bunch::Bunch{A}, ele::LineElement, bunch0::Bunch{B}, ::Linear; work=nothing) where {A,B}
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
  return @inline _track_linear!(bunch, bunch0, ma, bm, bp, L, Brho_ref; work=work)
end

# Don't do anything if no AlignmentParams
misalign!(bunch::Bunch, ::Nothing, ::Bool) = bunch
#=
# in = true for enter, false for exit
function misalign!(bunch::Bunch, ma::AlignmentParams, in::Bool)
  if ma.x_rot != 0. || ma.y_rot != 0. || ma.tilt != 0.
    error("Rotational misalignments not implemented yet")
  end
  sgn = in ? -1 : 1
  for i in 1:length(bunch.v.x)
    @FastGTPSA! begin
      bunch.v.x[i] += sgn*ma.x_offset
      bunch.v.y[i] += sgn*ma.y_offset
    end
  end
  return bunch
end
=#

function _track_linear!(
  bunch::Bunch{A}, 
  bunch0::Bunch{B}, 
  ma,
  bm, 
  bp,
  L, 
  Brho_ref;
  work=nothing,
) where {A,B}
  if !isnothing(bp)
    error("Bend tracking not implemented yet")
  end
  v = A == AoS ? transpose(bunch.v) : bunch.v
  v0 = B == AoS ? transpose(bunch0.v) : bunch0.v

  @assert size(v,1) == size(v0,1) "Number of particles in input/output bunches do not match!"
  N_particle = size(v, 1)

  misalign!(bunch, ma, true)

  if isnothing(bm) || length(bm.bdict) == 0 # Drift
    @turbo for i in 1:N_particle
      v[i,1] = v0[i,1] + v0[i,2] * L
      v[i,3] = v0[i,3] + v0[i,4] * L
    end
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
      fq = 1 #v.x
      fp = 2 #v.px
      dq = 3 #v.y
      dp = 4 #v.py
      sqrtk = sqrt(K1)
    else
      fq = 3 #v.y
      fp = 4 #v.py
      dq = 1 #v.x
      dp = 2 #v.px
      sqrtk = sqrt(-K1)
    end

    @turbo for i in 1:N_particle
      v[i,fq] = cos(sqrtk*L)*v0[i,fq] + L*sincu(sqrtk*L)*v0[i,fp]
      v[i,fp] = -sqrtk*sin(sqrtk*L)*v0[i,fq] + cos(sqrtk*L)*v0[i,fp]
      v[i,dq] = cosh(sqrtk*L)*v0[i,dq] + L*sinhcu(sqrtk*L)*v0[i,dp]
      v[i,dp] = sqrtk*sinh(sqrtk*L)*v0[i,dq] + cosh(sqrtk*L)*v0[i,dp]
    end
  end

  misalign!(bunch, ma, false)
  return bunch
end

