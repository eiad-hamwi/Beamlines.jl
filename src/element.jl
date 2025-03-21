
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
  pdict::ParamDict = ParamDict(UniversalParams => UniversalParams())
end

function LatElement(class::String; kwargs...)
  ele = LatElement()
  ele.class = class
  for (k, v) in kwargs
    setproperty!(ele, k, v)
  end
  return ele
end

include("multipole.jl")

abstract type TrackingMethod end
struct MattStandard <: TrackingMethod end
# This is just a first idea for handling tracking open to suggestions
struct DiffEq <: TrackingMethod
  ds::Float64
end

@kwdef mutable struct UniversalParams{T<:TrackingMethod, U<:Number} <: AbstractParams
  tracking_method::T = MattStandard()
  L::U               = 0.0
  class::String      = "Marker"
end

# Use Accessors here for default bc super convenient for replacing entire (even mutable) type
# For more complex params (e.g. BMultipoleParams) we will need custom override
@inline replace(p::AbstractParams, key::Symbol, value) = set(pg, opcompose(PropertyLens(key)), value)

function Base.getproperty(ele::LatElement, key::Symbol)
  if key == :pdict
    return getfield(ele, :pdict)
  elseif haskey(PARAMS_MAP, key) # To get AbstractParams struct
    return getindex(ele.pdict, PARAMS_MAP[key])
  else  # To get a specific parameter in a parameter struct
    return getproperty(getindex(ele.pdict, PARAMS_FIELDS_MAP[key]), key)
  end
end

function Base.setproperty!(ele::LatElement, key::Symbol, value)
  # Using immutable structs via Accessors.jl: time to update is 452 ns with 7 allocations, regardless of type change
  # ele.pdict[PARAMS_FIELDS_MAP[key]] = set(ele.pdict[PARAMS_FIELDS_MAP[key]], opcompose(PropertyLens(key)), value)

  # With mutable structs time to update is ~65 ns with 3 allocations
  if haskey(PARAMS_MAP, key)
    setindex!(ele.pdict, value, PARAMS_MAP[key])
  else
    if !haskey(ele.pdict, PARAMS_FIELDS_MAP[key])
      p = getindex(ele.pdict, PARAMS_FIELDS_MAP[key])
      # Function barrier for speed
      _setproperty!(ele.pdict, p, key, value)
    else

    end
  end
end

function _setproperty!(pdict::ParamDict, p::AbstractParams, key::Symbol, value)
  #T = fieldtype(typeof(pg), key) 
  #if typeof(value) == T # no promotion necessary
     # Here and below, setproperty! causes one more allocation and ~10ns slower than setfield!, 
     # but setproperty! should be used bc setproperty! can be extended.
  #  return setproperty!(pg, key, value)
  #else
  # Can we put this value in the current mutable struct?
  if hasproperty(p, key)
    T = typeof(getproperty(p, key))
    if promote_type(typeof(value), T) == T 
      return setproperty!(p, key, value)
    end
  end
  return pdict[PARAMS_FIELDS_MAP[key]] = replace(p, key, value)
end

#Base.fieldnames(::Type{LatElement}) = tuple(:pdict, keys(PARAMS_FIELDS_MAP)..., keys(PARAMS_MAP)...)
#Base.fieldnames(::LatElement) = tuple(:pdict, keys(PARAMS_FIELDS_MAP)..., keys(PARAMS_MAP)...)
#Base.propertynames(::Type{LatElement}) = tuple(:pdict, keys(PARAMS_FIELDS_MAP)..., keys(PARAMS_MAP)...)
#Base.propertynames(::LatElement) = tuple(:pdict, keys(PARAMS_FIELDS_MAP)..., keys(PARAMS_MAP)...)

const PARAMS_FIELDS_MAP = Dict{Symbol,Type{<:AbstractParams}}(
  :Kn0 =>  BMultipoleParams,
  :Kn1 =>  BMultipoleParams,
  :Kn2 =>  BMultipoleParams,
  :Kn3 =>  BMultipoleParams,
  :Kn4 =>  BMultipoleParams,
  :Kn5 =>  BMultipoleParams,
  :Kn6 =>  BMultipoleParams,
  :Kn7 =>  BMultipoleParams,
  :Kn8 =>  BMultipoleParams,
  :Kn9 =>  BMultipoleParams,
  :Kn10 => BMultipoleParams,
  :Kn11 => BMultipoleParams,
  :Kn12 => BMultipoleParams,
  :Kn13 => BMultipoleParams,
  :Kn14 => BMultipoleParams,
  :Kn15 => BMultipoleParams,
  :Kn16 => BMultipoleParams,
  :Kn17 => BMultipoleParams,
  :Kn18 => BMultipoleParams,
  :Kn19 => BMultipoleParams,
  :Kn20 => BMultipoleParams,
  :Kn21 => BMultipoleParams,

  :tilt0 =>  BMultipoleParams,
  :tilt1 =>  BMultipoleParams,
  :tilt2 =>  BMultipoleParams,
  :tilt3 =>  BMultipoleParams,
  :tilt4 =>  BMultipoleParams,
  :tilt5 =>  BMultipoleParams,
  :tilt6 =>  BMultipoleParams,
  :tilt7 =>  BMultipoleParams,
  :tilt8 =>  BMultipoleParams,
  :tilt9 =>  BMultipoleParams,
  :tilt10 => BMultipoleParams,
  :tilt11 => BMultipoleParams,
  :tilt12 => BMultipoleParams,
  :tilt13 => BMultipoleParams,
  :tilt14 => BMultipoleParams,
  :tilt15 => BMultipoleParams,
  :tilt16 => BMultipoleParams,
  :tilt17 => BMultipoleParams,
  :tilt18 => BMultipoleParams,
  :tilt19 => BMultipoleParams,
  :tilt20 => BMultipoleParams,
  :tilt21 => BMultipoleParams,

  :L => UniversalParams,
  :tracking_method => UniversalParams,
  :class => UniversalParams
)

const PARAMS_MAP = Dict{Symbol,Type{<:AbstractParams}}(
  :BMultipoleParams => BMultipoleParams,
  :UniversalParams => UniversalParams,
)
