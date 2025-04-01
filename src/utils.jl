# Functions for float by Dan Abell.
# Modified by Matt to handle eps for different float types.
# Modified by matt to use ifelse.

@inline sincu(z) = ifelse(abs(z) < sqrt(2*eps(z)), one(z), sin(z)/z)
@inline sinhcu(z) = ifelse(abs(z) < sqrt(2*eps(z)), one(z), sinh(z)/z)

