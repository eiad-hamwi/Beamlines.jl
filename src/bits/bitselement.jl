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
