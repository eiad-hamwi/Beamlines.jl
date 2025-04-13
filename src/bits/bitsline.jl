#=

Defines the BitsBeamline type: a compressed,
bytes representation of the lattice.

=#


struct MultipleTrackingMethods end
struct MultipleNumberTypes end
struct Dense end
struct Sparse end

struct BitsBeamline{
  TM,          # Equal to MultipleTrackingMethods if elements use different tracking methods, else equal to universal tracking method
  TMI,
  TME,
  D,
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
#=
i = 1
while i <= length(bl)
  repeat_count = bl.repeat[i]
  if repeat_count == 1
    track!(bunch, bl[i])
    i += 1
  else
    count = 0
    while count <= repeat_count
      j = i
      while bl.repeat[j] == 0 
        track!(bunch, bl[j])
      end
      count += 1
    end
  end
end
for i in 1:length(bl)
  count = 0
  while bl

  end
end
=#
function bitsbltype(bl::Beamline) #, arr::Type{T}=SVector{length(bl.line)}) where {T}
  # Default values:
  TM  = Nothing # Set by first element, then if any elements differ, set to MultipleTrackingMethods
  TMI = Nothing
  TME = SVector{0,Union{}}
  D = Dense
  R   = Nothing
  NR  = Nothing
  N_ele = length(bl.line)
  param_eltype = Nothing # set by first parameter
  N_bytes = zeros(Int, N_ele)

  # These are the types of the structures in BitsLineElement:
  # They default to Nothing for similar behavior as LineElement
  UP = Nothing
  BM = Nothing
  BP = Nothing
  AP = Nothing

  N_parameters = zeros(Int, N_ele)
  line_w_duplicates = Vector{LineElement}(undef, N_ele)

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

    # Now do the duplicates check
    j = 1   
    ele_to_add = ele
    while isassigned(line_w_duplicates, j)
      if line_w_duplicates[j] == ele
        ele_to_add = line_w_duplicates[j]
        break
      end
      j += 1
    end
    line_w_duplicates[i] = ele_to_add 
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

  # Now compress if there are repeats
  # We default to a Dense representation bc more cache friendly but 
  # if we go over 64KB we can attempt a Sparse representation
  # if that goes over too, then just use Dense bc cache friendly.

  idxs_w_duplicates = map(t->t.beamline_index, line_w_duplicates)
return idxs_w_duplicates
  return BitsBeamline{TM,TMI,TME,R,NR,N_ele,param_eltype,bl_N_bytes,BitsLineElement{UP,BM,BP,AP}}
end


function find_consecutive_repeats(arr)
  # go through the entire array checking for the smallest patterns
  # First check each pair and see if any consecutive repeats
  # then check each triplet
  # then quad
  # etc etc
  # Note that we do NOT nest, so once a repeated pair is found, 
  # we specify the repeat and the continue down the array, ignoring 
  # anything before
  #=

  Consider:
  [ 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15]
  [ 5, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 6,6,1,2,3,1,2,3,7,6]
i +3*4 + 1
  We need to know 1) number of elements in a repeat, and 2) how many times 
  to repeat it. The above example should return:

  [1, 3,0,0,0,  2,  2,0,0,  1, 1]

  The first number tells you how many times you should go through the 
  subsequent sequence of zeros inclusive of that element. 
  
  If 1, then no repeating (so all can be ones or zeros).
  =#
  n = length(arr)
  i = 1
  repeats = Int[]
  while i <= n
    found = false
    for eles_per_repeat in 1:floor(Int,(n-i)/2)
      cur_pattern = arr[i:i+eles_per_repeat-1]
      count = 1
      #println("Checking pattern $cur_pattern")
      #=if i+(count+1)eles_per_repeat-1 <= n
        println("does it equal $(arr[i+count*eles_per_repeat:i+(count+1)eles_per_repeat-1])")
      end=#
      while i+(count+1)eles_per_repeat-1 <= n && cur_pattern == arr[i+count*eles_per_repeat:i+(count+1)eles_per_repeat-1]
        count += 1
      end
      if count > 1 
        #println("we found one! $cur_pattern repeats $count times")
        # then we have a repeat starting at index i of eles_per_repeat 
        # lengths repeating count-1 times
        append!(repeats, [count, zeros(Int, eles_per_repeat-1)...])
        i += count*eles_per_repeat
        found = true
        break
      end
    end
    if !found
      push!(repeats, 1)
      i += 1
    end
  end
  return repeats
end
