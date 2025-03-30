# Tracking functions in this file to be moved to other package

#= Beamline does not know about particles going through it. =#

using StructArrays
export Bunch, Particle, Linear, track!, ELECTRON, POSITRON, PROTON, ANTIPROTON

include("utils.jl")
include("types.jl")

struct Linear end

MAX_TEMPS(::Linear) = 1

function track!(bunch::Bunch, bl::Beamline; work=nothing)
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
  for ele in bl.line
    @noinline track!(bunch, ele; work=work)
  end
  return bunch
end

function track!(bunch::Bunch, ele::LineElement; work=work)
  # Dispatch on the tracking method:
  return track!(bunch, ele, ele.tracking_method; work=work)
end

function track!(bunch::Bunch, ele::LineElement, ::Linear; work=nothing)
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
misalign!(bunch::Bunch, ::Nothing, ::Bool) = bunch

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

function _track_linear!(
  bunch::Bunch{A}, 
  ma,
  bm, 
  bp,
  L, 
  Brho_ref;
  work=nothing,
) where {A}
  if !isnothing(bp)
    error("Bend tracking not implemented yet")
  end

  N_particle = A == AoS ? size(bunch.v, 2) : size(bunch.v, 1)

  misalign!(bunch, ma, true)

  v = bunch.v

  if isnothing(bm) || length(bm.bdict) == 0 # Drift
    for i in 1:N_particle
      p = A == AoS ? view(bunch.v, :, i) : view(bunch.v, i, :)
      @FastGTPSA! begin
        p[1] += p[2] * L
        p[3] += p[4] * L
      end
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

    # One temporary array, for 1000 Floats is 3 allocations on Julia v1.11
    
    tmp = zero(first(bunch.v))
    #isnothing(work) ? zero(bunch.v.x) : work[1]

    # copy and copy! behavior by GTPSA may be modified in future (weirdness 
    # because TPS is mutable). For now 0 + with FastGTPSA! is workaround.
    for i in 1:N_particle
      p = A == AoS ? view(bunch.v, :, i) : view(bunch.v, i, :)
      @FastGTPSA! begin
        tmp = 0 + p[fq]
        p[fq] = cos(sqrtk*L)*p[fq] + L*sincu(sqrtk*L)*p[fp]
        p[fp] = -sqrtk*sin(sqrtk*L)*tmp + cos(sqrtk*L)*p[fp]
        tmp = 0 + p[dq]
        p[dq] = cosh(sqrtk*L)*p[dq] + L*sinhcu(sqrtk*L)*p[dp]
        p[dp] = sqrtk*sinh(sqrtk*L)*tmp + cosh(sqrtk*L)*p[dp]
      end
    end
  end

  misalign!(bunch, ma, false)
  return bunch
end

