mutable struct BMultipole{T<:Number}
  strength::T # field strength in T/m^order, normalized by Brho if normalized == true
  tilt::T # direction (in xy plane) of directional-derivative defining strength
  const order::Int # Cyclic group order=0 solenoid, order=1 dipole, order=2 Quadrupole, ... 
  const normalized::Bool # if quantities are normalized
  const integrated::Bool # if quantities are integrated
  function BMultipole(args...)
    return new{promote_type(typeof(args[1]),typeof(args[2]))}(args...)
  end
  BMultipole{T}(args...) where {T} = new{T}(args...)
end

function Base.hasproperty(bm::BMultipole, key::Symbol)
  if key in fieldnames(BMultipole)
    return true
  elseif haskey(BMULTIPOLE_STRENGTH_MAP, key)
    order, normalized, integrated = BMULTIPOLE_STRENGTH_MAP[key]
    return order == bm.order  && normalized == bm.normalized && integrated == bm.integrated
  elseif haskey(BMULTIPOLE_TILT_MAP, key)
    return true
  else
    return false
  end
end

function Base.getproperty(bm::BMultipole, key::Symbol)
  if key in fieldnames(BMultipole)
    return getfield(bm, key)
  elseif haskey(BMULTIPOLE_STRENGTH_MAP, key)
    order, normalized, integrated = BMULTIPOLE_STRENGTH_MAP[key]
    if order == bm.order  && normalized == bm.normalized && integrated == bm.integrated
      return bm.strength
    else
      kys = collect(keys(BMULTIPOLE_STRENGTH_MAP))
      vals = collect(values(BMULTIPOLE_STRENGTH_MAP))
      correctkey = kys[findfirst(t->t==(bm.order,bm.normalized,bm.integrated),vals)]
      error("BMultipole does not have property $key: did you mean $correctkey?")
    end
  elseif haskey(BMULTIPOLE_TILT_MAP, key)
    return bm.tilt
  end
  error("BMultipole $bm does not have property $key")
end

function Base.setproperty!(bm::BMultipole{T}, key::Symbol, value) where {T}
  if key in (:strength,:tilt) 
    return setfield!(bm, key, T(value))
  elseif key in fieldnames(BMultipole)
    return setfield!(bm, key, value)
  elseif haskey(BMULTIPOLE_STRENGTH_MAP, key)
    order, normalized, integrated = BMULTIPOLE_STRENGTH_MAP[key]
    if order == bm.order  && normalized == bm.normalized && integrated == bm.integrated
      return setfield!(bm, :strength, T(value))
    else
      error("BMultipole $bm does not have property $key")
    end
  elseif haskey(BMULTIPOLE_TILT_MAP, key)
    return setfield!(bm, :tilt, T(value))
  end
  error("BMultipole $bm does not have property $key")
end

const BMULTIPOLE_STRENGTH_MAP = Dict{Symbol,Tuple{Int,Bool,Bool}}(
  :Bs  => (0,  false, false),
  :B0  => (1 , false, false),
  :B1  => (2 , false, false),
  :B2  => (3 , false, false),
  :B3  => (4 , false, false),
  :B4  => (5 , false, false),
  :B5  => (6 , false, false),
  :B6  => (7 , false, false),
  :B7  => (8 , false, false),
  :B8  => (9 , false, false),
  :B9  => (10, false, false),
  :B10 => (11, false, false),
  :B11 => (12, false, false),
  :B12 => (13, false, false),
  :B13 => (14, false, false),
  :B14 => (15, false, false),
  :B15 => (16, false, false),
  :B16 => (17, false, false),
  :B17 => (18, false, false),
  :B18 => (19, false, false),
  :B19 => (20, false, false),
  :B20 => (21, false, false),
  :B21 => (22, false, false),

  :Ks  => (0,  true, false),
  :K0  => (1 , true, false),
  :K1  => (2 , true, false),
  :K2  => (3 , true, false),
  :K3  => (4 , true, false),
  :K4  => (5 , true, false),
  :K5  => (6 , true, false),
  :K6  => (7 , true, false),
  :K7  => (8 , true, false),
  :K8  => (9 , true, false),
  :K9  => (10, true, false),
  :K10 => (11, true, false),
  :K11 => (12, true, false),
  :K12 => (13, true, false),
  :K13 => (14, true, false),
  :K14 => (15, true, false),
  :K15 => (16, true, false),
  :K16 => (17, true, false),
  :K17 => (18, true, false),
  :K18 => (19, true, false),
  :K19 => (20, true, false),
  :K20 => (21, true, false),
  :K21 => (22, true, false),

  :BsL  => (0,  false, true),
  :B0L  => (1 , false, true),
  :B1L  => (2 , false, true),
  :B2L  => (3 , false, true),
  :B3L  => (4 , false, true),
  :B4L  => (5 , false, true),
  :B5L  => (6 , false, true),
  :B6L  => (7 , false, true),
  :B7L  => (8 , false, true),
  :B8L  => (9 , false, true),
  :B9L  => (10, false, true),
  :B10L => (11, false, true),
  :B11L => (12, false, true),
  :B12L => (13, false, true),
  :B13L => (14, false, true),
  :B14L => (15, false, true),
  :B15L => (16, false, true),
  :B16L => (17, false, true),
  :B17L => (18, false, true),
  :B18L => (19, false, true),
  :B19L => (20, false, true),
  :B20L => (21, false, true),
  :B21L => (22, false, true),

  :KsL  => (0,  true, true),
  :K0L  => (1 , true, true),
  :K1L  => (2 , true, true),
  :K2L  => (3 , true, true),
  :K3L  => (4 , true, true),
  :K4L  => (5 , true, true),
  :K5L  => (6 , true, true),
  :K6L  => (7 , true, true),
  :K7L  => (8 , true, true),
  :K8L  => (9 , true, true),
  :K9L  => (10, true, true),
  :K10L => (11, true, true),
  :K11L => (12, true, true),
  :K12L => (13, true, true),
  :K13L => (14, true, true),
  :K14L => (15, true, true),
  :K15L => (16, true, true),
  :K16L => (17, true, true),
  :K17L => (18, true, true),
  :K18L => (19, true, true),
  :K19L => (20, true, true),
  :K20L => (21, true, true),
  :K21L => (22, true, true),
)

const BMULTIPOLE_TILT_MAP = Dict{Symbol,Int}(
  :tilts =>   0, 
  :tilt0 =>   1,
  :tilt1 =>   2,
  :tilt2 =>   3,
  :tilt3 =>   4,
  :tilt4 =>   5,
  :tilt5 =>   6,
  :tilt6 =>   7,
  :tilt7 =>   8,
  :tilt8 =>   9,
  :tilt9 =>  10,
  :tilt10 => 11,
  :tilt11 => 12,
  :tilt12 => 13,
  :tilt13 => 14,
  :tilt14 => 15,
  :tilt15 => 16,
  :tilt16 => 17,
  :tilt17 => 18,
  :tilt18 => 19,
  :tilt19 => 20,
  :tilt20 => 21, 
  :tilt21 => 22, 
)

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
  BMultipoleParams(bdict::BMultipoleDict{T}) where {T} = new{T}(bdict)
  function BMultipoleParams{T}(b::BMultipoleParams) where {T} 
    bdict = BMultipoleDict{T}()
    for (order, bm) in b.bdict
      bdict[order] = BMultipole{T}(bm.strength, bm.tilt, order, bm.normalized, bm.integrated)
    end
    return new{T}(bdict)
  end
end

function Base.hasproperty(b::BMultipoleParams, key::Symbol)
  if key in fieldnames(BMultipoleParams)
    return true
  end
  
  if haskey(BMULTIPOLE_STRENGTH_MAP, key)
    order = first(BMULTIPOLE_STRENGTH_MAP[key])
  elseif haskey(BMULTIPOLE_TILT_MAP, key)
    order = first(BMULTIPOLE_TILT_MAP[key])
  else
    return false
  end

  return haskey(b.bdict, order) && hasproperty(b.bdict[order], key)
end

function Base.getproperty(b::BMultipoleParams, key::Symbol)
  if key in fieldnames(BMultipoleParams)
    return getfield(b, key)
  end

  if haskey(BMULTIPOLE_STRENGTH_MAP, key)
    order = first(BMULTIPOLE_STRENGTH_MAP[key])
  elseif haskey(BMULTIPOLE_TILT_MAP, key)
    order = first(BMULTIPOLE_TILT_MAP[key])
  else
    error("BMultipoleParams does not have property $key")
  end

  if haskey(b.bdict, order)
    return getproperty(b.bdict[order], key)
  else
    error("BMultipoleParams does not have property $key")
  end
end

function Base.setproperty!(b::BMultipoleParams{T}, key::Symbol, value) where {T}
  if key in fieldnames(BMultipoleParams)
    return setfield!(b, key, value) # This will error because immutable
  end

  if haskey(BMULTIPOLE_STRENGTH_MAP, key)
    order, normalized, integrated = BMULTIPOLE_STRENGTH_MAP[key]
  elseif haskey(BMULTIPOLE_TILT_MAP, key)
    order = BMULTIPOLE_TILT_MAP[key]
    normalized = true
    integrated = false
  else
    error("BMultipoleParams does not have property $key")
  end

  if !haskey(b.bdict, order)
    b.bdict[order] = BMultipole{T}(0, 0, order, normalized, integrated)
  end
  return setproperty!(b.bdict[order], key, value)
end

function replace(b1::BMultipoleParams{S}, key::Symbol, value) where {S} 
  T = promote_type(S,typeof(value))
  b = BMultipoleParams{T}(b1)

  if haskey(BMULTIPOLE_STRENGTH_MAP, key)
    ord, normalized, integrated = BMULTIPOLE_STRENGTH_MAP[key]
  elseif haskey(BMULTIPOLE_TILT_MAP, key)
    # tilt is first value of this multipole being set
    # This is kind of weird, but we can allow it.
    # default normalized to true, and integrated to false
    ord = BMULTIPOLE_TILT_MAP[key]
    normalized = true
    integrated = false
  else
    error("Unreachable! Replace should only be called when the strength or tilt of a BMultipole is being set such that the number type must be promoted. Please submit an issue to Beamlines.jl")
  end

  if !haskey(b.bdict, ord)
    # First set of this value determines if normalized and/or integrated
    b.bdict[ord] = BMultipole{T}(0, 0, ord, normalized, integrated)
  end
  setproperty!(b.bdict[ord], key, value)
  return b
end

#=

  # Now let's check if the multipole associated with the key exists already:
  if haskey(BMULTIPOLE_STRENGTH_MAP, key)
    ord, normalized, integrated = BMULTIPOLE_STRENGTH_MAP[key]
  elseif haskey(BMULTIPOLE_TILT_MAP, key)
    # tilt is first value of this multipole being set
    # This is kind of weird, but we can allow it.
    # default normalized to true, and integrated to false
    ord = BMULTIPOLE_TILT_MAP[key]
    normalized = true
    integrated = false
  else
    error("Unreachable! Replace should only be called when the strength or tilt of a BMultipole is being set such that the number type must be promoted. Please submit an issue to Beamlines.jl")
  end

  if !haskey(bdict, ord)
    # First set of this value determines if normalized and/or integrated
    bdict[ord] = BMultipole{T}(0, 0, ord, normalized, integrated)
    setproperty!(bdict[ord], key, value)
  end
=#

#=
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

function change(b::BMultipoleParams{old_nrml,S}, Brho) where {old_nrml,S}
  nrml = !old_nrml
  scl = old_nrml ? Brho : 1/Brho
  T = promote_type(S, typeof(scl))
  bdict = BMultipoleDict{nrml,T}()
  for (order, bm) in b.bdict
    bdict[order] = BMultipole{nrml,T}(order, scl*bm.strength, bm.tilt)
  end
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
=#