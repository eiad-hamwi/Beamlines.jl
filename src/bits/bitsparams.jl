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
#=
function BitsBMultipole{T}(bm::BMultipole, L, Brho_ref=nothing) where T <: Number
  if bm.normalized
    if isnothing(Brho_ref)
      error("BitsBMultipole only stores the unnormalized strength, and this BMultipole is normalized: please provide Brho_ref")
    else
      strength = bm.strength * Brho_ref
    end
  else
    strength = bm.strength
  end

  if !bm.integrated
    strength *= L
  end
  return BitsBMultipole{T}(T(strength), T(bm.tilt))
end
=#
const BitsBMultipoleDict{T,N,normalized} = LittleDict{Int8, BitsBMultipole{T,normalized}, SVector{N,Int8}, SVector{N, BitsBMultipole{T,normalized}}} where {T,N}

struct BitsBMultipoleParams{T,N,normalized} <: AbstractBitsParams
  bdict::BitsBMultipoleDict{T,N,normalized}
end

Base.eltype(::BitsBMultipoleParams{T,N}) where {T,N} = T
Base.eltype(::Type{<:BitsBMultipoleParams{T,N}}) where {T,N} = T

Base.length(::BitsBMultipoleParams{T,N}) where {T,N} = N
Base.length(::Type{<:BitsBMultipoleParams{T,N}}) where {T,N} = N

isnormalized(::BitsBMultipoleParams{T,N,normalized}) where {T,N,normalized} = normalized
isnormalized(::Type{<:BitsBMultipoleParams{T,N,normalized}}) where {T,N,normalized} = normalized

# Default:
function BitsBMultipoleParams{T,N,normalized}() where {T,N,normalized}
  k = StaticArrays.sacollect(SVector{N,Int8}, -1 for i in 1:N)
  v = StaticArrays.sacollect(SVector{N, BitsBMultipole{T,normalized}}, BitsBMultipole{T,normalized}() for i in 1:N)
  return BitsBMultipoleParams{T,N,normalized}(BitsBMultipoleDict{T,N,normalized}(k,v))
end
#=
function BitsBMultipoleParams{N,T}(b::BMultipoleParams, L, Brho_ref=nothing) where {N,T}
  # Note that with the dict, if the FIRST key is -1 then all of it is zero
  # this is a quick check for if it is inactive
  ki = keys(b.bdict)
  vi = values(b.bdict)
  k = StaticArrays.sacollect(SVector{N,Int8}, -1 for i in 1:N)
  i=1
  for kii in ki
    k = @set k[i] = kii
    i += 1
  end
  v = StaticArrays.sacollect(SVector{N, BitsBMultipole{T}}, BitsBMultipole{T}() for i in 1:N)
  i = 1
  for vii in vi
    v = @set v[i] = BitsBMultipole{T}(vii, L, Brho_ref)
    i += 1
  end
  return BitsBMultipoleParams{N,T}(BitsBMultipoleDict{N,T}(k,v))
end
=#
# BendParams
struct BitsBendParams{T<:Number} <: AbstractBitsParams
  g::T      
  e1::T     
  e2::T     
end

Base.eltype(::BitsBendParams{T}) where {T} = T
Base.eltype(::Type{BitsBendParams{T}}) where {T} = T

function BitsBendParams{T}() where {T<:Number}
  return BitsBendParams{T}(T(NaN), T(NaN), T(NaN))
end

#=
# inactive here means NaNs
function BitsBendParams{T}(::Nothing=nothing) where T <: Number
  return BitsBendParams{T}(T(NaN), T(NaN), T(NaN))
end

function BitsBendParams{T}(bp::BendParams) where T <: Number
  return BitsBendParams{T}(T(bp.g), T(bp.e1), T(bp.e2))
end
=#
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

function BitsAlignmentParams{T}() where T <: Number
  return BitsAlignmentParams{T}(T(NaN), T(NaN), T(NaN), T(NaN), T(NaN))
end
#=
function BitsAlignmentParams{T}(ma::AlignmentParams) where T <: Number
  return BitsAlignmentParams{T}(T(ma.x_offset), T(ma.y_offset), T(ma.x_rot), T(ma.y_rot), T(ma.tilt))
end

=#


