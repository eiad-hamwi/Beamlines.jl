struct BitsLineElement{S,T,A,B,C}
  tracking_method::UInt
  L::S
  Brho_ref::T
  BMultipoleParams::A
  BendParams::B
  AlignmentParams::C
end

function Base.getproperty(b::BitsLineElement, key::Symbol)
  field = getfield(b, key)
  if key == :Brho_ref && isnan(field)
    error("Unable to get magnetic rigidity: Brho_ref of the BitsLineElement has not been set.")
  end
  return field
end

function tobits(bl::Beamline, ::Type{T}=bitseltype(bl)) where {T}
  bitsline = Vector{T}(undef, length(bl.line))
  for i in 1:length(bl.line)
    @inbounds bitsline[i] = T(bl.line[i])
  end
  return bitsline
end

function BitsLineElement{S,T,A,B,C}(ele::LineElement) where {S,T,A,B,C}
  tracking_method = objectid(ele.tracking_method)::UInt
  L = convert(S, ele.L)::S
  Brho_ref = convert(T, getfield(ele.BeamlineParams.beamline, :Brho_ref))::T
  bmultipoleparams = convert(A, ele.BMultipoleParams)::A
  bendparams = convert(B, ele.BendParams)::B
  alignmentparams = convert(C, ele.AlignmentParams)::C
  return BitsLineElement{S,T,A,B,C}(tracking_method, L, Brho_ref, bmultipoleparams, bendparams, alignmentparams)
end

# First pass to get the BitsLineElement type
# This should only be done ONCE ever for a beamline, even if updates occur
function bitseltype(bl::Beamline)
  S = Float16
  T = typeof(getfield(bl, :Brho_ref))
  A = Nothing
  B = Nothing
  C = Nothing
  for ele in bl.line
    S = promote_type(typeof(ele.L),S)

    a = ele.BMultipoleParams
    if !isnothing(a)
      if A == Nothing
        T = eltype(a)
        N = length(a)
      else
        T = promote_type(eltype(a),eltype(A))
        N = length(a) > length(A) ? length(a) : length(A)
      end
      A = BitsBMultipoleParams{N,T}
    end

    b = ele.BendParams
    if !isnothing(b)
      if B == Nothing
        T = eltype(b)
      else
        T = promote_type(eltype(b),eltype(B))
      end
      B = BitsBendParams{T}
    end

    c = ele.AlignmentParams
    if !isnothing(c)
      if C == Nothing
        T = eltype(c)
      else
        T = promote_type(eltype(c),eltype(C))
      end
      C = BitsAlignmentParams{T}
    end
  end

  return BitsLineElement{S,T,A,B,C}
end