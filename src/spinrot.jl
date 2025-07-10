@kwdef mutable struct SnakeParams{T<:Number} <: AbstractParams
    snake_axis::Vector{T} = Float32[0.0, 0.0, 0.0]
    snake_angle::T = Float32(0.0)
    function SnakeParams(snake_axis, snake_angle)
        return new{promote_type(eltype(snake_axis), typeof(snake_angle))}(snake_axis, snake_angle)
    end
end

Base.eltype(::SnakeParams{T}) where {T} = T
Base.eltype(::Type{SnakeParams{T}}) where {T} = T

Base.isapprox(a::SnakeParams, b::SnakeParams) = a.snake_axis ≈ b.snake_axis && a.snake_angle ≈ b.snake_angle