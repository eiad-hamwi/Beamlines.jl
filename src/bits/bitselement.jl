#=
struct BitsLineElement{
  UP<:Union{BitsUniversalParams,Nothing},
  BM<:Union{BitsBMultipoleParams,Nothing},
  BP<:Union{BitsBendParams,Nothing},
  AP<:Union{BitsAlignmentParams,Nothing},
}
  UniversalParams::UP
  BMultipoleParams::BM
  BendParams::BP
  AlignmentParams::AP
end
=#

@inline function readval(i, arr, T)
  i += 1
  s = sizeof(T)
  slice = ntuple(i->0xff, sizeof(T))
  for j in 1:length(slice)
    @reset slice[j] = arr[i+j-1]
  end
  val = reinterpret(T, slice)
  i += s
  return i, val
end

@inline tilt_id_to_order(id) = Int8(id-1)
@inline strength_id_to_order(id) = Int8(id-23)


function BitsLineElement(bbl::BitsBeamline, idx::Integer=1)
  TM,TMI,TME,DS,R,N_ele,N_bytes,UP,BM,BP,AP = unpack_type_params(bbl)
  if DS == Sparse
    error("Sparse BitsBeamline not implemented yet!")
  end

  params::NTuple{N_bytes,UInt8} = bbl.params[idx] # Byte array we now need to process
  up::UP = UP()
  bmp::BM = BM()
  bp::BP  = BP()
  ap::AP = AP()
 
  i = 1
  bm_count = 0
  while i <= length(params) && params[i] != 0xff
    if params[i] == 0x0 # Length!
      i, L = readval(i, params, eltype(UP))
      @reset up.L = L
    end

    
    if i <= length(params) && params[i] > 0x0 && params[i] < UInt8(45) # then we have some kinda multipole business going on
      orders::SVector{length(BM),Int8} = bmp.bdict.keys
      bms = bmp.bdict.vals
      id = params[i]
      i, v = readval(i, params, eltype(BM))
      if id < UInt8(23) # tilt
        order = tilt_id_to_order(id)
        if !(order in orders)
          @reset orders[bm_count+1] = order::Int8
          bm_count += 1
        end
        bm_idx = -1
        for j in 1:length(orders)
          if orders[j] == order
            bm_idx = j
            break
          end
        end
        strength::eltype(BM) = bms[bm_idx].strength
        if isnan(strength)
          strength = zero(eltype(BM))
        end
        @reset bms[bm_idx] = BitsBMultipole{eltype(BM),isnormalized(BM)}(strength,v,order)
      end

      if id >= UInt8(23) # strength
        order = strength_id_to_order(id)
        if !(order in orders)
          @reset orders[bm_count+1] = order::Int8
          bm_count += 1
        end
        bm_idx = -1
        for j in 1:length(orders)
          if orders[j] == order
            bm_idx = j
            break
          end
        end
        tilt::eltype(BM) = bms[bm_idx].tilt
        if isnan(tilt)
          tilt = zero(eltype(BM))
        end
        @reset bms[bm_idx] = BitsBMultipole{eltype(BM),isnormalized(BM)}(v,tilt,order)
      end

      @reset bmp = BM(BitsBMultipoleDict{eltype(BM),length(BM),isnormalized(BM)}(orders, bms))
    end

    if i <= length(params) && params[i] >= UInt8(45)  && params[i] < UInt8(48) # bendparams!
      id = params[i]
      if isnan(bp.g)
        @reset bp.g = zero(eltype(BP))
        @reset bp.e1 = zero(eltype(BP))
        @reset bp.e2 = zero(eltype(BP))
      end

      i, v = readval(i, params, eltype(BP))
      if id == UInt8(45)
        @reset bp.g = v
      elseif id == UInt8(46)
        @reset bp.e1 = v
      else
        @reset bp.e2 = v
      end
    end

    if i <= length(params) && params[i] >= UInt8(48)  && params[i] < UInt8(54) # alignmentparams
      id = params[i]
      if isnan(ap.x_offset)
        @reset ap.x_offset = zero(eltype(AP))
        @reset ap.y_offset = zero(eltype(AP))
        @reset ap.z_offset = zero(eltype(AP))
        @reset ap.x_rot = zero(eltype(AP))
        @reset ap.y_rot = zero(eltype(AP))
        @reset ap.tilt = zero(eltype(AP))
      end

      i, v = readval(i, params, eltype(AP))
      if id == UInt8(48)
        @reset ap.x_offset = v
      elseif id == UInt8(49)
        @reset ap.y_offset = v
      elseif id == UInt8(50)
        @reset ap.z_offset = v
      elseif id == UInt8(51)
        @reset ap.x_rot = v
      elseif id == UInt8(52)
        @reset ap.y_rot = v
      else
        @reset ap.tilt = v
      end
    end
  end

  return BitsLineElement(up,bmp,bp,ap)
end
