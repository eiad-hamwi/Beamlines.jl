const Q = 1.602176634e-19 # C
const C_LIGHT = 2.99792458e8 # m/s
const M_ELECTRON = 0.51099895069 # eV/c^2
const M_PROTON = 9.3827208943e8 # eV/c^2

struct Species
  name::String
  mass::Float64   # in eV/c^2
  charge::Float64 # in Coulomb
end

const ELECTRON = Species("electron", M_ELECTRON,-Q)
const POSITRON = Species("positron", M_ELECTRON,Q)

const PROTON = Species("proton", M_PROTON,Q)
const ANTIPROTON = Species("antiproton", M_PROTON,-Q)

calc_Brho(species::Species, E) = @FastGTPSA sqrt(E^2-species.mass^2)/C_LIGHT
calc_E(species::Species, Brho) = @FastGTPSA sqrt((Brho*C_LIGHT)^2 + species.mass^2)
calc_gamma(species::Species, Brho) = @FastGTPSA sqrt((Brho*C_LIGHT/species.mass)^2+1)

# sincu/sinhcu functions for float by Dan Abell.
# Modified by Matt to handle eps for different float types.
# Modified by matt to use ifelse.

@inline sincu(z) = ifelse(abs(z) < sqrt(2*eps(z)), one(z), sin(z)/z)
@inline sinhcu(z) = ifelse(abs(z) < sqrt(2*eps(z)), one(z), sinh(z)/z)

