@kwdef mutable struct PatchParams{T<:Number} <: AbstractParams
  patch_dt::T        = Float32(0.0)             # Time offset
  patch_dx::T        = Float32(0.0)             # Local x coord offset
  patch_dy::T        = Float32(0.0)             # Local y coord offset
  patch_dz::T        = Float32(0.0)             # Local z coord offset
  patch_dx_rot::T    = Float32(0.0)             # Pitch: rotation around flat radial
  patch_dy_rot::T    = Float32(0.0)             # Yaw:   rotation around global vertical
  patch_dz_rot::T    = Float32(0.0)             # Roll:  rotation around longitudinal
  function PatchParams(args...)
    return new{promote_type(map(x->typeof(x),args)...)}(args...)
  end
end

Base.eltype(::PatchParams{T}) where {T} = T
Base.eltype(::Type{PatchParams{T}}) where {T} = T

function Base.isapprox(a::PatchParams, b::PatchParams)
  return a.patch_dt          ≈ b.patch_dt &&
         a.patch_dx          ≈ b.patch_dx &&
         a.patch_dy          ≈ b.patch_dy &&
         a.patch_dz          ≈ b.patch_dz &&
         a.patch_dx_rot      ≈ b.patch_dx_rot &&
         a.patch_dy_rot      ≈ b.patch_dy_rot &&
         a.patch_dz_rot      ≈ b.patch_dz_rot
end

# May want to include reference energy changes
# In the future, would want to include "flexible" patches for global geomtry connections.
#
# The rotations are expressed as Tait-Bryan angles.