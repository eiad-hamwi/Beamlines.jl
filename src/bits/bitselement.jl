const TRACKING_METHOD_MAP = Dict{DataType, UInt8}()
# A bits-compatible tracking methods should implement:
#=
struct Linear end
function __init__()
  Beamlines.TRACKING_METHOD_MAP[Linear] = 0x1
end
Beamlines.tracking_method_extras(::Linear) = SA[]
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
Beamlines.tracking_method_extras(m::MatrixKick) = SA[m.n_steps]

# another option with auto step size computation per element
struct MatrixKickAuto end
function __init__()
  Beamlines.TRACKING_METHOD_MAP[MatrixKickAuto] = 0x5
end
Beamlines.tracking_method_extras(::MatrixKickAuto) = SA[] # no extras, which is good

=# 

# If I have Linear and MatrixKick{T} in the same lattice, then 
# linear will now contain SA[T(0)] (promotion handled internally 
# by get_promoted_tm_extras. This is the requirement for tracking methods. 
# note that the size in bytes of the extras should be minimized, ideally 0
# we need to fit this whole lattice in constant memory on a GPU.
tracking_method_extras(::Any) = error("Please implement Beamlines.tracking_method_extras for this tracking method.")


struct BitsLineElement{TME<:SVector,S,BM,BP,AP}
  tracking_method::UInt8
  tracking_method_extras::TME
  L::S
  BMultipoleParams::BM
  BendParams::BP
  AlignmentParams::AP
end

function tobits(bl::Beamline, ::Type{BLE}=bitseltype(bl)) where {BLE}
  bitsline = Vector{BLE}(undef, length(bl.line))
  for i in 1:length(bl.line)
    @inbounds bitsline[i] = BLE(bl.line[i])
  end
  if sizeof(bitsline) > 65536
    @warn "This bits-beamline is size $(sizeof(bitsline)), which is greater than the 65536 bytes allowed in constant memory on a CUDA GPU. Consider simplifying the beamline or splitting it up into one size that fits in constant memory and the rest in global memory."
  end
  return bitsline
end

function get_promoted_tm_extras(::Type{TME}, tracking_method) where {TME}
  tme = tracking_method_extras(tracking_method) # implemented by tracking method
  if length(tme) > length(TME) || promote_type(eltype(TME),eltype(tme)) != eltype(TME)
    error("Cannot promote tracking method extra $tme to $TME")
  end
  tme_out = zero(TME)
  for i in 1:length(tme)
    tme_out = @set tme_out[i] = tme[i]
  end
  return tme_out
end

function BitsLineElement{TME,S,BM,BP,AP}(ele::LineElement) where {TME,S,BM,BP,AP}
  tracking_method = TRACKING_METHOD_MAP[typeof(ele.tracking_method)]
  tracking_method_extras = get_promoted_tm_extras(TME, ele.tracking_method)::TME
  L = S(ele.L)::S
  bmultipoleparams = BM == Nothing ? nothing : BM(ele.BMultipoleParams, L, isnan(ele.Brho_ref) ? nothing : ele.Brho_ref)::BM
  bendparams = BP == Nothing ? nothing : BP(ele.BendParams)::BP
  alignmentparams = AP == Nothing ? nothing : AP(ele.AlignmentParams)::AP
  return BitsLineElement{TME,S,BM,BP,AP}(tracking_method, tracking_method_extras, L, bmultipoleparams, bendparams, alignmentparams)
end

# First pass to get the BitsLineElement type
# This should only be done ONCE ever for a beamline, even if updates occur
function bitseltype(bl::Beamline)
  brho_reft = typeof(bl.Brho_ref)
  TME = typeof(SA[]) 
  S = Float16
  BM = Nothing
  BP = Nothing
  AP = Nothing
  for ele in bl.line
    S = promote_type(typeof(ele.L),S)

    bmp = ele.BMultipoleParams
    if !isnothing(bmp)
      bmpt = eltype(bmp)
      # note that BitsBMultipole only stores integrated, unnormalized
      # therefore is any of the multipoles are not integrated or normalized,
      # then we multiply it by L and/or Brho_ref respectively, promoting the type 
      # of the BitsBMultipole
      for bm in values(bmp.bdict)
        if bm.normalized
          bmpt = promote_type(bmpt, brho_reft)
        end
        if !bm.integrated
          bmpt = promote_type(bmpt, S)
        end
      end
      if BM == Nothing
        T = bmpt
        N = length(bmp)
      else
        T = promote_type(bmpt,eltype(BM))
        N = length(bmp) > length(BM) ? length(bmp) : length(BM)
      end
      BM = BitsBMultipoleParams{N,T}
    end

    bp = ele.BendParams
    if !isnothing(bp)
      if BP == Nothing
        T = eltype(bp)
      else
        T = promote_type(eltype(bp),eltype(BP))
      end
      BP = BitsBendParams{T}
    end

    ap = ele.AlignmentParams
    if !isnothing(ap)
      if AP == Nothing
        T = eltype(ap)
      else
        T = promote_type(eltype(ap),eltype(AP))
      end
      AP = BitsAlignmentParams{T}
    end
  end

  return BitsLineElement{TME,S,BM,BP,AP}
end