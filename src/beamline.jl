@kwdef struct Beamline{T<:Number}
  line::Vector{LineElement}
  E_ref::T = Beamlines.default_E_ref
end

# Make Brho a virtual field
# rho = p/(qB) -> B*rho = p/q
# p = gamma*m*c*beta = E/c*beta
# E = gamma*m*c^2
# Brho = E/c*sqrt(1 - (m/E)^2)
# beta = sqrt(1 - (mass / E_tot)^2)

function Base.getproperty(bl::Beamline, key::Symbol)
  if key == :Brho
    gamma = sqrt(1-(M_ELECTRON/bl.E_ref)^2)
    return bl.E_ref/C_LIGHT*gamma
  elseif key == :E_ref # I have no idea why this makes things faster
    return getfield(bl, :E_ref)
  else
    return getfield(bl, key)
  end
end

struct BeamlineParams{T} <: AbstractParams
  beamline::Beamline{T}
  beamline_index::Int
end

replace(bp::BeamlineParams, key::Symbol, value) = error("BeamlineParams is not updateable!")

function Base.getproperty(bp::BeamlineParams, key::Symbol)
  if key == :E_ref || key == :Brho
    return getproperty(bp.beamline, key) 
  else
    return getfield(bp, key)
  end
end

# Beamlines can be very long, so realistically only 
# Base.Vector should be allowed.
function Beamline(line::Vector{LineElement}; E_ref=Beamlines.default_E_ref)
  bl = Beamline{typeof(E_ref)}(line, E_ref)
  !isnan(E_ref) || error("Please set the reference energy by either specify E_ref or Beamlines.default_E_ref")
  for i in eachindex(line)
    !haskey(line[i].pdict, BeamlineParams) || error("Element is already in a beamline")
    line[i].BeamlineParams = BeamlineParams(bl, i)
  end
  
  return bl
end

# We could overload getproperty to disallow accessing line
# directly so elements cannot be removed, but I will deal 
# with that later.
