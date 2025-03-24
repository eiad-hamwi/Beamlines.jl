@kwdef mutable struct BendParams{T<:Number} <: AbstractParams
  B_bend::T = 0.0 # Actual field strength in Tesla
  g::T      = 0.0 # Coordinate system curvature
  e1::T     = 0.0 # Edge 1 angle as SBend from g_ref (e.g. e1 = 0.0 for SBend)
  e2::T     = 0.0 # Edge 2 angle as SBend from g_ref (e.g. e2 = 0.0 for SBend)
  function BendParams(B_bend, g, e1, e2)
    return new{promote_type(typeof(B_bend),typeof(g),typeof(e1),typeof(e2))}(B_bend, g, e1, e2)
  end
end

# Note that here the reference energy is really needed to compute anything
# other than the above so there is no more work to do here. Must define 
# virtual properties for the rest of them.
