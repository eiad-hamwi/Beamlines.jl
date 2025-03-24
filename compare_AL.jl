using BenchmarkTools
import Beamlines as BL
using AcceleratorLattice
# note that doing import AcceleratorLattice as AL
# and then using AL.@eles gives garbage, and it will let you do it.

# Beamlines ===========================
BL.default_E_ref = 18e9 # 18 GeV
qf = BL.Quadrupole(K1=0.36, L=0.5)
sf = BL.Sextupole(K2=0.1, L=0.5)
d1 = BL.Drift(L=1.0)
qd = BL.Quadrupole(K1=-qf.K1, L=0.5)
sd = BL.Sextupole(K2=-sf.K2, L=0.5)
d2 = BL.Drift(L=1.0)

bl = BL.Beamline([qf, sf, d1, qd, sd, d2])

# Get:
@btime $(qf).B1
#= Output:
49.638 ns (1 allocation: 16 bytes)
21.61495336884025
=# 

# Set:
@btime $(qf).B1 = $60
#= Output:
  111.983 ns (2 allocations: 32 bytes)
60
=#

@btime $(qf).K1 = $60
#= Output:
247.472 ns (9 allocations: 144 bytes)
60
=# # Slightly slower because E_ref is polymorphic! This is not the case in AL

@btime $(d2).s
#= Output:
379.353 ns (9 allocations: 144 bytes)
3.0
=#

# ======================================

# AcceleratorLattice ===================
@eles begin
  begin0 = BeginningEle(pc_ref = 1e7, species_ref = Species("electron"))
  qf = Quadrupole(Kn1=0.36, L=0.5)
  sf = Sextupole(Kn2=0.1, L=0.5)
  d1 = Drift(L=1.0)
  qd = Quadrupole(Kn1=-qf.Kn1, L=0.5)
  sd = Sextupole(Kn2=-sf.Kn2, L=0.5)
  d2 = Drift(L=1.0)
end

bl = BeamLine([begin0, qf, sf, d1, qd, sd, d2])
lat = Lattice([bl])

@btime $(qf).Bn1
#= Output:
  2.264 μs (57 allocations: 2.27 KiB)
0.0
=# # Much slower, and incorrect!

@btime $(qf).Bn1 = $60
#= Output:
  3.771 μs (85 allocations: 3.32 KiB)
60
=#

@btime $(qf).Kn1 = $60
#= Output:
  3.693 μs (85 allocations: 3.34 KiB)
60
=#

@btime $(d2).s  
#= Output:  
  572.973 ns (11 allocations: 328 bytes)
0.0
=# # Slower and incorrect!

# ======================================
