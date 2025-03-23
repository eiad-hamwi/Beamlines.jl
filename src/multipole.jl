mutable struct BMultipole{T<:Number}
  order::Int
  Bn::T       #  field strength in T
  tilt::T
  function BMultipole(order, Bn, tilt)
    return new{promote_type(typeof(Bn),typeof(tilt))}(order, Bn, tilt)
  end
  function BMultipole{T}(order, Bn, tilt) where {T}
    return new{T}(order, Bn, tilt)
  end
end

# Key == order
# Note we require all multipoles to have same number type
const BMultipoleDict{T} = Dict{Int, BMultipole{T}} where {T<:Number}

# Note the repetitive code - this means we can likely coalesce ParamDict and BMultipoleDict 
# Into some single new Dict type.
function Base.setindex!(h::BMultipoleDict, v::BMultipole, key::Int)
  v.order == key || error("Key $key does not match multipole order $(v.order)")
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

@kwdef struct BMultipoleParams{T<:Number} <: AbstractParams
  bdict::BMultipoleDict{T} = BMultipoleDict{Float64}(1 => BMultipole(1, 0.36, 0.)) # multipole coefficients
end

# Replace will copy the copy + change the type, and if the key is not provided
# then it will add the multipole.
function replace(b::BMultipoleParams{S}, key::Symbol, value) where {S}
  T = promote_type(S, typeof(value))
  ord, sym = BMULTIPOLE_KEY_MAP[key]
  bdict = BMultipoleDict{T}()
  for (order, bm) in b.bdict
    bdict[order] = BMultipole{T}(order, bm.Bn, bm.tilt)
  end
  if !haskey(bdict, ord)
    bdict[ord] = BMultipole{T}(ord, 0, 0)
  end
  setproperty!(bdict[ord], sym, T(value))
  return BMultipoleParams{T}(bdict)
end

function Base.getproperty(bm::BMultipoleParams, key::Symbol)
  if key == :bdict
    return getfield(bm, :bdict)
  else
    order, sym = BMULTIPOLE_KEY_MAP[key]
    return getproperty(getindex(bm.bdict, order), sym)
  end
end

# Also allow array-like indexing of the param struct
function Base.getindex(bm::BMultipoleParams, key)
  return bm.bdict[key]
end

function Base.setproperty!(bm::BMultipoleParams, key::Symbol, value)
  order, sym = BMULTIPOLE_KEY_MAP[key]
  b = getindex(bm.bdict, order)
  return setproperty!(b, sym, value)
end

# One question might be how to handle the input of :tilt with :Ks
# This can be resolved by having a separate :dtilt symbol that adds
# a tilt to the current multipole tilt.


Base.hasproperty(b::BMultipoleParams, key::Symbol) = haskey(b.bdict, first(BMULTIPOLE_KEY_MAP[key]))

#Base.fieldnames(::Type{<:BMultipoleParams}) = tuple(:bdict, keys(BMULTIPOLE_KEY_MAP)...)
#Base.fieldnames(::BMultipoleParams) = tuple(:bdict, keys(BMULTIPOLE_KEY_MAP)...)
#Base.propertynames(::Type{<:BMultipoleParams}) = tuple(:bdict, keys(BMULTIPOLE_KEY_MAP)...)
#Base.propertynames(::BMultipoleParams) = tuple(:bdict, keys(BMULTIPOLE_KEY_MAP)...)

#Base.propertynames(b::BMultipoleParams) = tuple(keys(b.bdict)...)
#BMULTIPOLE_PROPERTIES_MAP[first(keys(b.bdict))] #... for key in keys(BMULTIPOLE_KEY_MAP))..., :bdict)
#Base.getindex.(BMULTIPOLE_PROPERTIES_MAP, keys(b.bdict)...)
#(BMULTIPOLE_PROPERTIES_MAP[key]... for key in keys(BMULTIPOLE_KEY_MAP)..., :bdict)

# Technically these are virtual IO fields
# But because they only use stuff within this parameter struct,
# we can optimize
const BMULTIPOLE_KEY_MAP = Dict{Symbol, Tuple{Int,Symbol}}(
  :Bn0 =>  ( 0, :Bn), 
  :Bn1 =>  ( 1, :Bn),
  :Bn2 =>  ( 2, :Bn),
  :Bn3 =>  ( 3, :Bn),
  :Bn4 =>  ( 4, :Bn),
  :Bn5 =>  ( 5, :Bn),
  :Bn6 =>  ( 6, :Bn),
  :Bn7 =>  ( 7, :Bn),
  :Bn8 =>  ( 8, :Bn),
  :Bn9 =>  ( 9, :Bn),
  :Bn10 => (10, :Bn),
  :Bn11 => (11, :Bn),
  :Bn12 => (12, :Bn),
  :Bn13 => (13, :Bn),
  :Bn14 => (14, :Bn),
  :Bn15 => (15, :Bn),
  :Bn16 => (16, :Bn),
  :Bn17 => (17, :Bn),
  :Bn18 => (18, :Bn),
  :Bn19 => (19, :Bn),
  :Bn20 => (20, :Bn),
  :Bn21 => (21, :Bn), 

  :tilt0 =>  ( 0, :tilt), 
  :tilt1 =>  ( 1, :tilt),
  :tilt2 =>  ( 2, :tilt),
  :tilt3 =>  ( 3, :tilt),
  :tilt4 =>  ( 4, :tilt),
  :tilt5 =>  ( 5, :tilt),
  :tilt6 =>  ( 6, :tilt),
  :tilt7 =>  ( 7, :tilt),
  :tilt8 =>  ( 8, :tilt),
  :tilt9 =>  ( 9, :tilt),
  :tilt10 => (10, :tilt),
  :tilt11 => (11, :tilt),
  :tilt12 => (12, :tilt),
  :tilt13 => (13, :tilt),
  :tilt14 => (14, :tilt),
  :tilt15 => (15, :tilt),
  :tilt16 => (16, :tilt),
  :tilt17 => (17, :tilt),
  :tilt18 => (18, :tilt),
  :tilt19 => (19, :tilt),
  :tilt20 => (20, :tilt),
  :tilt21 => (21, :tilt), 
)


# These are FUNCTIONAL virtual parameters
const BMULTIPOLE_VIRTUAL_MAP = Dict{Symbol,Symbol}(
:Kn0 =>  :Bn0 ,
:Kn1 =>  :Bn1 ,
:Kn2 =>  :Bn2 ,
:Kn3 =>  :Bn3 ,
:Kn4 =>  :Bn4 ,
:Kn5 =>  :Bn5 ,
:Kn6 =>  :Bn6 ,
:Kn7 =>  :Bn7 ,
:Kn8 =>  :Bn8 ,
:Kn9 =>  :Bn9 ,
:Kn10 => :Bn10,
:Kn11 => :Bn11,
:Kn12 => :Bn12,
:Kn13 => :Bn13,
:Kn14 => :Bn14,
:Kn15 => :Bn15,
:Kn16 => :Bn16,
:Kn17 => :Bn17,
:Kn18 => :Bn18,
:Kn19 => :Bn19,
:Kn20 => :Bn20,
:Kn21 => :Bn21,
)