calc_Brho(E_ref) = @FastGTPSA E_ref/C_LIGHT*sqrt(1-(M_ELECTRON/E_ref)^2)

namedtuple(d::Dict) = NamedTuple{(keys(d)...,)}((values(d)...,))

# Functions for float by Dan Abell.
# Modified by Matt to handle eps for different float types.

function sincu(z)
  threshold = sqrt(2*eps(z))
  if abs(z) < threshold
    return 1.
  else
    return sin(z) / z
  end
end

function sinhcu(z)
  threshold = sqrt(2*eps(z))
  if abs(z) < threshold
    return 1.
  else
    return sinh(z) / z
  end
end

const Q = 1.602176634e-19 # C
const C_LIGHT = 2.99792458e8 # m/s
const M_ELECTRON = 0.51099895069 # eV/c^2
