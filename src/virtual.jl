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

function get_bm_strength(ele::LineElement, key::Symbol)
  b = ele.BMultipoleParams
  return @noinline _get_bm_strength(ele, b, key)
end

function _get_bm_strength(ele, b, key)
  order, normalized, integrated = BMULTIPOLE_STRENGTH_MAP[key]
  bm = b.bdict[order]
  strength = bm.strength
  # Yes there is a simpler way to write the below but this 
  # way minimizes type instability.
  if bm.normalized == normalized
    if bm.integrated == integrated
      return strength
    else
      L = ele.L
      if bm.integrated == false 
        # user asking for integrated strength of non-integrated BMultipole
        return strength*L
      else
        # user asking for non-integrated strength of integrated BMultipole
        if L == 0
          error("Unable to get $key of LineElement: Integrated multipole is stored, but the element length L = 0")
        end
        return strength/L
      end
    end
  else
    Brho = ele.Brho
    if bm.integrated == integrated
      if bm.normalized == false
        # user asking for normalized strength of unnormalized BMultipole
        return strength/Brho
      else
        # user asking for unnormalized strength of normalized BMultipole
        return strength*Brho
      end
    else
      L = ele.L
      if bm.normalized == false
        if bm.integrated == false
          return strength/Brho*L
        else
          if L == 0
            error("Unable to get $key of LineElement: Integrated multipole is stored, but the element length L = 0")
          end
          return strength/Brho/L
        end
      else
        if bm.integrated == false
          return strength*Brho*L
        else
          if L == 0
            error("Unable to get $key of LineElement: Integrated multipole is stored, but the element length L = 0")
          end
          return strength*Brho/L
        end
      end
    end
  end
end

function set_bm_strength!(ele::LineElement, key::Symbol, value)
  if !haskey(ele.pdict, BMultipoleParams)
    setindex!(ele.pdict, BMultipoleParams(), BMultipoleParams)
  end
  b = ele.BMultipoleParams
  return @noinline _set_bm_strength!(ele, b, key, value)
end

function _set_bm_strength!(ele, b1::BMultipoleParams{S}, key, value) where {S}
  order, normalized, integrated = BMULTIPOLE_STRENGTH_MAP[key]
  # The case that is an issue is inputing a virtual parameter
  # with type promotion. So first we should promote the entire type 
  # of the parameters struct if necessary and then insert.
  T = promote_type(S,typeof(value))
  if T != S
    b = BMultipoleParams{T}(b1)
    ele.pdict[BMultipoleParams] = b
  else
    b = b1
  end

  # If first set, this now defines normalized + integrated.
  if !haskey(b.bdict, order)
    b.bdict[order] = BMultipole{T}(value, 0, order, normalized, integrated)
    return value
  end

  bm = b.bdict[order]

  if bm.normalized == normalized
    if bm.integrated == integrated
      return setproperty!(bm, :strength, value)
    else
      L = ele.L
      if bm.integrated == false 
        # user setting integrated strength of non-integrated BMultipole
        if L == 0
          error("Unable to set $key of LineElement: Nonintegrated multipole is stored, but the element length L = 0")
        end
        return setproperty!(bm, :strength, value/L)
      else
        # user setting non-integrated strength of integrated BMultipole
        return setproperty!(bm, :strength, value*L)
      end
    end
  else
    Brho = ele.Brho
    if bm.integrated == integrated
      if bm.normalized == false
        # user setting normalized strength of unnormalized BMultipole
        return setproperty!(bm, :strength, value*Brho)
      else
        # user setting unnormalized strength of normalized BMultipole
        return setproperty!(bm, :strength, value/Brho)
      end
    else
      L = ele.L
      if bm.normalized == false
        if bm.integrated == false
          # user setting normalized, integrated strength of 
          # unnormalized, nonintegrated BMultipole
          if L == 0
            error("Unable to set $key of LineElement: Nonintegrated multipole is stored, but the element length L = 0")
          end
          return setproperty!(bm, :strength, value*Brho/L)
        else
          # user setting normalized, nonintegrated strength of 
          # unnormalized, integrated BMultipole
          return setproperty!(bm, :strength, value*Brho*L)
        end
      else
        if bm.integrated == false
          # user setting unnormalized, integrated strength of 
          # normalized, nonintegrated BMultipole
          if L == 0
            error("Unable to set $key of LineElement: Nonintegrated multipole is stored, but the element length L = 0")
          end
          return setproperty!(bm, :strength, value/Brho/L)
        else
          # user setting unnormalized, nonintegrated strength of 
          # normalized, integrated BMultipole
          return setproperty!(bm, :strength, value/Brho*L)
        end
      end
    end
  end
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
  return @noinline _get_B_dep_E_ref(b)
end

function _get_B_dep_E_ref(b)
  v = Vector{Int}(undef, 0)
  for (order, bm) in b.bdict
    if bm.normalized
      push!(v, order-1)
    end
  end
  return v
end

function set_B_dep_E_ref!(ele::LineElement, ::Symbol, value)
  b = ele.BMultipoleParams
  error("Not implemented yet")
  return @noinline _set_B_dep_E_ref!(ele, b, value)
end

function _set_B_dep_E_ref!(ele, b, value::Bool)
  # If Bool, set all of them:

end

const VIRTUAL_GETTER_MAP = Dict{Symbol,Function}(
  :Bs   => get_bm_strength,
  :B0   => get_bm_strength,
  :B1   => get_bm_strength,
  :B2   => get_bm_strength,
  :B3   => get_bm_strength,
  :B4   => get_bm_strength,
  :B5   => get_bm_strength,
  :B6   => get_bm_strength,
  :B7   => get_bm_strength,
  :B8   => get_bm_strength,
  :B9   => get_bm_strength,
  :B10  => get_bm_strength,
  :B11  => get_bm_strength,
  :B12  => get_bm_strength,
  :B13  => get_bm_strength,
  :B14  => get_bm_strength,
  :B15  => get_bm_strength,
  :B16  => get_bm_strength,
  :B17  => get_bm_strength,
  :B18  => get_bm_strength,
  :B19  => get_bm_strength,
  :B20  => get_bm_strength,
  :B21  => get_bm_strength,
  :Ks   => get_bm_strength,
  :K0   => get_bm_strength,
  :K1   => get_bm_strength,
  :K2   => get_bm_strength,
  :K3   => get_bm_strength,
  :K4   => get_bm_strength,
  :K5   => get_bm_strength,
  :K6   => get_bm_strength,
  :K7   => get_bm_strength,
  :K8   => get_bm_strength,
  :K9   => get_bm_strength,
  :K10  => get_bm_strength,
  :K11  => get_bm_strength,
  :K12  => get_bm_strength,
  :K13  => get_bm_strength,
  :K14  => get_bm_strength,
  :K15  => get_bm_strength,
  :K16  => get_bm_strength,
  :K17  => get_bm_strength,
  :K18  => get_bm_strength,
  :K19  => get_bm_strength,
  :K20  => get_bm_strength,
  :K21  => get_bm_strength,
  :BsL  => get_bm_strength,
  :B0L  => get_bm_strength,
  :B1L  => get_bm_strength,
  :B2L  => get_bm_strength,
  :B3L  => get_bm_strength,
  :B4L  => get_bm_strength,
  :B5L  => get_bm_strength,
  :B6L  => get_bm_strength,
  :B7L  => get_bm_strength,
  :B8L  => get_bm_strength,
  :B9L  => get_bm_strength,
  :B10L => get_bm_strength,
  :B11L => get_bm_strength,
  :B12L => get_bm_strength,
  :B13L => get_bm_strength,
  :B14L => get_bm_strength,
  :B15L => get_bm_strength,
  :B16L => get_bm_strength,
  :B17L => get_bm_strength,
  :B18L => get_bm_strength,
  :B19L => get_bm_strength,
  :B20L => get_bm_strength,
  :B21L => get_bm_strength,
  :KsL  => get_bm_strength,
  :K0L  => get_bm_strength,
  :K1L  => get_bm_strength,
  :K2L  => get_bm_strength,
  :K3L  => get_bm_strength,
  :K4L  => get_bm_strength,
  :K5L  => get_bm_strength,
  :K6L  => get_bm_strength,
  :K7L  => get_bm_strength,
  :K8L  => get_bm_strength,
  :K9L  => get_bm_strength,
  :K10L => get_bm_strength,
  :K11L => get_bm_strength,
  :K12L => get_bm_strength,
  :K13L => get_bm_strength,
  :K14L => get_bm_strength,
  :K15L => get_bm_strength,
  :K16L => get_bm_strength,
  :K17L => get_bm_strength,
  :K18L => get_bm_strength,
  :K19L => get_bm_strength,
  :K20L => get_bm_strength,
  :K21L => get_bm_strength,

  :B_dep_E_ref => get_B_dep_E_ref,
)

const VIRTUAL_SETTER_MAP = Dict{Symbol,Function}(
  :Bs   => set_bm_strength!,
  :B0   => set_bm_strength!,
  :B1   => set_bm_strength!,
  :B2   => set_bm_strength!,
  :B3   => set_bm_strength!,
  :B4   => set_bm_strength!,
  :B5   => set_bm_strength!,
  :B6   => set_bm_strength!,
  :B7   => set_bm_strength!,
  :B8   => set_bm_strength!,
  :B9   => set_bm_strength!,
  :B10  => set_bm_strength!,
  :B11  => set_bm_strength!,
  :B12  => set_bm_strength!,
  :B13  => set_bm_strength!,
  :B14  => set_bm_strength!,
  :B15  => set_bm_strength!,
  :B16  => set_bm_strength!,
  :B17  => set_bm_strength!,
  :B18  => set_bm_strength!,
  :B19  => set_bm_strength!,
  :B20  => set_bm_strength!,
  :B21  => set_bm_strength!,
  :Ks   => set_bm_strength!,
  :K0   => set_bm_strength!,
  :K1   => set_bm_strength!,
  :K2   => set_bm_strength!,
  :K3   => set_bm_strength!,
  :K4   => set_bm_strength!,
  :K5   => set_bm_strength!,
  :K6   => set_bm_strength!,
  :K7   => set_bm_strength!,
  :K8   => set_bm_strength!,
  :K9   => set_bm_strength!,
  :K10  => set_bm_strength!,
  :K11  => set_bm_strength!,
  :K12  => set_bm_strength!,
  :K13  => set_bm_strength!,
  :K14  => set_bm_strength!,
  :K15  => set_bm_strength!,
  :K16  => set_bm_strength!,
  :K17  => set_bm_strength!,
  :K18  => set_bm_strength!,
  :K19  => set_bm_strength!,
  :K20  => set_bm_strength!,
  :K21  => set_bm_strength!,
  :BsL  => set_bm_strength!,
  :B0L  => set_bm_strength!,
  :B1L  => set_bm_strength!,
  :B2L  => set_bm_strength!,
  :B3L  => set_bm_strength!,
  :B4L  => set_bm_strength!,
  :B5L  => set_bm_strength!,
  :B6L  => set_bm_strength!,
  :B7L  => set_bm_strength!,
  :B8L  => set_bm_strength!,
  :B9L  => set_bm_strength!,
  :B10L => set_bm_strength!,
  :B11L => set_bm_strength!,
  :B12L => set_bm_strength!,
  :B13L => set_bm_strength!,
  :B14L => set_bm_strength!,
  :B15L => set_bm_strength!,
  :B16L => set_bm_strength!,
  :B17L => set_bm_strength!,
  :B18L => set_bm_strength!,
  :B19L => set_bm_strength!,
  :B20L => set_bm_strength!,
  :B21L => set_bm_strength!,
  :KsL  => set_bm_strength!,
  :K0L  => set_bm_strength!,
  :K1L  => set_bm_strength!,
  :K2L  => set_bm_strength!,
  :K3L  => set_bm_strength!,
  :K4L  => set_bm_strength!,
  :K5L  => set_bm_strength!,
  :K6L  => set_bm_strength!,
  :K7L  => set_bm_strength!,
  :K8L  => set_bm_strength!,
  :K9L  => set_bm_strength!,
  :K10L => set_bm_strength!,
  :K11L => set_bm_strength!,
  :K12L => set_bm_strength!,
  :K13L => set_bm_strength!,
  :K14L => set_bm_strength!,
  :K15L => set_bm_strength!,
  :K16L => set_bm_strength!,
  :K17L => set_bm_strength!,
  :K18L => set_bm_strength!,
  :K19L => set_bm_strength!,
  :K20L => set_bm_strength!,
  :K21L => set_bm_strength!,

  :angle => set_bend_angle!,

  :B_dep_E_ref => set_B_dep_E_ref!,
)


#=

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
=#