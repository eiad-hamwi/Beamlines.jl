using Beamlines, BenchmarkTools, GTPSA

# This only needs to be specified if we input normalized field strengths
Beamlines.default_E_ref = 18e9 # 18 GeV

qf = Quadrupole(Kn1=0.36, L=0.5)
sf = Sextupole(Kn2=0.1, L=0.5)
d1 = Drift(L=1.0)
qd = Quadrupole(Kn1=-qf.Kn1, L=0.5)
sd = Sextupole(Kn2=-sf.Kn2, L=0.5)
d2 = Drift(L=1.0)

# Up to 21st order multipoles allowed:
m21 = Multipole(Kn21=5.0, L=6)

# We can access quantities like:
qf.L
qf.Bn1 # B field in Tesla

# We can also reset quantities:
qf.Bn1 = 60
qf.Kn1 = 0.36

struct MyTrackingMethod end
qf.tracking_method = MyTrackingMethod()
# EVERYTHING is a deferred expression, there is no bookkeeper

# Create a FODO beamline
bl = Beamline([qf, sf, d1, qd, sd, d2])

# Easily get s, and s_downstream, as deferred expression:
qd.s
qd.s_downstream

# And of course, EVERYTHING is fully polymorphic for differentiability.
# Let's make the length of the first drift a TPSA variable:
const D = Descriptor(1,1)
ΔL = @vars(D)[1]

d1.L += ΔL

# Now we can see that s and s_downstream are also TPSA variables:
qd.s
qd.s_downstream

