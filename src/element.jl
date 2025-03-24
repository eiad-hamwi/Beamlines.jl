
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

@kwdef struct LineElement
  pdict::ParamDict = ParamDict(UniversalParams => UniversalParams())
end

function LineElement(class::String; kwargs...)
  ele = LineElement()
  ele.class = class
  for (k, v) in kwargs
    setproperty!(ele, k, v)
  end
  return ele
end

# Common class choices
Solenoid(; kwargs...)   = LineElement("Solenoid"; kwargs...)
Quadrupole(; kwargs...) = LineElement("Quadrupole"; kwargs...)
Sextupole(; kwargs...)  = LineElement("Sextupole"; kwargs...)
Drift(; kwargs...)      = LineElement("Drift"; kwargs...)
Octupole(; kwargs...)   = LineElement("Octupole"; kwargs...)
Multipole(; kwargs...)  = LineElement("Multipole"; kwargs...)
Marker(; kwargs...)     = LineElement("Marker"; kwargs...)

include("multipole.jl")

# These should be in tracking package instead
struct MattStandard end
# This is just a first idea for handling tracking open to suggestions
struct DiffEq
  ds::Float64
end

@kwdef mutable struct UniversalParams{T, U<:Number} <: AbstractParams
  tracking_method::T = MattStandard()
  L::U               = 0.0
  class::String      = "Marker"
end

include("beamline.jl")

# Use Accessors here for default bc super convenient for replacing entire (even mutable) type
# For more complex params (e.g. BMultipoleParams) we will need custom override
replace(p::AbstractParams, key::Symbol, value) = set(p, opcompose(PropertyLens(key)), value)

include("virtual.jl")

function Base.getproperty(ele::LineElement, key::Symbol)
  if key == :pdict 
    return getfield(ele, :pdict)
  elseif haskey(PARAMS_MAP, key) # To get parameters struct
    return getindex(ele.pdict, PARAMS_MAP[key])
  elseif haskey(PROPERTIES_MAP, key)  # To get a property in a parameter struct
    return getproperty(getindex(ele.pdict, PROPERTIES_MAP[key]), key)
  elseif haskey(VIRTUAL_GETTER_MAP, key) # To get a virtual element property
    return VIRTUAL_GETTER_MAP[key](ele, key)
  else
    error("Type LineElement has no property $key")
  end
end

function Base.setproperty!(ele::LineElement, key::Symbol, value)
  if haskey(PARAMS_MAP, key) # Setting whole parameter struct
    setindex!(ele.pdict, value, PARAMS_MAP[key])
  elseif haskey(PROPERTIES_MAP, key)
    if !haskey(ele.pdict, PROPERTIES_MAP[key])
      # If the parameter struct associated with this symbol does not exist, create it
      # This could be optimized in the future with a `place` function
      # That is similar to `replace` but just has the type
      # Though adding fields is not done very often so is fine
      setindex!(ele.pdict, PROPERTIES_MAP[key](), PROPERTIES_MAP[key])
    end
    p = getindex(ele.pdict, PROPERTIES_MAP[key])
    # Function barrier for speed
    @noinline _setproperty!(ele.pdict, p, key, value)
  elseif haskey(VIRTUAL_SETTER_MAP, key)
    return VIRTUAL_SETTER_MAP[key](ele, key, value)
  else
    if haskey(VIRTUAL_GETTER_MAP, key)
      error("LineElement property $key is read-only")
    else
      error("Type LineElement has no property $key")
    end
  end
end

function _setproperty!(pdict::ParamDict, p::AbstractParams, key::Symbol, value)
  if hasproperty(p, key) # Check if we can put this value in current struct
    T = typeof(getproperty(p, key))
    if promote_type(typeof(value), T) == T
      return setproperty!(p, key, value)
    end
  end
  return pdict[PROPERTIES_MAP[key]] = replace(p, key, value)
end

#Base.fieldnames(::Type{LineElement}) = tuple(:pdict, keys(PROPERTIES_MAP)..., keys(PARAMS_MAP)...)
#Base.fieldnames(::LineElement) = tuple(:pdict, keys(PROPERTIES_MAP)..., keys(PARAMS_MAP)...)
#Base.propertynames(::Type{LineElement}) = tuple(:pdict, keys(PROPERTIES_MAP)..., keys(PARAMS_MAP)...)
#Base.propertynames(::LineElement) = tuple(:pdict, keys(PROPERTIES_MAP)..., keys(PARAMS_MAP)...)

const PROPERTIES_MAP = Dict{Symbol,Type{<:AbstractParams}}(
  :B0 =>  BMultipoleParams,
  :B1 =>  BMultipoleParams,
  :B2 =>  BMultipoleParams,
  :B3 =>  BMultipoleParams,
  :B4 =>  BMultipoleParams,
  :B5 =>  BMultipoleParams,
  :B6 =>  BMultipoleParams,
  :B7 =>  BMultipoleParams,
  :B8 =>  BMultipoleParams,
  :B9 =>  BMultipoleParams,
  :B10 => BMultipoleParams,
  :B11 => BMultipoleParams,
  :B12 => BMultipoleParams,
  :B13 => BMultipoleParams,
  :B14 => BMultipoleParams,
  :B15 => BMultipoleParams,
  :B16 => BMultipoleParams,
  :B17 => BMultipoleParams,
  :B18 => BMultipoleParams,
  :B19 => BMultipoleParams,
  :B20 => BMultipoleParams,
  :B21 => BMultipoleParams,

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
  :class => UniversalParams,

  :beamline => BeamlineParams,
  :beamline_index => BeamlineParams,
  :E_ref => BeamlineParams,
  :Brho => BeamlineParams, 
  :s => BeamlineParams,
  :s_downstream => BeamlineParams,
)

const PARAMS_MAP = Dict{Symbol,Type{<:AbstractParams}}(
  :BMultipoleParams => BMultipoleParams,
  :UniversalParams => UniversalParams,
  :BeamlineParams => BeamlineParams,
)
