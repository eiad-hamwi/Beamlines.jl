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

function BitsLineElement(bbl::BitsBeamline, idx::Integer=1)
  TM,TMI,TME,DS,R,N_ele,param_eltype,N_bytes,UP,BM,BP,AP = unpack_type_params(bbl)
  if DS == Sparse
    error("Sparse BitsBeamline not implemented yet!")
  end

  params = bbl.params[idx] # Byte array we now need to process
  up = UP()
  bmp = BM()
  bp  = BP()
  ap = AP()

  function readval(i, arr, )
    i += 1
    if param_eltype == MultipleNumberTypes
      s = arr[i] # Number of bytes to read next!
      i += 1
    else
      s = sizeof(param_eltype)
    end
    val = reinterpret(arr[i:])
  end


  i = 1
  while params[i] != 0xff
    if params[i] == 0x0 # Length!
      @reset up.L = reinterpret
    end
      
  end


end
