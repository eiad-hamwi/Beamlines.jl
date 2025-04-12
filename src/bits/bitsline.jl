#=

Defines the BitsBeamline type: a compressed,
bytes representation of the lattice.

=#


struct MultipleTrackingMethods end
struct MultipleNumberTypes end

struct BitsBeamline{
  TM,          # Equal to MultipleTrackingMethods if elements use different tracking methods, else equal to universal tracking method
  TMI,
  TME,
  R,
  NR,
  N_ele,
  param_eltype,  # Equal to MultipleNumberTypes if parameters are of different number types, else the number type of all parameters
  N_bytes,
  BitsLineElementType
}
  tracking_method::TMI         
  tracking_method_extras::SVector{N_ele,TME}
  repeat_next_n_eles::R
  n_repeat::NR
  params::SVector{N_ele,NTuple{N_bytes,UInt8}}
end

function bitsbltype(bl::Beamline) #, arr::Type{T}=SVector{length(bl.line)}) where {T}
  # Default values:
  TM  = Nothing # Set by first element, then if any elements differ, set to MultipleTrackingMethods
  TMI = Nothing
  TME = SVector{0,Union{}}
  R   = Nothing
  NR  = Nothing
  N_ele = length(bl.line) # will put in repeat later
  param_eltype = Nothing # set by first parameter
  N_bytes = zeros(Int, N_ele)

  # These are the types of the structures in BitsLineElement:
  # They default to Nothing for similar behavior as LineElement
  UP = Nothing
  BM = Nothing
  BP = Nothing
  AP = Nothing

  N_parameters = zeros(Int, N_ele)
  for i in 1:length(bl.line)
    ele = bl.line[i]
    ele_tm = ele.tracking_method
    if TM == Nothing 
      if isbits(ele_tm)
        TM = ele_tm
      else
        TM = MultipleTrackingMethods
        TMI = SVector{N_ele,UInt8}
      end
    end

    if TM != ele_tm
      TM = MultipleTrackingMethods
      TMI = SVector{N_ele,UInt8}
    end

    ele_tme = get_tracking_method_extras(ele_tm)
    if length(ele_tme) > length(TME)
      TME = similar_type(TME, Size(ele_tme))
    end
    TME = similar_type(TME, promote_type(eltype(ele_tme), eltype(TME)))
    

    # Now onto the parameters
    ele_L = ele.L
    if param_eltype == Nothing
      param_eltype = typeof(ele_L)
    end
    if param_eltype != typeof(ele_L)
      param_eltype = MultipleNumberTypes
    end
    if UP == Nothing
      UP = BitsUniversalParams{typeof(ele_L)}
    else
      UP = BitsUniversalParams{promote_type(eltype(UP),typeof(ele_L))}
    end
    N_bytes[i] += sizeof(ele_L)
    N_parameters[i] += 1

    bmp = ele.BMultipoleParams
    if !isnothing(bmp) && length(bmp) > 0 # then we do have a multipole 
      # First check the eltypes:
      if BM == Nothing
        BM = BitsBMultipoleParams{0,eltype(bmp)}
      end

      if length(BM) < length(bmp)
        BM = BitsBMultipoleParams{length(bmp),eltype(BM)}
      end

      if eltype(BM) != promote_type(eltype(BM),eltype(bmp))
        BM = BitsBMultipoleParams{length(BM),eltype(bmp)}
      end
      # Now check each multipole - we have to do this bc only 
      # unnormalized+integrated is stored in BitsBeamLine, which 
      # can cause a promotion for param_eltype if Brho_ref doesn't agree
      # and also a promotion for the eltype of BitsBMultipole
      for bm in values(bmp.bdict)
        if bm.tilt != 0 # only store tilts when nonzero
          N_bytes[i] += sizeof(eltype(bmp)) 
          N_parameters[i] += 1
          if param_eltype != eltype(bmp)
            param_eltype = MultipleNumberTypes
          end
        end

        bits_strength_type = eltype(bmp)
        
        if bm.strength != 0 # also only store strengths when nonzero
          if bm.normalized
            bits_strength_type = promote_type(bits_strength_type, typeof(ele.Brho_ref))
          end
          if !bm.integrated
            bits_strength_type = promote_type(bits_strength_type, typeof(ele_L))
          end
          N_bytes[i] += sizeof(bits_strength_type)
          N_parameters[i] += 1
          if param_eltype != bits_strength_type
            param_eltype = MultipleNumberTypes
          end
          BM = BitsBMultipoleParams{length(BM),promote_type(eltype(BM),bits_strength_type)}
        end
      end      
    end


    bp = ele.BendParams
    if !isnothing(bp)
      if BP == Nothing
        BP = BitsBendParams{eltype(bp)}
      end
      for v in (bp.g,bp.e1,bp.e2)
        if v != 0 
          N_bytes[i] += sizeof(v)
          N_parameters[i] += 1
          if param_eltype != typeof(v)
            param_eltype = MultipleNumberTypes
          end
          BP = BitsBendParams{promote_type(eltype(BP),typeof(v))}
        end
      end
    end

    ap = ele.AlignmentParams
    if !isnothing(ap)
      if AP == Nothing
        AP = BitsAlignmentParams{eltype(ap)}
      end
      for v in (ap.x_offset,ap.y_offset,ap.x_rot,ap.y_rot,ap.tilt)
        if v != 0 
          N_bytes[i] += sizeof(v)
          N_parameters[i] += 1
          if param_eltype != typeof(v)
            param_eltype = MultipleNumberTypes
          end
          AP = BitsAlignmentParams{promote_type(eltype(AP),typeof(v))}
        end
      end
    end
  end

  bl_N_bytes = maximum(N_bytes)

  # Every parameter now needs at least 1 byte to say what it is

  # If this is true, then we need to add a byte next to each
  # parameter stored in the array specifying how big next number is 
  # however for certain elements we may already have the space to 
  # add this number, so we should only add bytes if at least one 
  # element requires more
  scl = 1
  if param_eltype == MultipleNumberTypes
    scl = 2
  end

  i = 1
  while i < N_ele
    if bl_N_bytes - N_bytes[i] - scl*N_parameters[i] < 0
      bl_N_bytes += 1
      i -= 1
    end
    i += 1
  end

  #return BitsBeamline{TM,SVector{N_ele,TMI},TME,SVector{N_ele,R},SVector{N_ele,NR},N_ele,param_eltype,N_bytes,BitsLineElement{UP,BM,BP,AP}}
  #return BitsBeamline{TM,UInt8,TME,UInt8,UInt8,N_ele,param_eltype,N_bytes,BitsLineElement{UP,BM,BP,AP}}
  return BitsBeamline{TM,TMI,TME,R,NR,N_ele,param_eltype,bl_N_bytes,BitsLineElement{UP,BM,BP,AP}}
end

