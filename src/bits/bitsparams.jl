#=

Defines the parameters for the BitsLineElementView 
type.

=#

abstract type AbstractBitsParams end

#Base.convert(::Type{T}, p::Union{AbstractParams,Nothing}) where {T <: AbstractBitsParams} = T(p)


struct BitsUniversalParams{T} <: AbstractBitsParams
  L::T
end

Base.eltype(::BitsUniversalParams{T}) where {T} = T
Base.eltype(::Type{BitsUniversalParams{T}}) where {T} = T



# BMultipoleParams
struct BitsBMultipole{T<:Number}
  strength::T      
  tilt::T          
  order::Int       
  # normalized::Bool # tobits conversion always gives unnormalized
  # integrated::Bool # tobits conversion always gives integrated
end

@inline function Base.getproperty(bm::BitsBMultipole, key::Symbol)
  if key == :normalized
    return false
  elseif key == :integrated
    return true
  else
    return getfield(bm, key)
  end
end

#Base.convert(::Type{T}, bm::BMultipole) where {T<:BitsBMultipole} = T(bm)

Base.eltype(::BitsBMultipole{T}) where {T} = T
Base.eltype(::Type{BitsBMultipole{T}}) where {T} = T

# Default:
function BitsBMultipole{T}() where T <: Number
  return BitsBMultipole{T}(T(NaN), T(NaN))
end

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

const BitsBMultipoleDict{N,T} = LittleDict{Int8, BitsBMultipole{T}, SVector{N,Int8}, SVector{N, BitsBMultipole{T}}} where {N,T}

struct BitsBMultipoleParams{N,T} <: AbstractBitsParams
  bdict::BitsBMultipoleDict{N,T}
end

Base.eltype(::BitsBMultipoleParams{N,T}) where {N,T} = T
Base.eltype(::Type{BitsBMultipoleParams{N,T}}) where {N,T} = T

Base.length(::BitsBMultipoleParams{N}) where {N} = N
Base.length(::Type{<:BitsBMultipoleParams{N}}) where {N} = N

# Default:
function BitsBMultipoleParams{N,T}(::Nothing, L, Brho_ref=nothing) where {N,T}
  k = StaticArrays.sacollect(SVector{N,Int8}, -1 for i in 1:N)
  v = StaticArrays.sacollect(SVector{N, BitsBMultipole{T}}, BitsBMultipole{T}() for i in 1:N)
  return BitsBMultipoleParams{N,T}(BitsBMultipoleDict{N,T}(k,v))
end

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

# BendParams
struct BitsBendParams{T<:Number} <: AbstractBitsParams
  g::T      
  e1::T     
  e2::T     
end

# inactive here means NaNs
function BitsBendParams{T}(::Nothing=nothing) where T <: Number
  return BitsBendParams{T}(T(NaN), T(NaN), T(NaN))
end

function BitsBendParams{T}(bp::BendParams) where T <: Number
  return BitsBendParams{T}(T(bp.g), T(bp.e1), T(bp.e2))
end

# AlignmentParams
struct BitsAlignmentParams{T<:Number} <: AbstractBitsParams
  x_offset::T 
  y_offset::T 
  x_rot::T    
  y_rot::T    
  tilt::T     
end

function BitsAlignmentParams{T}(::Nothing=nothing) where T <: Number
  return BitsAlignmentParams{T}(T(NaN), T(NaN), T(NaN), T(NaN), T(NaN))
end

function BitsAlignmentParams{T}(ma::AlignmentParams) where T <: Number
  return BitsAlignmentParams{T}(T(ma.x_offset), T(ma.y_offset), T(ma.x_rot), T(ma.y_rot), T(ma.tilt))
end




