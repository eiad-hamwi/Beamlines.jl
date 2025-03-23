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
  bp = ele.BMultipoleParams
  if haskey(ele.pdict, BeamlineParams) 
    blp = ele.BeamlineParams
    return @noinline _get_norm_bm1(bp, blp, key)
  else
    !isnan(Beamlines.default_E_ref) || error("LineElement not in a Beamline: please set Beamlines.default_E_ref to calculate normalized field strengths")
    return @noinline _get_norm_bm2(bp, Beamlines.default_E_ref, key)
  end
end

function _get_norm_bm1(bp, blp, key)
  ord, sym = BMULTIPOLE_KEY_MAP[BMULTIPOLE_VIRTUAL_MAP[key]]
  Bn = getproperty(bp.bdict[ord], sym)
  return Bn/blp.Brho
end

function _get_norm_bm2(bp, E_ref, key)
  ord, sym = BMULTIPOLE_KEY_MAP[BMULTIPOLE_VIRTUAL_MAP[key]]
  Bn = getproperty(bp.bdict[ord], sym)
  gamma = sqrt(1-(M_ELECTRON/E_ref)^2)
  Brho = E_ref/C_LIGHT*gamma
  return Bn/Brho
end

const VIRTUAL_GETTER_MAP = Dict{Symbol,Function}(
  :Kn0 =>  get_norm_bm,
  :Kn1 =>  get_norm_bm,
  :Kn2 =>  get_norm_bm,
  :Kn3 =>  get_norm_bm,
  :Kn4 =>  get_norm_bm,
  :Kn5 =>  get_norm_bm,
  :Kn6 =>  get_norm_bm,
  :Kn7 =>  get_norm_bm,
  :Kn8 =>  get_norm_bm,
  :Kn9 =>  get_norm_bm,
  :Kn10 => get_norm_bm,
  :Kn11 => get_norm_bm,
  :Kn12 => get_norm_bm,
  :Kn13 => get_norm_bm,
  :Kn14 => get_norm_bm,
  :Kn15 => get_norm_bm,
  :Kn16 => get_norm_bm,
  :Kn17 => get_norm_bm,
  :Kn18 => get_norm_bm,
  :Kn19 => get_norm_bm,
  :Kn20 => get_norm_bm,
  :Kn21 => get_norm_bm,
)

function set_norm_bm!(ele::LineElement, key::Symbol, value)
  # Get corresponding magnetic field symbol to set
  sym = BMULTIPOLE_VIRTUAL_MAP[key]

  # If in a Beamline use that E_ref, else go global
  if haskey(ele.pdict, BeamlineParams) 
    blp = ele.BeamlineParams
    return @noinline _set_norm_bm1!(ele, blp, sym, value)
  else
    !isnan(Beamlines.default_E_ref) || error("LineElement not in a Beamline: please set Beamlines.default_E_ref to calculate normalized field strengths")
    return @noinline _set_norm_bm2!(ele, Beamlines.default_E_ref, sym, value)
  end
end

function _set_norm_bm1!(ele, blp, key, value)
  Bn = value*blp.Brho
  return setproperty!(ele, key, Bn)
end

function _set_norm_bm2!(ele, E_ref, key, value)
  gamma = sqrt(1-(M_ELECTRON/E_ref)^2)
  Brho = E_ref/C_LIGHT*gamma
  return setproperty!(ele, key, value * Brho)
end

const VIRTUAL_SETTER_MAP = Dict{Symbol,Function}(
  :Kn0 =>  set_norm_bm!,
  :Kn1 =>  set_norm_bm!,
  :Kn2 =>  set_norm_bm!,
  :Kn3 =>  set_norm_bm!,
  :Kn4 =>  set_norm_bm!,
  :Kn5 =>  set_norm_bm!,
  :Kn6 =>  set_norm_bm!,
  :Kn7 =>  set_norm_bm!,
  :Kn8 =>  set_norm_bm!,
  :Kn9 =>  set_norm_bm!,
  :Kn10 => set_norm_bm!,
  :Kn11 => set_norm_bm!,
  :Kn12 => set_norm_bm!,
  :Kn13 => set_norm_bm!,
  :Kn14 => set_norm_bm!,
  :Kn15 => set_norm_bm!,
  :Kn16 => set_norm_bm!,
  :Kn17 => set_norm_bm!,
  :Kn18 => set_norm_bm!,
  :Kn19 => set_norm_bm!,
  :Kn20 => set_norm_bm!,
  :Kn21 => set_norm_bm!,
)

# Maybe we can do some trickery with FunctionWrappers
# but that will require us to know the return type...

# This solution is MUCH faster than AL
# AND no bookkeeper :)

# These are virtual parameters, which do NOT exist 
# for lone BMultipole structs, only those within LineElements
const BMULTIPOLE_VIRTUAL_MAP = Dict{Symbol,Symbol}(
:Kn0 =>  :Bn0 ,
:Kn1 =>  :Bn1 ,
:Kn2 =>  :Bn2 ,
:Kn3 =>  :Bn3 ,
:Kn4 =>  :Bn4 ,
:Kn5 =>  :Bn5 ,
:Kn6 =>  :Bn6 ,
:Kn7 =>  :Bn7 ,
:Kn8 =>  :Bn8 ,
:Kn9 =>  :Bn9 ,
:Kn10 => :Bn10,
:Kn11 => :Bn11,
:Kn12 => :Bn12,
:Kn13 => :Bn13,
:Kn14 => :Bn14,
:Kn15 => :Bn15,
:Kn16 => :Bn16,
:Kn17 => :Bn17,
:Kn18 => :Bn18,
:Kn19 => :Bn19,
:Kn20 => :Bn20,
:Kn21 => :Bn21,
)