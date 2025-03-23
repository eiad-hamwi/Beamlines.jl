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

# Maybe we can do some trickery with FunctionWrappers
# but that will require us to know the return type...

# This solution is MUCH faster than AL
# AND no bookkeeper :)