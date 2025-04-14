module Beamlines
export MattStandard, 
       AbstractParams, 
       LineElement, 
       Bunch, 
       make_lat, 
       track!, 
       ParamDict, 
       UniversalParams, 
       BMultipoleParams, 
       BeamlineParams,
       AlignmentParams,
       BendParams,
       BMultipole,
       Drift,
       Solenoid,
       Quadrupole,
       Sextupole,
       Octupole,
       Multipole,
       Marker,
       SBend,
       Kicker,
       RFCavity,
       Beamline,
       Controller,
       set!,
       
       BitsBeamline

using GTPSA, 
      Accessors, 
      StaticArrays, 
      LoopVectorization, 
      SIMD, 
      VectorizationBase, 
      Polyester,
      OrderedCollections

import GTPSA: sincu, sinhcu

# Reference energy in eV
#default_E_ref::Float64 = NaN


# Note that LineElement and parameter structs have three things:
# 1) Fields: These are actual fields within a struct, e.g. pdict in LineElement
# 2) Properties: These are "fields" within a struct that aren't actual fields, but can 
#                be get/set using the dot syntax and/or getproperty/setproperty!. 
#                E.g., the default fallback for getproperty is getfield
# 3) Virtual properties: These are values that only exist for parameter structs within 
#                        a LineElement type, and can be calculated using different 
#                        parameter structs within the LineElement. E.g. the normalized 
#                        field strengths requires BMultipoleParams and BeamlineParams.

# Often, quantities can be get/set as properties, and NOT virtual properties.
# For example, the s position of an element can be PROPERTY of the BeamlineParams 
# struct as one can sum the lengths of each preceding element in the Beamline.

include("element.jl")
include("beamline.jl")
include("multipole.jl")
include("virtual.jl")
include("bend.jl")
include("control.jl")
include("alignment.jl")
include("keymaps.jl")
include("bits/bitsparams.jl")
include("bits/bitstracking.jl")
include("bits/bitsline.jl")
include("bits/bitselement.jl")

#include("track_aos/track.jl")
#include("track/track.jl")


#=
struct Bunch{T <: Number}
  x::Vector{T}
  px::Vector{T}
  y::Vector{T}
  py::Vector{T}
end

function Bunch(n::Integer, ::Type{T}=Float64) where T <: Number
  return Bunch(rand(T, n), rand(T, n), rand(T, n), rand(T, n))
end

function make_lat(n::Integer=1; K1=0.36, L_quad=0.5, L_drift=1.)
  function make_matt_ele(K1, L)
    ele = LineElement()
    ele.QuadParams = QuadParams(K1, 0.)
    ele.LengthParams = LengthParams(L)
    return ele
  end

  fodo = [make_matt_ele(K1, L_quad), make_matt_ele(0., L_drift),
          make_matt_ele(-K1, L_quad), make_matt_ele(0., L_drift)]
  lat = repeat(fodo, n)
  return lat
end

function track!(bunch::Bunch, lat::Vector{<:LineElement})
  tmp = zero(bunch.x)
  for ele in lat
    track!(bunch, ele, tmp)
  end
  return bunch
end

function track!(bunch::Bunch, ele::LineElement, tmp=nothing)
  return track!(bunch, ele.tracking_method, ele.params, tmp) # Function barrier technique
end

function track!(bunch::Bunch, ::MattStandard, params::Params, tmp=nothing)
  L = params.L
  K1 = params.K1

  if abs(K1 - 0.0) < eps(K1) # Drift
    @FastGTPSA! begin
      @. bunch.x += bunch.px * L
      @. bunch.y += bunch.py * L
    end
  else
    if K1 >= 0
      fq = bunch.x
      fp = bunch.px
      dq = bunch.y
      dp = bunch.py
      sqrtk = sqrt(K1)
    else
      fq = bunch.y
      fp = bunch.py
      dq = bunch.x
      dp = bunch.px
      sqrtk = sqrt(-K1)
    end

    # One temporary array, for 1000 Floats is 3 allocations on Julia v1.11
    if isnothing(tmp)
      tmp = zero(fq)
    end

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
  return bunch
end
=#



end
