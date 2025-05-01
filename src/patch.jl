@kwdef mutable struct PatchParams{T<:Number} <: AbstractParams
  ref_t::T = Float32(0.0)                    # Time offset
  ref_x::T = Float32(0.0)                    # Local x coord offset
  ref_y::T = Float32(0.0)                    # Local y coord offset
  ref_z::T = Float32(0.0)                    # Local z coord offset
  ref_tilt::T     = Float32(0.0)             # Roll:  rotation around longitudinal
  ref_y_pitch::T  = Float32(0.0)             # Pitch: rotation around flat radial
  ref_x_pitch::T  = Float32(0.0)             # Yaw:   rotation around global vertical 
  function PatchParams(args...)
    return new{promote_type(map(x->typeof(x),args)...)}(args...)
  end
end

Base.eltype(::PatchParams{T}) where {T} = T
Base.eltype(::Type{PatchParams{T}}) where {T} = T

function Base.isapprox(a::PatchParams, b::PatchParams)
  return a.ref_t          ≈ b.ref_t &&
         a.ref_x          ≈ b.ref_x &&
         a.ref_y          ≈ b.ref_y &&
         a.ref_z          ≈ b.ref_z &&
         a.ref_x_pitch    ≈ b.ref_x_pitch &&
         a.ref_y_pitch    ≈ b.ref_y_pitch &&
         a.ref_tilt       ≈ b.ref_tilt
end

# May want to include reference energy changes
# In the future, would want to include "flexible" patches for global geomtry connections.
#
# The rotations are described in Tait-Bryan angles.