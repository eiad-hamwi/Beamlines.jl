#=

Defines the BitsBeamline type, which is a compressed, 
immutable, isbits-type structure-of-arrays version of 
a Beamline.


Two routines are defined:

bitsbltype -- Determines the type parameters of the 
BitsBeamline given a Beamline.

tobits -- Constructs an isbits representation of 
a Beamline. 

=#
struct BitsBeamline{T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12,T13,T14,T15,T16}
  tracking_method::T1         # If Nothing, then SciBmadStandard, else some array of UInt8
  tracking_method_extras::T2  
  repeat_next_n_eles::T3
  n_repeat::T4
  L::T5

  order::T6      # Each element is a SVector of the orders
  strength::T7   # Each element is a SVector of the strengths
  tiltm::T8      # Each element is a SVector of the tilts

  g::T9
  e1::T10
  e2::T11

  x_offset::T12
  y_offset::T13
  x_rot::T14
  y_rot::T15
  tilt::T16
end

function bitsbltype(bl::Beamline, arr::Type{T}=SVector{length(bl.line)}) where {T}
  # Default values:
  # Note these are the ELTYPES of these corresponding fields in BitsBeamline:
  tracking_method        = Nothing       # SciBmadStandard
  tracking_method_extras = typeof(SA[])
  repeat_next_n_eles     = Nothing
  n_repeat               = Nothing
  L                      = Float16
  order                  = Nothing
  strength               = Nothing
  tiltm                  = Nothing            
  g                      = Nothing
  e1                     = Nothing
  e2                     = Nothing
  x_offset               = Nothing
  y_offset               = Nothing
  x_rot                  = Nothing
  y_rot                  = Nothing
  tilt                   = Nothing

  for i in 1:length(bl.line)
    ele = bl.line[i]

    ele_tme = get_tracking_method_extras(ele.tracking_method)
    if length(ele_tme) > length(tracking_method_extras)
      tracking_method_extras = similar_type(tracking_method_extras, Size(ele_tme))
    end
    tracking_method_extras = similar_type(tracking_method_extras, promote_type(eltype(ele_tme), eltype(tracking_method_extras)))
    
    L = promote_type(L,typeof(ele.L))

    bmp = ele.BMultipoleParams
    if !isnothing(bmp) && length(bmp) > 0 # then we do have a multipole 
      # First check the eltypes:
      if order != Nothing
        strength = similar_type(strength, promote_type(eltype(strength),eltype(bmp)))
        tiltm = tiltm == Nothing ? Nothing : similar_type(tiltm, promote_type(eltype(tiltm),eltype(bmp)))
      else
        order = SVector{length(bmp),Int8} # create orders, specifying there is a multipole. Alwys Int8
        strength = SVector{length(bmp),eltype(bmp)}
      end

      # Then check the lengths:
      if length(bmp) > length(order)
        order = similar_type(order, Size(length(bmp)))
        strength = similar_type(strength, Size(length(bmp)))
        tiltm = tiltm == Nothing ? Nothing : similar_type(tiltm, Size(length(bmp)))
      end
      # Now check the each multipole - we have to do this bc only 
      # unnormalized+integrated is stored in BitsBeamLine. Also need 
      # to add tiltm if one is found.
      for bm in values(bmp.bdict)
        # If tiltm found and does not exist, create it
        if bm.tilt != 0 && tiltm == Nothing
          tiltm = SVector{length(strength),eltype(bmp)}
        end

        if bm.normalized
          strength = similar_type(strength, promote_type(eltype(strength), typeof(ele.Brho_ref)))
        end
        if !bm.integrated
          strength = similar_type(strength, promote_type(eltype(strength), typeof(ele.L)))
        end
      end
    end


    bp = ele.BendParams
    if !isnothing(bp)
      t = DataType[g,e1,e2]
      i = 1
      for v in (bp.g,bp.e1,bp.e2)
        if v != 0 
          t[i] = t[i] == Nothing ? typeof(v) : promote_type(t[i], typeof(v))
        end
        i += 1
      end
      g = t[1]
      e1 = t[2]
      e2 = t[3]
    end

    ap = ele.AlignmentParams
    if !isnothing(ap)
      t = DataType[x_offset,y_offset,x_rot,y_rot,tilt]
      i = 1
      for v in (ap.x_offset,ap.y_offset,ap.x_rot,ap.y_rot,ap.tilt)
        if v != 0 
          t[i] = t[i] == Nothing ? typeof(v) : promote_type(t[i], typeof(v))
        end
        i += 1
      end
      x_offset = t[1]
      y_offset = t[2]
      x_rot = t[3]
      y_rot = t[4]
      tilt = t[5]
    end
  end
  make_arr(type) = type == Nothing ? Nothing : arr{type}
  return BitsBeamline{
    make_arr(tracking_method),
    make_arr(tracking_method_extras),
    make_arr(repeat_next_n_eles),
    make_arr(n_repeat),
    make_arr(L), 
    make_arr(order), 
    make_arr(strength),
    make_arr(tiltm),
    make_arr(g),
    make_arr(e1),
    make_arr(e2),
    make_arr(x_offset),
    make_arr(y_offset),
    make_arr(x_rot),
    make_arr(y_rot),
    make_arr(tilt),
  }
end


function tobits(bl::Beamline, ::Type{BBL}=bitsbltype(bl)) where {BBL}
  line = bl.line
  N_ele = length(line)
  ft = fieldtypes(BBL)
  # Construct and set default values:
  tracking_method       = ft[ 1] == Nothing ? nothing : (t = Vector{eltype(ft[ 1])}(undef, N_ele); t .= 0x0; t)
  tracking_method_extras= ft[ 2] == Nothing ? nothing : (t = Vector{eltype(ft[ 2])}(undef, N_ele); t .= zeros(eltype(t), N_ele); t)
  repeat_next_n_eles    = ft[ 3] == Nothing ? nothing : (t = Vector{eltype(ft[ 3])}(undef, N_ele); t .= nothing; t)
  n_repeat              = ft[ 4] == Nothing ? nothing : (t = Vector{eltype(ft[ 4])}(undef, N_ele); t .= nothing; t)
  L                     = ft[ 5] == Nothing ? nothing : (t = Vector{eltype(ft[ 5])}(undef, N_ele); t .= 0; t)
  order                 = ft[ 6] == Nothing ? nothing : (t = Vector{eltype(ft[ 6])}(undef, N_ele); t .= zeros(eltype(t), N_ele); t)
  strength              = ft[ 7] == Nothing ? nothing : (t = Vector{eltype(ft[ 7])}(undef, N_ele); t .= zeros(eltype(t), N_ele); t)
  tiltm                 = ft[ 8] == Nothing ? nothing : (t = Vector{eltype(ft[ 8])}(undef, N_ele); t .= zeros(eltype(t), N_ele); t)
  g                     = ft[ 9] == Nothing ? nothing : (t = Vector{eltype(ft[ 9])}(undef, N_ele); t .= 0; t)
  e1                    = ft[10] == Nothing ? nothing : (t = Vector{eltype(ft[10])}(undef, N_ele); t .= 0; t)
  e2                    = ft[11] == Nothing ? nothing : (t = Vector{eltype(ft[11])}(undef, N_ele); t .= 0; t)
  x_offset              = ft[12] == Nothing ? nothing : (t = Vector{eltype(ft[12])}(undef, N_ele); t .= 0; t)
  y_offset              = ft[13] == Nothing ? nothing : (t = Vector{eltype(ft[13])}(undef, N_ele); t .= 0; t)
  x_rot                 = ft[14] == Nothing ? nothing : (t = Vector{eltype(ft[14])}(undef, N_ele); t .= 0; t)
  y_rot                 = ft[15] == Nothing ? nothing : (t = Vector{eltype(ft[15])}(undef, N_ele); t .= 0; t)
  tilt                  = ft[16] == Nothing ? nothing : (t = Vector{eltype(ft[16])}(undef, N_ele); t .= 0; t)

  for i in 1:N_ele
    ele = line[i]
    if !isnothing(tracking_method)        tracking_method[i]        = TRACKING_METHOD_MAP[typeof(ele.tracking_method)] end
    if !isnothing(tracking_method_extras) tracking_method_extras[i] = get_promoted_tm_extras(eltype(ft[2]), ele.tracking_method) end
    #if !isnothing(repeat_next_n_eles)     repeat_next_n_eles[i]     = 
    #if !isnothing(n_repeat)               n_repeat[i]               =     
    if !isnothing(L)                      L[i]                      = ele.L  end
    
    if !isnothing(ele.BMultipoleParams)
      bmp = ele.BMultipoleParams
      orderi = -ones(eltype(ft[6]))
      strengthi = zeros(eltype(ft[7]))
      tiltmi = isnothing(tiltm) ? nothing : zeros(eltype(ft[8]))
      j = 1
      for (k,v) in bmp.bdict
        @reset orderi[j] = k
        @reset strengthi[j] = eltype(strengthi)(v.strength)
        if v.normalized
          @reset strengthi[j] *= eltype(strengthi)(ele.Brho_ref)
        end
        if !v.integrated
          @reset strengthi[j] *= eltype(strengthi)(ele.L)
        end
        if !isnothing(tiltm)
          @reset tiltmi[j] = eltype(tiltmi)(v.tilt)
        end
        j += 1
      end
      order[i] = orderi
      strength[i] = strengthi
      if !isnothing(tiltm) tiltm[i] = tiltmi end
    end

    if haskey(ele.pdict, BendParams)
      if !isnothing(g)  g[i]  = ele.g end
      if !isnothing(e1) e1[i] = ele.e1 end
      if !isnothing(e2) e2[i] = ele.e2 end
    end
    if haskey(ele.pdict, AlignmentParams)
      if !isnothing(x_offset) x_offset[i]  = ele.x_offset end
      if !isnothing(y_offset) y_offset[i] = ele.y_offset end
      if !isnothing(x_rot) x_rot[i] = ele.x_rot end
      if !isnothing(y_rot) y_rot[i] = ele.y_rot end
      if !isnothing(tilt) tilt[i] = ele.tilt end
    end
  end
  
  bitsline = BitsBeamline(
    !isnothing(tracking_method) ? SA[tracking_method...] : nothing,
    !isnothing(tracking_method_extras) ? SA[tracking_method_extras...] : nothing,
    !isnothing(repeat_next_n_eles) ? SA[repeat_next_n_eles...] : nothing,
    !isnothing(n_repeat) ? SA[n_repeat...] : nothing,
    !isnothing(L) ? SA[L...] : nothing,
    !isnothing(order) ? SA[order...] : nothing,
    !isnothing(strength) ? SA[strength...] : nothing,
    !isnothing(tiltm) ? SA[tiltm...] : nothing,
    !isnothing(g) ? SA[g...] : nothing,
    !isnothing(e1) ? SA[e1...] : nothing,
    !isnothing(e2) ? SA[e2...] : nothing,
    !isnothing(x_offset) ? SA[x_offset...] : nothing,
    !isnothing(y_offset) ? SA[y_offset...] : nothing,
    !isnothing(x_rot) ? SA[x_rot...] : nothing,
    !isnothing(y_rot) ? SA[y_rot...] : nothing,
    !isnothing(tilt) ? SA[tilt...] : nothing,
  )
  typeof(bitsline) == BBL || error("Something bad happened!")
  #=if sizeof(bitsline) > 65536
    @warn "This BitsBeamline is size $(sizeof(bitsline)), which is greater than the 65536 bytes allowed in constant memory on a CUDA GPU. Consider using Float32/Float16 for LineElement parameters, simplifying the beamline, or splitting it up into one size that fits in constant memory and the rest in global memory."
  end=#
  return bitsline
end

#= StaticArrays implementation:
function tobits(bl::Beamline, ::Type{BBL}=bitsbltype(bl)) where {BBL}
  line = bl.line
  ft = fieldtypes(BBL)
  tracking_method = StaticArrays.sacollect(ft[1], TRACKING_METHOD_MAP[typeof(line[i].tracking_method)] for i in 1:length(line))
  tracking_method_extras = ft[2] == Nothing ? nothing : StaticArrays.sacollect(ft[2],  get_promoted_tm_extras(ft[2], line[i].tracking_method) for i in 1:length(line))
  
  repeat_next_n_eles = ft[3]
  n_repeat = ft[4]
  
  L = StaticArrays.sacollect(ft[5], line[i].L for i in 1:length(line))

  order = StaticArrays.sacollect(ft[6], StaticArrays.sacollect(eltype(ft[6]), 
  begin
    o = -ones(eltype(ft[6]))
    bmp = line[i].BMultipoleParams
    if !isnothing(bmp)
      j = 1
      for k in keys(bmp.bdict)
        o = @set o[j] = Int8(k)
        j += 1
      end
    end
    o
  end for i in 1:length(line)))

  strength = StaticArrays.sacollect(ft[7], StaticArrays.sacollect(eltype(ft[7]), 
  begin
    strength = zeros(eltype(ft[7]))
    bmp = line[i].BMultipoleParams
    if !isnothing(bmp)
      j = 1
      for v in values(bmp.bdict)
        @reset strength[j] = eltype(strength)(v.strength)
        if v.normalized
          @reset strength[j] *= ele.Brho_ref
        end
        if !v.integrated
          @reset strength[j] *= ele.L
        end
        j += 1
      end
    end
    strength
  end for i in 1:length(line)))

  tiltm = StaticArrays.sacollect(ft[8], StaticArrays.sacollect(eltype(ft[8]), 
  begin
    tiltm = zeros(eltype(ft[8]))
    bmp = line[i].BMultipoleParams
    if !isnothing(bmp)
      j = 1
      for v in values(bmp.bdict)
        @reset tiltm[j] = eltype(tiltm)(v.tilt)
        j += 1
      end
    end
    tiltm
  end for i in 1:length(line)))

  g = ft[9] == Nothing ? nothing : StaticArrays.sacollect(ft[9], haskey(line[i].bdict, BendParams) ? line[i].g : 0 for i in 1:length(line))
  e1 = ft[10] == Nothing ? nothing : StaticArrays.sacollect(ft[10], haskey(line[i].bdict, BendParams) ? line[i].e1 : 0 for i in 1:length(line))
  e2 = ft[11] == Nothing ? nothing : StaticArrays.sacollect(ft[11], haskey(line[i].bdict, BendParams) ? line[i].e2 : 0 for i in 1:length(line))

  x_offset = ft[12] == Nothing ? nothing : StaticArrays.sacollect(ft[12], haskey(line[i].bdict, AlignmentParams) ? line[i].x_offset : 0 for i in 1:length(line))
  y_offset = ft[13] == Nothing ? nothing : StaticArrays.sacollect(ft[13], haskey(line[i].bdict, AlignmentParams) ? line[i].y_offset : 0 for i in 1:length(line))
  x_rot = ft[14] == Nothing ? nothing : StaticArrays.sacollect(ft[14], haskey(line[i].bdict, AlignmentParams) ? line[i].x_rot : 0 for i in 1:length(line))
  y_rot = ft[15] == Nothing ? nothing : StaticArrays.sacollect(ft[15], haskey(line[i].bdict, AlignmentParams) ? line[i].y_rot : 0 for i in 1:length(line))
  tilt = ft[16] == Nothing ? nothing : StaticArrays.sacollect(ft[16], haskey(line[i].bdict, AlignmentParams) ? line[i].tilt : 0 for i in 1:length(line))
  bitsline = BitsBeamline(
    tracking_method,
    tracking_method_extras,
    repeat_next_n_eles,
    n_repeat,
    L,
    order,
    strength,
    tiltm,
    g,
    e1,
    e2,
    x_offset,
    y_offset,
    x_rot,
    y_rot,
    tilt,
  )
  if sizeof(bitsline) > 65536
    @warn "This BitsBeamline is size $(sizeof(bitsline)), which is greater than the 65536 bytes allowed in constant memory on a CUDA GPU. Consider using Float32/Float16 for LineElement parameters, simplifying the beamline, or splitting it up into one size that fits in constant memory and the rest in global memory."
  end
  return bitsline
end
=#


#=
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
=#