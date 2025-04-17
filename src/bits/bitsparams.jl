#=

Defines the parameters for the BitsLineElementView 
type.

=#

abstract type AbstractBitsParams end

struct BitsUniversalParams{T} <: AbstractBitsParams
  L::T
end

Base.eltype(::BitsUniversalParams{T}) where {T} = T
Base.eltype(::Type{BitsUniversalParams{T}}) where {T} = T

BitsUniversalParams{T}() where {T} = BitsUniversalParams{T}(T(NaN))

# BMultipoleParams
struct BitsBMultipole{T<:Number,normalized}
  strength::T      
  tilt::T          
  order::Int       
  # normalized::Bool # normalization stored in type
  # integrated::Bool # tobits conversion always gives integrated
  function BitsBMultipole{T,normalized}(strength, tilt, order) where {T,normalized}
    normalized isa Bool || error("Second type parameter must be a Bool specifying if this multipole is normalized or not. Received $normalized")
    return new{T,normalized}(T(strength),T(tilt),order)
  end
end

function BMultipole(bbm::BitsBMultipole{T,normalized}) where {T,normalized}
  return BMultipole(bbm.strength, bbm.tilt, bbm.order, normalized, true)
end

function Base.getproperty(bm::BitsBMultipole{T,normalized}, key::Symbol) where {T,normalized}
  if key == :normalized
    return normalized
  elseif key == :integrated
    return true
  else
    return getfield(bm, key)
  end
end

Base.eltype(::BitsBMultipole{T,normalized}) where {T,normalized} = T
Base.eltype(::Type{BitsBMultipole{T,normalized}}) where {T,normalized} = T

# Default:
function BitsBMultipole{T,normalized}() where {T <: Number,normalized}
  return BitsBMultipole{T,normalized}(T(NaN), T(NaN), -1)
end

const BitsBMultipoleDict{T,N,normalized} = LittleDict{Int8, BitsBMultipole{T,normalized}, SVector{N,Int8}, SVector{N, BitsBMultipole{T,normalized}}} where {T,N,normalized}

struct BitsBMultipoleParams{T,N,normalized} <: AbstractBitsParams
  bdict::BitsBMultipoleDict{T,N,normalized}
end

Base.eltype(::BitsBMultipoleParams{T,N}) where {T,N} = T
Base.eltype(::Type{<:BitsBMultipoleParams{T,N}}) where {T,N} = T

Base.length(::BitsBMultipoleParams{T,N}) where {T,N} = N
Base.length(::Type{<:BitsBMultipoleParams{T,N}}) where {T,N} = N

isnormalized(::BitsBMultipoleParams{T,N,normalized}) where {T,N,normalized} = normalized
isnormalized(::Type{<:BitsBMultipoleParams{T,N,normalized}}) where {T,N,normalized} = normalized

isactive(bbm::BitsBMultipoleParams) = !(all(bbm.bdict.keys .== -1))

# Default:
function BitsBMultipoleParams{T,N,normalized}() where {T,N,normalized}
  k = StaticArrays.sacollect(SVector{N,Int8}, -1 for i in 1:N)
  v = StaticArrays.sacollect(SVector{N, BitsBMultipole{T,normalized}}, BitsBMultipole{T,normalized}() for i in 1:N)
  return BitsBMultipoleParams{T,N,normalized}(BitsBMultipoleDict{T,N,normalized}(k,v))
end

# To regular:
function BMultipoleParams(bbm::Union{Nothing,BitsBMultipoleParams{T}}) where {T}
  if !isactive(bbm)
    return nothing
  end
  bdict = BMultipoleDict{T}()
  for (order, bm) in bbm.bdict
    if order != -1
      bdict[order] = BMultipole(bm)
    end
  end
  return BMultipoleParams(bdict)
end

# BendParams
struct BitsBendParams{T<:Number} <: AbstractBitsParams
  g::T      
  e1::T     
  e2::T     
end

Base.eltype(::BitsBendParams{T}) where {T} = T
Base.eltype(::Type{BitsBendParams{T}}) where {T} = T

isactive(bbp::BitsBendParams) = !isnan(bbp.g)

function BitsBendParams{T}() where {T<:Number}
  return BitsBendParams{T}(T(NaN), T(NaN), T(NaN))
end

function BendParams(bbp::Union{Nothing,BitsBendParams})
  if !isactive(bbp)
    return nothing
  else
    return BendParams(bbp.g,bbp.e1,bbp.e2)
  end
end

# AlignmentParams
struct BitsAlignmentParams{T<:Number} <: AbstractBitsParams
  x_offset::T 
  y_offset::T 
  z_offset::T
  x_rot::T    
  y_rot::T    
  tilt::T     
end

Base.eltype(::BitsAlignmentParams{T}) where {T} = T
Base.eltype(::Type{BitsAlignmentParams{T}}) where {T} = T

isactive(bap::BitsAlignmentParams) = !isnan(bap.x_offset)

function BitsAlignmentParams{T}() where T <: Number
  return BitsAlignmentParams{T}(T(NaN), T(NaN), T(NaN), T(NaN), T(NaN))
end

function AlignmentParams(bap::Union{Nothing,BitsAlignmentParams})
  if !isactive(bap)
    return nothing
  else
    return AlignmentParams(bap.x_offset, bap.y_offset, bap.z_offset, bap.x_rot, bap.y_rot, bap.tilt)
  end
end


