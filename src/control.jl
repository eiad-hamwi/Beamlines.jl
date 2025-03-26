mutable struct Controller
  fcns::Dict{Tuple{Union{Controller,LineElement},Symbol},Function}
  vars::NamedTuple
  function Controller(pairs...; vars=(; x=0.0,))
    fcns = Dict(pairs...)
    return new(fcns, vars)
  end
end

function Base.setproperty!(c::Controller, key::Symbol, value)
  if !(key in (:fcns, :vars))
    c.vars = set(c.vars, opcompose(PropertyLens(key)), value)
    _run_controller(c, c.vars)
    return value
  else
    return setfield!(c, key, value)
  end
end

function Base.getproperty(c::Controller, key::Symbol)
  if !(key in (:fcns, :vars))
    return getfield(c.vars, key)
  else
    return getfield(c, key)
  end
end

# Functions must be of format f(ele; kwargs...)
# kwargs will be :var=>values

function set!(c::Controller; kwargs...)
  vars = c.vars # Unpack the vars (costly)
  # question: should I unpack all the 
  # Function barrier
  c.vars = _set!(c, vars, kwargs)
  return c.vars
end

function _set!(c, vars, kwargs)
  newvars = merge(vars, values(kwargs))
  _run_controller(c, newvars)
  return newvars
end

function _run_controller(c, vars)
  fcns = c.fcns
  for (ele_and_prop,f) in fcns
    ele = first(ele_and_prop)
    prop = last(ele_and_prop)
    val = f(ele; vars...)
    setproperty!(ele, prop, val)
  end
  return
end
