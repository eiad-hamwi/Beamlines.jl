@kwdef struct Beamline{T<:Number}
  line::Vector{LineElement}
  E_ref::T = Beamlines.default_E_ref
end

# Make Brho a property
# rho = p/(qB) -> B*rho = p/q
# p = gamma*m*c*beta = E/c*beta
# E = gamma*m*c^2
# Brho = E/c*sqrt(1 - (m/E)^2)
# beta = sqrt(1 - (mass / E_tot)^2)

Base.propertynames(::Beamline) = (:line, :E_ref, :Brho)

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

# Make E_ref and Brho (in beamline) be properties
# Also make s a property of BeamlineParams
# Note that because BeamlineParams is immutable, not setting rn
Base.propertynames(::BeamlineParams) = (:beamline, :beamline_index, :E_ref, :Brho, :s, :s_downstream)

replace(::BeamlineParams, ::Symbol, ::Any) = error("BeamlineParams is not updateable")
Base.setproperty!(::BeamlineParams, ::Symbol, ::Any) = error("BeamlineParams is not updateable")

function Base.getproperty(bp::BeamlineParams, key::Symbol)
  if key in (:Brho, :E_ref)
    return getproperty(bp.beamline, key) 
  elseif key in (:s, :s_downstream)
    if key == :s
      n = bp.beamline_index - 1
    else
      n = bp.beamline_index
    end
    # s is the sum of the lengths of all preceding elements
    line = bp.beamline.line
    return sum(line[i].L for i in 1:n)
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
    if haskey(line[i].pdict, BeamlineParams)
      if line[i].beamline != bl
        error("Element is already in a beamline")
      else
        # This can be changed later...
        error("Duplicate elements not currently allowed in a beamline")
      end
    end
    line[i].BeamlineParams = BeamlineParams(bl, i)
  end
  
  return bl
end

# We could overload getproperty to disallow accessing line
# directly so elements cannot be removed, but I will deal 
# with that later.
