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
    Brho = ele.Brho
  else
    !isnan(Beamlines.default_E_ref) || error("LineElement not in a Beamline: please set Beamlines.default_E_ref to calculate normalized field strengths")
    Brho = calc_Brho(Beamlines.default_E_ref)
  end
  return @noinline _get_norm_bm(bp, Brho, key)
end

function _get_norm_bm(bp, Brho, key)
  ord, sym = BMULTIPOLE_KEY_MAP[BMULTIPOLE_VIRTUAL_MAP[key]]
  Bk = getproperty(bp.bdict[ord], sym)
  return Bk/Brho
end

const VIRTUAL_GETTER_MAP = Dict{Symbol,Function}(
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
)

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
  return setproperty!(ele, key, Bk)
end

const VIRTUAL_SETTER_MAP = Dict{Symbol,Function}(
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
)

# Maybe we can do some trickery with FunctionWrappers
# but that will require us to Kow the return type...

# This solution is MUCH faster than AL
# AND no bookkeeper :)

# These are virtual parameters, which do NOT exist 
# for lone BMultipole structs, only those within LineElements
const BMULTIPOLE_VIRTUAL_MAP = Dict{Symbol,Symbol}(
:K0 =>  :B0 ,
:K1 =>  :B1 ,
:K2 =>  :B2 ,
:K3 =>  :B3 ,
:K4 =>  :B4 ,
:K5 =>  :B5 ,
:K6 =>  :B6 ,
:K7 =>  :B7 ,
:K8 =>  :B8 ,
:K9 =>  :B9 ,
:K10 => :B10,
:K11 => :B11,
:K12 => :B12,
:K13 => :B13,
:K14 => :B14,
:K15 => :B15,
:K16 => :B16,
:K17 => :B17,
:K18 => :B18,
:K19 => :B19,
:K20 => :B20,
:K21 => :B21,
)