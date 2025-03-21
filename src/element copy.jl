
abstract type AbstractParams end

# By making the key the AbstractParams type name, we always have a consistent internal definition
const ParamDict = Dict{Type{<:AbstractParams}, AbstractParams}
Base.setindex!(h::ParamDict, v, key) = error("Incorrect key/value types for ParamDict")

function Base.setindex!(h::ParamDict, v::AbstractParams, key::Type{<:AbstractParams})
  # 208 ns and 3 allocations to check that we set correctly
  # Parameter groups rarely added so perfectly fine
  typeof(v) <: key || error("Key type $key does not match AbstractParams type $(typeof(v))")
  # The following is copy-pasted directly from Base dict.jl ==========
  index, sh = Base.ht_keyindex2_shorthash!(h, key)

  if index > 0
      h.age += 1
      @inbounds h.keys[index] = key
      @inbounds h.vals[index] = v
  else
      @inbounds Base._setindex!(h, v, key, -index, sh)
  end

  return h
  # ==================================================================
end

@kwdef struct LatElement
  pdict::ParamDict = ParamDict(UniversalParams => UniversalParams(MattStandard(), 0.0))
end

mutable struct BMultipoleParams{T <: Number} <: AbstractParams
  Kn0::T
  Kn1::T
  Kn2::T
  tilt::T
  function BMultipoleParams(Kn0, Kn1, Kn2, tilt)
    return new{promote_type(typeof(Kn0), typeof(Kn1), typeof(Kn2), typeof(tilt))}(Kn0, Kn1, Kn2, tilt)
  end
end

abstract type TrackingMethod end
struct MattStandard <: TrackingMethod end
# This is just a first idea for handling tracking open to suggestions
struct DiffEq <: TrackingMethod
  ds::Float64
end

mutable struct UniversalParams{T<:TrackingMethod, U<:Number} <: AbstractParams
  tracking_method::T
  L::U
end

function Base.getproperty(ele::LatElement, key::Symbol)
  if key == :pdict
    return getfield(ele, :pdict)
  elseif haskey(PARAMS_MAP, key) # To get AbstractParams struct
    return getindex(ele.pdict, PARAMS_MAP[key])
  else  # To get a specific parameter in a parameter struct
    return getfield(getindex(ele.pdict, PARAMS_FIELDS_MAP[key]), key)
  end
end

function Base.setproperty!(ele::LatElement, key::Symbol, value)
  # Using immutable structs via Accessors.jl: time to update is 452 ns with 7 allocations, regardless of type change
  # ele.pdict[PARAMS_FIELDS_MAP[key]] = set(ele.pdict[PARAMS_FIELDS_MAP[key]], opcompose(PropertyLens(key)), value)

  # With mutable structs time to update is ~65 ns with 3 allocations
  if haskey(PARAMS_MAP, key)
    setindex!(ele.pdict, value, PARAMS_MAP[key])
  else
    pg = getindex(ele.pdict, PARAMS_FIELDS_MAP[key])
    # Function barrier for speed
    _setproperty!(ele.pdict, pg, key, value)
  end
end

function _setproperty!(pdict::ParamDict, pg::AbstractParams, key::Symbol, value)
  T = fieldtype(typeof(pg), key) 
  if typeof(value) == T # no promotion necessary
    return setfield!(pg, key, value)
  elseif promote_type(typeof(value), T) == T  # promote
    return setfield!(pg, key, T(value))
  else
    # Use Accessors here bc super convenient for replacing entire (even mutable) type
    return pdict[PARAMS_FIELDS_MAP[key]] = set(pdict[PARAMS_FIELDS_MAP[key]], opcompose(PropertyLens(key)), value)
  end
end

const PARAMS_FIELDS_MAP = Dict{Symbol,Type{<:AbstractParams}}(
  :Kn0 => BMultipoleParams,
  :Kn1 => BMultipoleParams, 
  :Kn2 => BMultipoleParams,
  :tilt => BMultipoleParams,
  :L => UniversalParams,
  :tracking_method => UniversalParams
)

const PARAMS_MAP = Dict{Symbol,Type{<:AbstractParams}}(
  :BMultipoleParams => BMultipoleParams,
  :UniversalParams => UniversalParams,
)
