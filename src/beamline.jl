@kwdef mutable struct Beamline
  const line::Vector{LineElement}
  const species::Species
  E_ref::Number

  # Beamlines can be very long, so realistically only 
  # Base.Vector should be allowed.
  function Beamline(line::Vector{LineElement}; E_ref=nothing, Brho=nothing, species::Species=ELECTRON)
    if !isnothing(Brho)
      if !isnothing(E_ref)
        error("Please specify one of either Brho or E_ref")
      else
        E_ref = calc_E_ref(species, Brho)
      end
    elseif isnothing(E_ref)
      error("Please specify one of either Brho or E_ref")
    end

    bl = new(line, species, E_ref)
    for i in eachindex(line)
      if haskey(line[i].pdict, BeamlineParams)
        if line[i].beamline != bl
          error("Element is already in a beamline")
        else
          # This can be changed later...
          error("Duplicate elements not currently allowed in a beamline")
          #line[i] = deepcopy_no_beamline(line[line[i].beamline_index])
        end
      end
      
      line[i].BeamlineParams = BeamlineParams(bl, i)
    end
    
    return bl
  end
end

function Base.getproperty(bl::Beamline, key::Symbol)
  if key == :Brho
    return @noinline calc_Brho(bl.species, bl.E_ref)
  else
    return getfield(bl, key)
  end
end

function Base.setproperty!(bl::Beamline, key::Symbol, value)
  if key == :Brho
    E_ref = @noinline calc_E_ref(bl.species, value)
    return setfield!(bl, :E_ref, E_ref)
  else
    return setfield!(bl, key, value)
  end
end

# Make Brho a property
# rho = p/(qB) -> B*rho = p/q
# p = gamma*m*c*beta = E/c*beta
# E = gamma*m*c^2
# Brho = E/c*sqrt(1 - (m/E)^2)
# beta = sqrt(1 - (mass / E_tot)^2)

Base.propertynames(::Beamline) = (:line, :binfo, :E_ref, :Brho, :species)

struct BeamlineParams <: AbstractParams
  beamline::Beamline
  beamline_index::Int
end

# Make E_ref and Brho (in beamline) be properties
# Also make s a property of BeamlineParams
# Note that because BeamlineParams is immutable, not setting rn
Base.propertynames(::BeamlineParams) = (:beamline, :beamline_index, :E_ref, :Brho, :species, :s, :s_downstream)

function Base.setproperty!(bp::BeamlineParams, key::Symbol, value)
  setproperty!(bp.beamline, key, value)
end

# Because BeamlineParams contains an abstract type, "replacing" it 
# is just modifying the field and returning itself
function replace(bp::BeamlineParams, key::Symbol, value)
  if key in (:E_ref,:Brho)
    setproperty!(bp, key, value)
    return bp
  else
    error("BeamlineParams property $key cannot be modified")
  end
end

function Base.getproperty(bp::BeamlineParams, key::Symbol)
  if key in (:Brho, :E_ref, :species)
    return getproperty(bp.beamline, key) 
  elseif key in (:s, :s_downstream)
    if key == :s
      n = bp.beamline_index - 1
      if n == 0
        return 0.0
      end
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


# We could overload getproperty to disallow accessing line
# directly so elements cannot be removed, but I will deal 
# with that later.
