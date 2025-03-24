using Beamlines, BenchmarkTools, GTPSA

# This only needs to be specified if we input normalized field strengths
Beamlines.default_E_ref = 18e9 # 18 GeV

qf = Quadrupole(K1=0.36, L=0.5)
sf = Sextupole(K2=0.1, L=0.5)
d1 = Drift(L=1.0)
qd = Quadrupole(K1=-qf.K1, L=0.5)
sd = Sextupole(K2=-sf.K2, L=0.5)
d2 = Drift(L=1.0)

# Up to 21st order multipoles allowed:
m21 = Multipole(K21=5.0, L=6)

# All of these are really just one type, LineElement
# E.g. literally,
# Quadrupole(; kwargs) = LineElement("Quadrupole"; kwargs...)
# Feel free to define your own element "classes":
bench = LineElement("Bench", L=25.0)

# We can access quantities like:
qf.L
qf.B1 # B field in Tesla

# We can also reset quantities:
qf.B1 = 60
qf.K1 = 0.36

struct MyTrackingMethod end
qf.tracking_method = MyTrackingMethod()
# EVERYTHING is a deferred expression, there is no bookkeeper

# Create a FODO beamline
bl = Beamline([qf, sf, d1, qd, sd, d2])

# Easily get s, and s_downstream, as deferred expression:
qd.s
qd.s_downstream

# We can get all Quadrupoles for example in the line with:
quads = findall(t->t.class == "Quadrupole", bl.line)

# Or just the focusing quadrupoles with:
f_quads = findall(t->t.class == "Quadrupole" && t.K1 > 0., bl.line)

# And of course, EVERYTHING is fully polymorphic for differentiability.
# Let's make the length of the first drift a TPSA variable:
const D = Descriptor(2,1)
ΔL = @vars(D)[1]

d1.L += ΔL

# Now we can see that s and s_downstream are also TPSA variables:
qd.s
qd.s_downstream

# Even the reference energy of the Beamline can be set as 
# a TPSA variable:
ΔE = @vars(D)[2]
bl.E_ref += ΔE

# Now e.g. normalized field strengths will be TPSA:
qd.K1


