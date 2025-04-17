#=

A generic interface for tracking routines to satisfy in 
order to have compatibility with the BitsBeamline.

=#
struct SciBmadStandard end
get_tracking_method_extras(::SciBmadStandard) = SA[]

const TRACKING_METHOD_MAP = Dict{DataType, UInt8}(SciBmadStandard=>0x0)
#const TRACKING_METHOD_INVERSE_MAP = Dict(value => key for (key, value) in TRACKING_METHOD_MAP)

# A bits-compatible tracking methods should implement:
#=
struct Linear end
function __init__()
  Beamlines.TRACKING_METHOD_MAP[Linear] = 0x1
end
Beamlines.get_tracking_method_extras(::Linear) = SA[]
=# 
# The extras are a StaticArray of the extra numbers
# More complicated example:
#=
struct MatrixKick{T} n_steps::T end
const MatrixKick8  = MatrixKick{UInt8}   # max 255 steps per element
const MatrixKick16 = MatrixKick{UInt16}  # max 65535 steps per element
const MatrixKick32 = MatrixKick{UInt32}  # max 4294967295 steps per element
function __init__()
  Beamlines.TRACKING_METHOD_MAP[MatrixKick8]  = 0x2
  Beamlines.TRACKING_METHOD_MAP[MatrixKick16] = 0x3
  Beamlines.TRACKING_METHOD_MAP[MatrixKick32] = 0x4
end
Beamlines.get_tracking_method_extras(m::MatrixKick) = SA[m.n_steps]

# another option with auto step size computation per element
struct MatrixKickAuto end
function __init__()
  Beamlines.TRACKING_METHOD_MAP[MatrixKickAuto] = 0x5
end
Beamlines.get_tracking_method_extras(::MatrixKickAuto) = SA[] # no extras, which is good

# you should also be able to create the trackking method instance with TrackingMethod(get_tracking_method_extras(::TrackingMethod)...)
=# 

# If I have Linear and MatrixKick{T} in the same lattice, then 
# linear will now contain SA[T(0)] (promotion handled internally 
# by get_promoted_tm_extras. This is the requirement for tracking methods. 
# note that the size in bytes of the extras should be minimized, ideally 0
# we need to fit this whole lattice in constant memory on a GPU.
get_tracking_method_extras(::Any) = error("Please implement Beamlines.get_tracking_method_extras for this tracking method.")

function get_promoted_tm_extras(::Type{TME}, tracking_method) where {TME}
  tme = get_tracking_method_extras(tracking_method) # implemented by tracking method
  if length(tme) > length(TME) || promote_type(eltype(TME),eltype(tme)) != eltype(TME)
    error("Cannot promote tracking method extra $tme to $TME")
  end
  tme_out = zero(TME)
  for i in 1:length(tme)
    tme_out = @set tme_out[i] = tme[i]
  end
  return tme_out
end
