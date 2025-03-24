@kwdef mutable struct AlignmentParams{T<:Number} <: AbstractParams
  x_offset::T = 0.0
  y_offset::T = 0.0
  x_rot::T    = 0.0
  y_rot::T    = 0.0
  tilt::T     = 0.0
  function AlignmentParams(x_offset, y_offset, x_rot, y_rot, tilt)
    return new{promote_type(
      typeof(x_offset),
      typeof(y_offset),
      typeof(x_rot),
      typeof(y_rot),
      typeof(tilt))}(x_offset, y_offset, x_rot, y_rot, tilt)
  end
end