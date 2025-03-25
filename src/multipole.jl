mutable struct BMultipole{nrml,T<:Number}
  order::Int    # Cyclic group order=0 solenoid, order=1 dipole, order=2 Quadrupole, ... 
  strength::T   # field strength in T/m^order, normalized by Brho if nrml == true
  tilt::T       # direction (in xy plane) of directional-derivative defining strength
  function BMultipole(order, strength, tilt)
    # Default nrml = false
    return new{false,promote_type(typeof(strength),typeof(tilt))}(order, strength, tilt)
  end
  function BMultipole{nrml}(order, strength, tilt) where {nrml}
    nrml isa Bool || error("BMultipole type parameter nrml must be a Bool")
    return new{nrml,promote_type(typeof(strength),typeof(tilt))}(order, strength, tilt)
  end
  function BMultipole{nrml,T}(order, strength, tilt) where {nrml,T}
    nrml isa Bool || error("BMultipole type parameter nrml must be a Bool")
    return new{nrml,T}(order, strength, tilt)
  end
end

# Key == order
# Note we require all multipoles to have same number type
const BMultipoleDict{nrml,T} = Dict{Int, BMultipole{nrml,T}} where {nrml,T<:Number}

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

@kwdef struct BMultipoleParams{nrml,T<:Number} <: AbstractParams
  bdict::BMultipoleDict{nrml,T} = BMultipoleDict{false,Float64}() # multipole coefficients
end
function BMultipoleParams{nrml}(bdict::BMultipoleDict{nrml,T}=BMultipoleDict{nrml,Float64}()) where {nrml,T} 
  return BMultipoleParams{nrml,T}(bdict)
end

get_ord_sym(::BMultipoleParams{nrml}, key) where {nrml} = nrml == false ? BMULTIPOLE_KEY_MAP[key] : KMULTIPOLE_KEY_MAP[key]

# Replace will copy the copy + change the type, and if the key is not provided
# then it will add the multipole.
function replace(b::BMultipoleParams{nrml,S}, key::Symbol, value) where {nrml,S}
  T = promote_type(S, typeof(value))
  ord, sym = get_ord_sym(b, key)
  bdict = BMultipoleDict{nrml,T}()
  for (order, bm) in b.bdict
    bdict[order] = BMultipole{nrml,T}(order, bm.strength, bm.tilt)
  end
  if !haskey(bdict, ord)
    bdict[ord] = BMultipole{nrml,T}(ord, 0, 0)
  end
  setproperty!(bdict[ord], sym, T(value))
  return BMultipoleParams{nrml,T}(bdict)
end

function Base.getproperty(b::BMultipoleParams{nrml}, key::Symbol) where {nrml}
  if key == :bdict
    return getfield(b, :bdict)
  else
    order, sym = get_ord_sym(b, key)
    return getproperty(getindex(b.bdict, order), sym)
  end
end

# Also allow array-like indexing of the param struct
function Base.getindex(b::BMultipoleParams, key)
  return b.bdict[key]
end

function Base.setproperty!(b::BMultipoleParams{nrml}, key::Symbol, value) where {nrml}
  order, sym = get_ord_sym(b, key)
  bm = getindex(b.bdict, order)
  return setproperty!(bm, sym, value)
end

# One question might be how to handle the input of :tilt with :Ks
# This can be resolved by having a separate :dtilt symbol that adds
# a tilt to the current multipole tilt.


function Base.hasproperty(b::BMultipoleParams{nrml}, key::Symbol) where {nrml}
  return haskey(b.bdict, first(get_ord_sym(b, key)))
end

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
# Note accelerator physics convention: cyclic group order
# is -1 of "multipole" order, and 0th order is "s" for solenoid
const BMULTIPOLE_KEY_MAP = Dict{Symbol, Tuple{Int,Symbol}}(
  :Bs =>  ( 0, :strength), 
  :B0 =>  ( 1, :strength),
  :B1 =>  ( 2, :strength),
  :B2 =>  ( 3, :strength),
  :B3 =>  ( 4, :strength),
  :B4 =>  ( 5, :strength),
  :B5 =>  ( 6, :strength),
  :B6 =>  ( 7, :strength),
  :B7 =>  ( 8, :strength),
  :B8 =>  ( 9, :strength),
  :B9 =>  (10, :strength),
  :B10 => (11, :strength),
  :B11 => (12, :strength),
  :B12 => (13, :strength),
  :B13 => (14, :strength),
  :B14 => (15, :strength),
  :B15 => (16, :strength),
  :B16 => (17, :strength),
  :B17 => (18, :strength),
  :B18 => (19, :strength),
  :B19 => (20, :strength),
  :B20 => (21, :strength), 
  :B21 => (22, :strength), 

  :tilts =>  ( 0, :tilt), 
  :tilt0 =>  ( 1, :tilt),
  :tilt1 =>  ( 2, :tilt),
  :tilt2 =>  ( 3, :tilt),
  :tilt3 =>  ( 4, :tilt),
  :tilt4 =>  ( 5, :tilt),
  :tilt5 =>  ( 6, :tilt),
  :tilt6 =>  ( 7, :tilt),
  :tilt7 =>  ( 8, :tilt),
  :tilt8 =>  ( 9, :tilt),
  :tilt9 =>  (10, :tilt),
  :tilt10 => (11, :tilt),
  :tilt11 => (12, :tilt),
  :tilt12 => (13, :tilt),
  :tilt13 => (14, :tilt),
  :tilt14 => (15, :tilt),
  :tilt15 => (16, :tilt),
  :tilt16 => (17, :tilt),
  :tilt17 => (18, :tilt),
  :tilt18 => (19, :tilt),
  :tilt19 => (20, :tilt),
  :tilt20 => (21, :tilt), 
  :tilt21 => (22, :tilt), 
)

const KMULTIPOLE_KEY_MAP = Dict{Symbol, Tuple{Int,Symbol}}(
  :Ks =>  ( 0, :strength), 
  :K0 =>  ( 1, :strength),
  :K1 =>  ( 2, :strength),
  :K2 =>  ( 3, :strength),
  :K3 =>  ( 4, :strength),
  :K4 =>  ( 5, :strength),
  :K5 =>  ( 6, :strength),
  :K6 =>  ( 7, :strength),
  :K7 =>  ( 8, :strength),
  :K8 =>  ( 9, :strength),
  :K9 =>  (10, :strength),
  :K10 => (11, :strength),
  :K11 => (12, :strength),
  :K12 => (13, :strength),
  :K13 => (14, :strength),
  :K14 => (15, :strength),
  :K15 => (16, :strength),
  :K16 => (17, :strength),
  :K17 => (18, :strength),
  :K18 => (19, :strength),
  :K19 => (20, :strength),
  :K20 => (21, :strength), 
  :K21 => (22, :strength), 

  :tilts =>  ( 0, :tilt), 
  :tilt0 =>  ( 1, :tilt),
  :tilt1 =>  ( 2, :tilt),
  :tilt2 =>  ( 3, :tilt),
  :tilt3 =>  ( 4, :tilt),
  :tilt4 =>  ( 5, :tilt),
  :tilt5 =>  ( 6, :tilt),
  :tilt6 =>  ( 7, :tilt),
  :tilt7 =>  ( 8, :tilt),
  :tilt8 =>  ( 9, :tilt),
  :tilt9 =>  (10, :tilt),
  :tilt10 => (11, :tilt),
  :tilt11 => (12, :tilt),
  :tilt12 => (13, :tilt),
  :tilt13 => (14, :tilt),
  :tilt14 => (15, :tilt),
  :tilt15 => (16, :tilt),
  :tilt16 => (17, :tilt),
  :tilt17 => (18, :tilt),
  :tilt18 => (19, :tilt),
  :tilt19 => (20, :tilt),
  :tilt20 => (21, :tilt), 
  :tilt21 => (22, :tilt), 
)

# These are for virtual parameters, which do NOT exist 
# for lone BMultipole structs, only those within LineElements
const BMULTIPOLE_ORDER_MAP = Dict{Symbol,Int}(
  :Bs =>   0, 
  :B0 =>   1,
  :B1 =>   2,
  :B2 =>   3,
  :B3 =>   4,
  :B4 =>   5,
  :B5 =>   6,
  :B6 =>   7,
  :B7 =>   8,
  :B8 =>   9,
  :B9 =>  10,
  :B10 => 11,
  :B11 => 12,
  :B12 => 13,
  :B13 => 14,
  :B14 => 15,
  :B15 => 16,
  :B16 => 17,
  :B17 => 18,
  :B18 => 19,
  :B19 => 20,
  :B20 => 21, 
  :B21 => 22, 

  :Ks =>   0, 
  :K0 =>   1,
  :K1 =>   2,
  :K2 =>   3,
  :K3 =>   4,
  :K4 =>   5,
  :K5 =>   6,
  :K6 =>   7,
  :K7 =>   8,
  :K8 =>   9,
  :K9 =>  10,
  :K10 => 11,
  :K11 => 12,
  :K12 => 13,
  :K13 => 14,
  :K14 => 15,
  :K15 => 16,
  :K16 => 17,
  :K17 => 18,
  :K18 => 19,
  :K19 => 20,
  :K20 => 21, 
  :K21 => 22, 
)

const BMULTIPOLE_NORM_UNNORM_MAP = Dict{Symbol,Symbol}(
  :Bs =>  :Ks , 
  :B0 =>  :K0 ,
  :B1 =>  :K1 ,
  :B2 =>  :K2 ,
  :B3 =>  :K3 ,
  :B4 =>  :K4 ,
  :B5 =>  :K5 ,
  :B6 =>  :K6 ,
  :B7 =>  :K7 ,
  :B8 =>  :K8 ,
  :B9 =>  :K9 ,
  :B10 => :K10,
  :B11 => :K11,
  :B12 => :K12,
  :B13 => :K13,
  :B14 => :K14,
  :B15 => :K15,
  :B16 => :K16,
  :B17 => :K17,
  :B18 => :K18,
  :B19 => :K19,
  :B20 => :K20, 
  :B21 => :K21, 

  :Ks =>  :Bs , 
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