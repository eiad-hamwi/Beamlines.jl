using Beamlines
using Beamlines: isactive
using Test

@testset "Beamlines.jl" begin
    L = 5.0f0
    ele = LineElement(class="Test", name="Test123", L=L)

    @test ele.pdict[UniversalParams] === ele.UniversalParams

    up = ele.UniversalParams
    @test isactive(up)
    @test up.class == "Test"
    @test up.name == "Test123"
    @test typeof(up.L) == typeof(L)
    @test up.L == L
    @test up.tracking_method == SciBmadStandard()
    @test ele.class == up.class
    @test ele.name == up.name
    @test ele.L == up.L
    @test ele.tracking_method == up.tracking_method

    ele2 = deepcopy(ele)
    @test !(ele2 === ele)
    @test ele2 ≈ ele 

    up_new = UniversalParams(SciBmadStandard(), 10.0, "NewTest", "NewTest123")
    ele.UniversalParams = up_new
    @test ele.UniversalParams === up_new
    @test ele.class == up_new.class
    @test ele.name == up_new.name
    @test ele.L == up_new.L
    @test ele.tracking_method == up_new.tracking_method

    g = 0.1
    e1 = 0.123
    e2 = 0.456

    @test !isactive(ele.BendParams)
    ele.g = g
    @test isactive(ele.BendParams)
    @test ele.g == g
    @test ele.e1 == 0
    @test ele.e2 == 0

    ele.e1 = e1
    ele.e2 = e2
    @test ele.e1 == e1
    @test ele.e2 == e2

    bp = BendParams(1.0im, 2.0im, 3.0im)
    ele.BendParams = bp
    @test ele.BendParams === bp
    @test ele.g == 1.0im
    @test ele.e1 == 2.0im
    @test ele.e2 == 3.0im

    ele.g = 0.2
    @test ele.g == 0.2
    @test ele.BendParams === bp # do not change parameter group if promotion is ok

    @test !isactive(ele.AlignmentParams)
    ap = AlignmentParams(1, 2, 3, 4, 5, 6)
    ele.AlignmentParams = ap
    @test isactive(ele.AlignmentParams)
    @test ele.AlignmentParams === ap
    @test ele.x_offset == 1
    @test ele.y_offset == 2
    @test ele.z_offset == 3
    @test ele.x_rot == 4
    @test ele.y_rot == 5
    @test ele.tilt == 6

    ele.x_offset = 7
    @test ele.x_offset == 7
    @test ap.x_offset == 7
    @test ele.AlignmentParams === ap

    @test typeof(ele.x_offset) == Int
    ele.x_offset = 10.0
    @test ele.x_offset == 10.0
    @test !(ele.AlignmentParams === ap)
    @test typeof(ele.x_offset) == Float64
end
