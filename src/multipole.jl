mutable struct BMultipole{T<:Number}
  order::Int
  Bk::T       #  field strength in T/m^order
  tilt::T
  function BMultipole(order, Bk, tilt)
    return new{promote_type(typeof(Bk),typeof(tilt))}(order, Bk, tilt)
  end
  function BMultipole{T}(order, Bk, tilt) where {T}
    return new{T}(order, Bk, tilt)
  end
end

# Key == order
# Note we require all multipoles to have same number type
const BMultipoleDict{T} = Dict{Int, BMultipole{T}} where {T<:Number}

# Note the repetitive code - this means we can likely coalesce ParamDict and BMultipoleDict 
# Into some single new restricted Dict type.
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
  bdict::BMultipoleDict{T} = BMultipoleDict{Float64}() # multipole coefficients
end

# Replace will copy the copy + change the type, and if the key is not provided
# then it will add the multipole.
function replace(b::BMultipoleParams{S}, key::Symbol, value) where {S}
  T = promote_type(S, typeof(value))
  ord, sym = BMULTIPOLE_KEY_MAP[key]
  bdict = BMultipoleDict{T}()
  for (order, bm) in b.bdict
    bdict[order] = BMultipole{T}(order, bm.Bk, bm.tilt)
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
  :B0 =>  ( 0, :Bk), 
  :B1 =>  ( 1, :Bk),
  :B2 =>  ( 2, :Bk),
  :B3 =>  ( 3, :Bk),
  :B4 =>  ( 4, :Bk),
  :B5 =>  ( 5, :Bk),
  :B6 =>  ( 6, :Bk),
  :B7 =>  ( 7, :Bk),
  :B8 =>  ( 8, :Bk),
  :B9 =>  ( 9, :Bk),
  :B10 => (10, :Bk),
  :B11 => (11, :Bk),
  :B12 => (12, :Bk),
  :B13 => (13, :Bk),
  :B14 => (14, :Bk),
  :B15 => (15, :Bk),
  :B16 => (16, :Bk),
  :B17 => (17, :Bk),
  :B18 => (18, :Bk),
  :B19 => (19, :Bk),
  :B20 => (20, :Bk),
  :B21 => (21, :Bk), 

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

# These are virtual parameters, which do NOT exist 
# for lone BMultipole structs, only those within LineElements
const BMULTIPOLE_VIRTUAL_MAP = Dict{Symbol,Symbol}(
:K0 =>  :B0 ,
:K1 =>  :B1 ,
:K2 =>  :B2 ,
:K3 =>  :B3 ,
:K4 =>  :B4 ,
:K5 =>  :B5 ,
:K6 =>  :B6 ,
:K7 =>  :B7 ,
:K8 =>  :B8 ,
:K9 =>  :B9 ,
:K10 => :B10,
:K11 => :B11,
:K12 => :B12,
:K13 => :B13,
:K14 => :B14,
:K15 => :B15,
:K16 => :B16,
:K17 => :B17,
:K18 => :B18,
:K19 => :B19,
:K20 => :B20,
:K21 => :B21,
)