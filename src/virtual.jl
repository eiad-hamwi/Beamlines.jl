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
  # Unpack + function barrier
  # First unpack to check if nrml = true or nrml = false
  b = ele.BMultipoleParams # In this unpacking step we now
  return @noinline _get_norm_bm1(b, key)
  #=
  if haskey(ele.pdict, BeamlineParams) 
    Brho = ele.Brho
  else
    !isnan(Beamlines.default_E_ref) || error("LineElement not in a Beamline: please set Beamlines.default_E_ref to calculate normalized field strengths")
    Brho = calc_Brho(Beamlines.default_E_ref)
  end
  return @noinline _get_norm_bm(bp, Brho, key)
  =#
end

function _get_norm_bm(b::BMultipoleParams{nrml}, key) where {nrml}
  ord, sym = BMULTIPOLE_KEY_MAP[BMULTIPOLE_VIRTUAL_MAP[key]]
  strength = getproperty(b.bdict[ord], sym)
  if nrml == true # If we already are storing normalized values
    
  else

  end
end
#=
function _get_norm_bm(bp, Brho, key)
  ord, sym = BMULTIPOLE_KEY_MAP[BMULTIPOLE_VIRTUAL_MAP[key]]
  Bk = getproperty(bp.bdict[ord], sym)
  return Bk/Brho
end
=#
function get_bend_angle(ele::LineElement, ::Symbol)
  bp = ele.BendParams
  up = ele.UniversalParams
  return @noinline _get_bend_angle(bp, up)
end

# Right now get bend angle returns geometric value, but set bend angle 
# sets the B field AND g. Maybe we need something more consistent?
function _get_bend_angle(bp, up)
  return bp.g*up.L
end

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
