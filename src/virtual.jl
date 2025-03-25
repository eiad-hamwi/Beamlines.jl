#=

Functional virtual getters/setters should generally only be used 
when you have a calculation which involves different parameter 
structs, e.g. BMultipoleParams and BeamlineParams are needed to 
get/set normalized field strengths.

If only one parameter struct is needed, then it is better for 
performance to make it a virtual field in the parameter struct 
itself by overriding  getproperty and optionally setproperty! 
for the parameter struct.

Nonetheless the performance difference is not significant so 
functional virtual getters/setters can be used if speed is 
less of a concern.

=#

function get_norm_bm(ele::LineElement, key::Symbol)
  # THIS FUNCTION ONLY REACHED IF KEY is Kn!!!
  @assert haskey(KMULTIPOLE_KEY_MAP, key) "Unreachable! Please submit an issue to Beamlines.jl"

  # Unpack + function barrier
  b = ele.BMultipoleParams
  return @noinline _get_norm_bm(ele, b, key)
end

function _get_norm_bm(ele, b::BMultipoleParams{nrml}, key) where {nrml}
  ord = BMULTIPOLE_ORDER_MAP[key]
  strength = b.bdict[ord].strength
  if nrml == true # If we already are storing normalized values
    return strength
  elseif haskey(ele.pdict, BeamlineParams) # Then we are storing unnormalized
    Brho = ele.Brho
    return strength/Brho
  else
    error("This LineElement stores the unnormalized field strengths as independent variables. To get the normalized field strengths, the LineElement must be within a Beamline with the reference energy E_ref set")
  end
end

function get_bm(ele::LineElement, key::Symbol)
  # THIS FUNCTION ONLY REACHED IF KEY is Bn!!!
  @assert haskey(BMULTIPOLE_KEY_MAP, key) "Unreachable! Please submit an issue to Beamlines.jl"

  # Unpack + function barrier
  b = ele.BMultipoleParams
  return @noinline _get_bm(ele, b, key)
end

function _get_bm(ele, b::BMultipoleParams{nrml}, key) where {nrml}
  ord = BMULTIPOLE_ORDER_MAP[key]
  strength = b.bdict[ord].strength
  if nrml == false # If we already are storing unnormalized values
    return strength
  elseif haskey(ele.pdict, BeamlineParams) # Then we are storing normalized
    Brho = ele.Brho
    return strength*Brho
  else
    error("This LineElement stores the normalized field strengths as independent variables. To get the unnormalized field strengths, the LineElement must be within a Beamline with the reference energy E_ref set")
  end
end


function set_norm_bm!(ele::LineElement, key::Symbol, value)
  # THIS FUNCTION ONLY REACHED IF KEY is Kn!!!
  @assert haskey(KMULTIPOLE_KEY_MAP, key) "Unreachable! Please submit an issue to Beamlines.jl"

  if !haskey(ele.pdict, BMultipoleParams)
    setindex!(ele.pdict, BMultipoleParams{true}(), BMultipoleParams)
  end

  # Unpack + function barrier
  b = ele.BMultipoleParams
  return @noinline _set_norm_bm1!(ele, b, key, value)
end

function _set_norm_bm1!(ele, b::BMultipoleParams{nrml,T}, key, value) where {nrml,T}
  if nrml == true # if we are already storing normalized, set directly:
    ord = BMULTIPOLE_ORDER_MAP[key]
    if promote_type(T,typeof(value)) == T && hasproperty(b, key)
      b.bdict[ord].strength = value
    else
      ele.pdict[BMultipoleParams] = replace(b, key, value)
    end
    return value
  elseif haskey(ele.pdict, BeamlineParams) 
    # Then we are storing unnormalized - properties are with Bs, so map:
    newkey = BMULTIPOLE_NORM_UNNORM_MAP[key]
    Brho = ele.Brho # Unpack
    # Another function barrier now
    return @noinline _set_norm_bm2!(ele, b, newkey, value, Brho)
  else
    error("This LineElement stores the unnormalized field strengths as independent variables. To set the normalized field strengths, the LineElement must be within a Beamline with the reference energy E_ref set")
  end
end

function _set_norm_bm2!(ele, b::BMultipoleParams{nrml,T}, newkey, value, Brho) where {nrml,T}
  ord = BMULTIPOLE_ORDER_MAP[newkey]
  strength = value*Brho
  if promote_type(T,typeof(strength)) == T && hasproperty(b, newkey)
    b.bdict[ord].strength = strength
  else
    ele.pdict[BMultipoleParams] = replace(b, newkey, strength)
  end
  return value
end


function set_bm!(ele::LineElement, key::Symbol, value)
  # THIS FUNCTION ONLY REACHED IF KEY is Bn!!!
  @assert haskey(BMULTIPOLE_KEY_MAP, key) "Unreachable! Please submit an issue to Beamlines.jl"
  
  if !haskey(ele.pdict, BMultipoleParams)
    setindex!(ele.pdict, BMultipoleParams{false}(), BMultipoleParams)
  end

  # Unpack + function barrier
  b = ele.BMultipoleParams
  return @noinline _set_bm1!(ele, b, key, value)
end

function _set_bm1!(ele, b::BMultipoleParams{nrml,T}, key, value) where {nrml,T}
  if nrml == false # if we are already storing unnormalized, set directly:
    ord = BMULTIPOLE_ORDER_MAP[key]
    if promote_type(T,typeof(value)) == T && hasproperty(b, key)
      b.bdict[ord].strength = value
    else
      ele.pdict[BMultipoleParams] = replace(b, key, value)
    end
    return value
  elseif haskey(ele.pdict, BeamlineParams) 
    # Then we are storing normalized - properties are with Ks, so map:
    newkey = BMULTIPOLE_NORM_UNNORM_MAP[key]
    Brho = ele.Brho # Unpack
    # Another function barrier now
    return @noinline _set_bm2!(ele, b, newkey, value, Brho)
  else
    error("This LineElement stores the normalized field strengths as independent variables. To set the unnormalized field strengths, the LineElement must be within a Beamline with the reference energy E_ref set")
  end
end

function _set_bm2!(ele, b::BMultipoleParams{nrml,T}, newkey, value, Brho) where {nrml,T}
  ord = BMULTIPOLE_ORDER_MAP[newkey]
  strength = value/Brho
  if promote_type(T,typeof(strength)) == T  && hasproperty(b, newkey)
    b.bdict[ord].strength = strength
  else
    ele.pdict[BMultipoleParams] = replace(b, newkey, strength)
  end
  return value
end


#=

  # Get corresponding magnetic field symbol to set
  sym = BMULTIPOLE_VIRTUAL_MAP[key]

  # If in a Beamline use that E_ref, else go global
  if haskey(ele.pdict, BeamlineParams) 
    Brho = ele.Brho
  else
    !isnan(Beamlines.default_E_ref) || error("LineElement not in a Beamline: please set Beamlines.default_E_ref to calculate normalized field strengths")
    Brho = calc_Brho(Beamlines.default_E_ref)
  end
  return @noinline _set_norm_bm!(ele, Brho, sym, value)
end
=#

function _set_norm_bm!(b, key, value)
  Bk = value*Brho
  setproperty!(ele, key, Bk)
  return value
end


#=
function _get_norm_bm(bp, Brho, key)
  ord, sym = BMULTIPOLE_KEY_MAP[BMULTIPOLE_VIRTUAL_MAP[key]]
  Bk = getproperty(bp.bdict[ord], sym)
  return Bk/Brho
end
=#
#=
function get_bend_angle(ele::LineElement, ::Symbol)
  bp = ele.BendParams
  up = ele.UniversalParams
  return @noinline _get_bend_angle(bp, up)
end
=#
# Right now get bend angle returns geometric value, but set bend angle 
# sets the B field AND g. Maybe we need something more consistent?
#=
function _get_bend_angle(bp, up)
  return bp.g*up.L
end
=#
#=
function set_norm_bm!(ele::LineElement, key::Symbol, value)
  # Get corresponding magnetic field symbol to set
  sym = BMULTIPOLE_VIRTUAL_MAP[key]

  # If in a Beamline use that E_ref, else go global
  if haskey(ele.pdict, BeamlineParams) 
    Brho = ele.Brho
  else
    !isnan(Beamlines.default_E_ref) || error("LineElement not in a Beamline: please set Beamlines.default_E_ref to calculate normalized field strengths")
    Brho = calc_Brho(Beamlines.default_E_ref)
  end
  return @noinline _set_norm_bm!(ele, Brho, sym, value)
end

function _set_norm_bm!(ele, Brho, key, value)
  Bk = value*Brho
  setproperty!(ele, key, Bk)
  return value
end

function set_bend_angle!(ele::LineElement, ::Symbol, value)
  up = ele.UniversalParams
  if haskey(ele.pdict, BeamlineParams) 
    Brho = ele.Brho
  else
    !isnan(Beamlines.default_E_ref) || error("LineElement not in a Beamline: please set Beamlines.default_E_ref to calculate normalized field strengths")
    Brho = calc_Brho(Beamlines.default_E_ref)
  end
  return @noinline _set_bend_angle!(ele, up, Brho, value)
end

function _set_bend_angle!(ele, up, Brho, value)
  # Angle = bp.B_bend/Brho*up.L
  # We should clean this up and find a more consistent definition
  B_bend = value*Brho/up.L
  g = value/up.L
  setproperty!(ele, :B_bend, B_bend)
  setproperty!(ele, :g, g)
  return value
end
=#