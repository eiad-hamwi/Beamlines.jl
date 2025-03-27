# Tracking functions in this file to be moved to other package

#= Beamline does not know about particles going through it. =#

using StructArrays
export Bunch, Particle, Linear, track, ELECTRON, POSITRON, PROTON, ANTIPROTON

include("utils.jl")
include("types.jl")

struct Linear end

function track(bunch::Vector{<:Particle}, bl::Beamline)
  for ele in bl.line
    bunch = @noinline track(bunch, ele)
  end
  return bunch
end

function track(bunch::Vector{<:Particle}, ele::LineElement)
  # Dispatch on the tracking method:
  return track(bunch, ele, ele.tracking_method)
end

function track(bunch::Vector{<:Particle}, ele::LineElement, ::Linear)
  # Unpack the line element
  ma = ele.AlignmentParams
  bm = ele.BMultipoleParams
  bp = ele.BendParams
  L = ele.L
  Brho_ref = ele.Brho_ref

  # Function barrier (this function is now fully compiled)
  # Only now broadcast
  return @noinline map(p->_track_linear(p, ma, bm, bp, L, Brho_ref), bunch)
end

# Don't do anything if no AlignmentParams
misalign(p::Particle, ::Nothing, ::Bool) = p

# in = true for enter, false for exit
function misalign(p::Particle, ma::AlignmentParams, in::Bool)
  if ma.x_rot != 0. || ma.y_rot != 0. || ma.tilt != 0.
    error("Rotational misalignments not implemented yet")
  end
  sgn = in ? -1 : 1
  x = @FastGTPSA p.v.x+sgn*ma.x_offset
  y = @FastGTPSA p.v.y+sgn*ma.y_offset
  return Particle(p.species, p.Brho, Coord(x,p.v.px,y,p.v.py))
end

function _track_linear(
  p::Particle, 
  ma,
  bm, 
  bp,
  L, 
  Brho_ref
)
  if !isnothing(bp)
    error("Bend tracking not implemented yet")
  end

  p = misalign(p, ma, true)

  v = p.v

  if isnothing(bm) || length(bm.bdict) == 0 # Drift
    @FastGTPSA begin
      x = v.x + v.px * L
      y = v.y + v.py * L
    end
    return Particle(p.species, p.Brho_0, Coord(x,v.px,y,v.py))
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
    K1 = B1/p.Brho_0


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

    # copy and copy! behavior by GTPSA may be modified in future (weirdness 
    # because TPS is mutable). For now 0 + with FastGTPSA! is workaround.
    @FastGTPSA begin
      out_fq = cos(sqrtk*L)*fq + L*sincu(sqrtk*L)*fp
      out_fp = -sqrtk*sin(sqrtk*L)*fq + cos(sqrtk*L)*fp
      out_dq = cosh(sqrtk*L)*dq + L*sinhcu(sqrtk*L)*dp
      out_dp = sqrtk*sinh(sqrtk*L)*dq + cosh(sqrtk*L)*dp
    end

    if K1 >= 0
      p = Particle(p.species,p.Brho_0,Coord(out_fq,out_fp,out_dq,out_dp))
    else
      p = Particle(p.species,p.Brho_0,Coord(out_dq,out_dp,out_fq,out_fp))
    end
  end

  p = misalign(p, ma, false)
  return p
end

