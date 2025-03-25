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
  if promote_type(T,typeof(strength)) == T && hasproperty(b, newkey)
    b.bdict[ord].strength = strength
  else
    ele.pdict[BMultipoleParams] = replace(b, newkey, strength)
  end
  return value
end

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

function set_bend_angle!(ele::LineElement, ::Symbol, value)
  up = ele.UniversalParams
  return @noinline _set_bend_angle!(ele, up, value)
end

function _set_bend_angle!(ele, up, value)
  # Angle = K0*up.L -> K0 = angle/up.L
  # Currently angle sets both
  # We should clean this up and find a more consistent definition
  K0 = value/up.L
  setproperty!(ele, :K0, K0)
  setproperty!(ele, :g, K0)
  return value
end


function get_B_dep_E_ref(ele::LineElement, ::Symbol)
  b = ele.BMultipoleParams
  if isnormalized(b)
    return true
  else
    return false
  end
end

function set_B_dep_E_ref!(ele, ::Symbol, value)
  if !haskey(ele.pdict, BMultipoleParams)
    setindex!(ele.pdict, BMultipoleParams{value}(), BMultipoleParams)
    return value
  end
  b = ele.BMultipoleParams
  if value == isnormalized(b)
    return value
  end
  Brho = ele.Brho
  ele.pdict[BMultipoleParams] = change(b, Brho)
  return value
end

const VIRTUAL_GETTER_MAP = Dict{Symbol,Function}(
  :Ks =>  get_norm_bm,
  :K0 =>  get_norm_bm,
  :K1 =>  get_norm_bm,
  :K2 =>  get_norm_bm,
  :K3 =>  get_norm_bm,
  :K4 =>  get_norm_bm,
  :K5 =>  get_norm_bm,
  :K6 =>  get_norm_bm,
  :K7 =>  get_norm_bm,
  :K8 =>  get_norm_bm,
  :K9 =>  get_norm_bm,
  :K10 => get_norm_bm,
  :K11 => get_norm_bm,
  :K12 => get_norm_bm,
  :K13 => get_norm_bm,
  :K14 => get_norm_bm,
  :K15 => get_norm_bm,
  :K16 => get_norm_bm,
  :K17 => get_norm_bm,
  :K18 => get_norm_bm,
  :K19 => get_norm_bm,
  :K20 => get_norm_bm,
  :K21 => get_norm_bm,

  :Bs =>  get_bm,
  :B0 =>  get_bm,
  :B1 =>  get_bm,
  :B2 =>  get_bm,
  :B3 =>  get_bm,
  :B4 =>  get_bm,
  :B5 =>  get_bm,
  :B6 =>  get_bm,
  :B7 =>  get_bm,
  :B8 =>  get_bm,
  :B9 =>  get_bm,
  :B10 => get_bm,
  :B11 => get_bm,
  :B12 => get_bm,
  :B13 => get_bm,
  :B14 => get_bm,
  :B15 => get_bm,
  :B16 => get_bm,
  :B17 => get_bm,
  :B18 => get_bm,
  :B19 => get_bm,
  :B20 => get_bm,
  :B21 => get_bm,

  :B_dep_E_ref => get_B_dep_E_ref,
  :angle => get_bend_angle,
)

const VIRTUAL_SETTER_MAP = Dict{Symbol,Function}(
  :Ks =>  set_norm_bm!,
  :K0 =>  set_norm_bm!,
  :K1 =>  set_norm_bm!,
  :K2 =>  set_norm_bm!,
  :K3 =>  set_norm_bm!,
  :K4 =>  set_norm_bm!,
  :K5 =>  set_norm_bm!,
  :K6 =>  set_norm_bm!,
  :K7 =>  set_norm_bm!,
  :K8 =>  set_norm_bm!,
  :K9 =>  set_norm_bm!,
  :K10 => set_norm_bm!,
  :K11 => set_norm_bm!,
  :K12 => set_norm_bm!,
  :K13 => set_norm_bm!,
  :K14 => set_norm_bm!,
  :K15 => set_norm_bm!,
  :K16 => set_norm_bm!,
  :K17 => set_norm_bm!,
  :K18 => set_norm_bm!,
  :K19 => set_norm_bm!,
  :K20 => set_norm_bm!,
  :K21 => set_norm_bm!,

  :Bs =>  set_bm!,
  :B0 =>  set_bm!,
  :B1 =>  set_bm!,
  :B2 =>  set_bm!,
  :B3 =>  set_bm!,
  :B4 =>  set_bm!,
  :B5 =>  set_bm!,
  :B6 =>  set_bm!,
  :B7 =>  set_bm!,
  :B8 =>  set_bm!,
  :B9 =>  set_bm!,
  :B10 => set_bm!,
  :B11 => set_bm!,
  :B12 => set_bm!,
  :B13 => set_bm!,
  :B14 => set_bm!,
  :B15 => set_bm!,
  :B16 => set_bm!,
  :B17 => set_bm!,
  :B18 => set_bm!,
  :B19 => set_bm!,
  :B20 => set_bm!,
  :B21 => set_bm!,

  :B_dep_E_ref => set_B_dep_E_ref!,
  :angle => set_bend_angle!,
)