using Revise, Beamlines, GTPSA, BenchmarkTools

function make_fodo(K1=0.40, L_quad=0.5, L_drift=5.0)
  qf = Quadrupole(K1=K1, L=L_quad, tracking_method=Linear())
  d1 = Drift(L=L_drift, tracking_method=Linear())
  qd = Quadrupole(K1=-qf.K1, L=L_quad, tracking_method=Linear())
  d2 = Drift(L=L_drift, tracking_method=Linear())
  return [qf, d1, qd, d2]
end

K1 = 0.40
L_quad = 0.5
L_drift = 5.0
N_fodo = 1000

bl = Beamline([ele for i in 1:N_fodo for ele in make_fodo(K1,L_quad,L_drift)]; Brho_ref=60.0)

N_particle = 100000

bunch_soa = Bunch(N_particle, mem=Beamlines.SoA)
bunch_soa_out = deepcopy(bunch_soa)
tmp = deepcopy(bunch_soa)
@btime track!($bunch_soa_out, $bl, $bunch_soa; work=tmp)

bunch_aos = Bunch(N_particle, mem=Beamlines.AoS)
@btime track!($bunch_aos, $bl)


# We can get another x2 for SoA by using 32-bit floats:
bunch_soa =Bunch{Beamlines.SoA}(Beamlines.ELECTRON, 60.0, rand(Float32, N_particle, 4))
@btime track!($bunch_soa, $bl)

# AoS is basically unchanged
bunch_aos =Bunch{Beamlines.AoS}(Beamlines.ELECTRON, 60.0, rand(Float32, 4, N_particle))
@btime track!($bunch_aos, $bl)
