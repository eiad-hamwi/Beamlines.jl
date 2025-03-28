
# Static phase space coordinate vector
Base.@kwdef struct Coord{T} <: FieldVector{4, T} 
  x::T  = 0.0
  px::T = 0.0
  y::T  = 0.0
  py::T = 0.0
end

mutable struct Bunch{S,T<:StructVector{<:Coord}}
  species::Species
  Brho_0::S
  const v::T
end

struct Particle{S,T}
  species::Species
  Brho_0::S
  v::Coord{T}
end

Bunch(N; Brho_0=60.0, species=ELECTRON) = Bunch(x=rand(N), px=rand(N), y=rand(N), py=rand(N), Brho_0=Brho_0, species=species)
"""
    Bunch(; 
      species::Species=ELECTRON, 
      Brho_0=60.0, 
      x::Union{Number,AbstractVector}=0.0, 
      px::Union{Number,AbstractVector}=0.0, 
      y::Union{Number,AbstractVector}=0.0, 
      py::Union{Number,AbstractVector}=0.0, 
    )


Initializes a `Bunch`. Any of the specified phase space coordinates may be scalar `Number`s or 
`Vector`s to store as a structure-of-arrays. Internally, all phase space coordinates are stored 
as `Vector`s. If all phase space coordinates are scalar `Number`s, then a `Bunch` is created with 
a single particle. If any of the coordinates are specified as `Vector`s, then all other scalar-
specified quantities are `fill`-ed as `Vector`s. For example, `Bunch(x=1.0, y=[2,3])` creates a 
bunch with two particles having the phase space coordinates `[1.0, 0.0, 2.0, 0.0]` 
and `[1.0, 0.0, 3.0, 0.0]`.
"""
function Bunch(; 
  species::Species=ELECTRON, 
  Brho_0=60.0, 
  x::Union{Number,AbstractVector}=0.0, 
  px::Union{Number,AbstractVector}=0.0, 
  y::Union{Number,AbstractVector}=0.0, 
  py::Union{Number,AbstractVector}=0.0, 
)
                
  idx_vector = findfirst(t->t isa AbstractVector, (x, px, y, py))
  if isnothing(idx_vector)
    N_particle = 1
  else
    N_particle = length(getindex((x, px, y, py), idx_vector))
  end

  T = promote_type(eltype(x), eltype(px), eltype(y),eltype(py)) 
  
  function make_vec_T(T, vec_or_num, N_particle)
    if vec_or_num isa AbstractVector
      if eltype(vec_or_num) == T
        return vec_or_num
      else
        return T.(vec_or_num)
      end
    else
      if isimmutable(T)
        return fill(T(vec_or_num),  N_particle)
      else
        vec = Vector{T}(undef, N_particle)
        for i in eachindex(vec)
          vec[i] = T(vec_or_num)
        end
        return vec
      end
    end
  end

  x1  = make_vec_T(T, x,  N_particle)
  px1 = make_vec_T(T, px, N_particle)
  y1  = make_vec_T(T, y,  N_particle)
  py1 = make_vec_T(T, py, N_particle)
  v = StructArray{Coord{T}}((x1, px1, y1, py1))

  return Bunch(species, Brho_0, v)
end


function Particle(bunch::Bunch, idx::Integer=1)
  v = bunch.v[idx] # StructArrays handles this!
  return Particle(bunch.species, bunch.Brho_0, v)
end