using BenchmarkTools, LoopVectorization, SIMD

N = 10000
v0 = rand(N,4)
v = zero(v0)
L = 5.0

const REGISTER_SIZE = LoopVectorization.VectorizationBase.register_size()

function foo!(N, v, v0, L)
  @simd for i in 1:N
    @inbounds v[i,1] = v0[i,1] + v0[i,2]*L
    @inbounds v[i,2] = v0[i,2]
    @inbounds v[i,3] = v0[i,3] + v0[i,4]*L
    @inbounds v[i,4] = v0[i,4]
  end
  return v
end

function foo_turbo!(N, v, v0, L)
  @turbo for i in 1:N
    @inbounds v[i,1] = v0[i,1] + v0[i,2]*L
    @inbounds v[i,2] = v0[i,2]
    @inbounds v[i,3] = v0[i,3] + v0[i,4]*L
    @inbounds v[i,4] = v0[i,4]
  end
  return v
end

function foo_simd!(N, v::A, v0, L) where {A}
  lane_size = Int(REGISTER_SIZE/sizeof(eltype(A))) 
  lane = VecRange{lane_size}(0)
  for i in 1:lane_size:N
    @inbounds v[lane+i,1] = v0[lane+i,1] + v0[lane+i,2]*L
    @inbounds v[lane+i,2] = v0[lane+i,2]
    @inbounds v[lane+i,3] = v0[lane+i,3] + v0[lane+i,4]*L
    @inbounds v[lane+i,4] = v0[lane+i,4]
  end
  return v
end

@btime foo!($N, $v, $v0, $L)
@btime foo_turbo!($N, $v, $v0, $L)
@btime foo_simd!($N, $v, $v0, $L)
