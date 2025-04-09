#=

Contains routines to convert a LineElement to an isbits, 
regular format based on the passed Beamline. This does not 
have the same flexibility nor functionality as a regular 
LineElement, but can be used for fast tracking e.g. on a GPU.

On a CPU, especially during optimization, regular LineElement 
will almost certainly be faster, because the BitsLineElement
requires ALL elements to have the exact same types and structure,
so if only quad strength is a TPSA, then all quad strengths must 
be a TPSA.

=#
abstract type AbstractBitsParams end

Base.convert(::Type{T}, p::Union{AbstractParams,Nothing}) where {T <: AbstractBitsParams} = T(p)


# BMultipoleParams
struct BitsBMultipole{T<:Number}
  strength::T      
  tilt::T          
  order::Int       
  normalized::Bool 
  integrated::Bool 
end

Base.convert(::Type{T}, bm::BMultipole) where {T<:BitsBMultipole} = T(bm)

Base.eltype(::BitsBMultipole{T}) where {T} = T
Base.eltype(::Type{BitsBMultipole{T}}) where {T} = T

# Default:
function BitsBMultipole{T}() where T <: Number
  return BitsBMultipole{T}(T(0), T(0), -1, false, false)
end

function BitsBMultipole{T}(bm::BMultipole) where T <: Number
  return BitsBMultipole{T}(T(bm.strength), T(bm.tilt), bm.order, bm.normalized, bm.integrated)
end

const BitsBMultipoleDict{N,T} = LittleDict{Int, BitsBMultipole{T}, SVector{N,Int}, SVector{N, BitsBMultipole{T}}} where {N,T}

struct BitsBMultipoleParams{N,T} <: AbstractBitsParams
  isactive::Bool
  bdict::BitsBMultipoleDict{N,T}
end

Base.eltype(::BitsBMultipoleParams{N,T}) where {N,T} = T
Base.eltype(::Type{BitsBMultipoleParams{N,T}}) where {N,T} = T

Base.length(::BitsBMultipoleParams{N}) where {N} = N
Base.length(::Type{<:BitsBMultipoleParams{N}}) where {N} = N

# Default:
function BitsBMultipoleParams{N,T}(::Nothing=nothing) where {N,T}
  k = StaticArrays.sacollect(SVector{N,Int}, -1 for i in 1:N)
  v = StaticArrays.sacollect(SVector{N, BitsBMultipole{T}}, BitsBMultipole{T}() for i in 1:N)
  return BitsBMultipoleParams{N,T}(false, BitsBMultipoleDict{N,T}(k,v))
end

function BitsBMultipoleParams{N,T}(b::BMultipoleParams) where {N,T}
  ki = keys(b.bdict)
  vi = values(b.bdict)
  k = StaticArrays.sacollect(SVector{N,Int}, -1 for i in 1:N)
  i=1
  for kii in ki
    k = @set k[i] = kii
    i += 1
  end
  v = StaticArrays.sacollect(SVector{N, BitsBMultipole{T}}, BitsBMultipole{T}() for i in 1:N)
  i = 1
  for vii in vi
    v = @set v[i] = BitsBMultipole{T}(vii)
    i += 1
  end
  return BitsBMultipoleParams{N,T}(true, BitsBMultipoleDict{N,T}(k,v))
end

# BendParams
struct BitsBendParams{T<:Number} <: AbstractBitsParams
  isactive::Bool
  g::T      
  e1::T     
  e2::T     
end

function BitsBendParams{T}(::Nothing=nothing) where T <: Number
  return BitsBendParams{T}(false, T(0), T(0), T(0))
end

function BitsBendParams{T}(bp::BendParams) where T <: Number
  return BitsBendParams{T}(true, T(bp.g), T(bp.e1), T(bp.e2))
end

# AlignmentParams
struct BitsAlignmentParams{T<:Number} <: AbstractBitsParams
  isactive::Bool
  x_offset::T 
  y_offset::T 
  x_rot::T    
  y_rot::T    
  tilt::T     
end

function BitsAlignmentParams{T}(::Nothing=nothing) where T <: Number
  return BitsAlignmentParams{T}(false, T(0), T(0), T(0), T(0), T(0))
end

function BitsAlignmentParams{T}(ma::AlignmentParams) where T <: Number
  return BitsAlignmentParams{T}(true, T(ma.x_offset), T(ma.y_offset), T(ma.x_rot), T(ma.y_rot), T(ma.tilt))
end




