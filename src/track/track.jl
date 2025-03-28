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
  if isnothing(work)
    n_temps = 0
    for ele in bl.line
      cur_n_temps = MAX_TEMPS(ele.tracking_method) 
      n_temps = cur_n_temps > n_temps ? cur_n_temps : n_temps
    end
    work = map(t->zero(bunch.v.x), 1:n_temps)
  end

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
  @FastGTPSA! begin
    bunch.v.x += sgn*ma.x_offset
    bunch.v.y += sgn*ma.y_offset
  end
  return bunch
end

function _track_linear!(
  bunch::Bunch, 
  ma,
  bm, 
  bp,
  L, 
  Brho_ref;
  work=nothing,
)
  if !isnothing(bp)
    error("Bend tracking not implemented yet")
  end

  misalign!(bunch, ma, true)

  v = bunch.v

  if isnothing(bm) || length(bm.bdict) == 0 # Drift
    @FastGTPSA! begin
      @. v.x += v.px * L
      @. v.y += v.py * L
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
      fq = v.x
      fp = v.px
      dq = v.y
      dp = v.py
      sqrtk = sqrt(K1)
    else
      fq = v.y
      fp = v.py
      dq = v.x
      dp = v.px
      sqrtk = sqrt(-K1)
    end

    # One temporary array, for 1000 Floats is 3 allocations on Julia v1.11
    
    tmp = isnothing(work) ? zero(bunch.v.x) : work[1]

    # copy and copy! behavior by GTPSA may be modified in future (weirdness 
    # because TPS is mutable). For now 0 + with FastGTPSA! is workaround.
    @FastGTPSA! begin
      @. tmp = 0 + fq
      @. fq = cos(sqrtk*L)*fq + L*sincu(sqrtk*L)*fp
      @. fp = -sqrtk*sin(sqrtk*L)*tmp + cos(sqrtk*L)*fp
      @. tmp = 0 + dq
      @. dq = cosh(sqrtk*L)*dq + L*sinhcu(sqrtk*L)*dp
      @. dp = sqrtk*sinh(sqrtk*L)*tmp + cosh(sqrtk*L)*dp
    end
  end

  misalign!(bunch, ma, false)
  return bunch
end

