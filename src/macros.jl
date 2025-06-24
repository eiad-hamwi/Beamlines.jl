macro eles(expr_or_block)
  if expr_or_block isa Expr && expr_or_block.head == :block
    block = expr_or_block
    return Expr(:block, map(block.args) do x
      if x isa LineNumberNode
        return x
      end
      return add_name(x)
    end...)
  else
    expr = expr_or_block
    return add_name(expr)
  end
end

function add_name(expr)
  if @capture(expr,  name_ = rhs_) 
    namestr = String(name)
    return :($(esc(name)) = setname($(esc(rhs)), $namestr))
  else
    return :($(esc(expr)))
  end
end

function setname(ele::LineElement, name::String)
  ele.name = name
  return ele
end

setname(not_ele, name::String) = not_ele