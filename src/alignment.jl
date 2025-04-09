@kwdef mutable struct AlignmentParams{T<:Number} <: AbstractParams
  x_offset::T = 0.0
  y_offset::T = 0.0
  x_rot::T    = 0.0
  y_rot::T    = 0.0
  tilt::T     = 0.0
  function AlignmentParams(args...)
    return new{promote_type(typeof.(args)...)}(args...)
  end
end

Base.eltype(::AlignmentParams{T}) where {T} = T
Base.eltype(::Type{AlignmentParams{T}}) where {T} = T

