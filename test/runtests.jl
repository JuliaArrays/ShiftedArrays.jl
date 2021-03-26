using ShiftedArrays, Test

@testset "ShiftedVector" begin
    v = [1, 3, 5, 4]
    sv = ShiftedVector(v, -1)
    @test isequal(sv, ShiftedVector(v, (-1,)))
    @test length(sv) == 4
    @test all(sv[1:3] .== [3, 5, 4])
    @test ismissing(sv[4])
    diff = v .- sv
    @test isequal(diff, [-2, -2, 1, missing])
    @test shifts(sv) == (-1,)
    svneg = ShiftedVector(v, -1, default = -100)
    @test default(svneg) == -100
    @test copy(svneg) == coalesce.(sv, -100)
    @test isequal(sv[1:3], Union{Int64, Missing}[3, 5, 4])
end

@testset "ShiftedArray" begin
    v = reshape(1:16, 4, 4)
    sv = ShiftedArray(v, (-2, 0))
    @test length(sv) == 16
    @test sv[1, 3] == 11
    @test ismissing(sv[3,3])
    @test shifts(sv) == (-2,0)
    @test isequal(sv, ShiftedArray(v, -2))
    @test isequal(ShiftedArray(v, (2,)), ShiftedArray(v, 2))
    s = ShiftedArray(v, (0, -2))
    @test isequal(collect(s), [ 9 13 missing missing;
                               10 14 missing missing;
                               11 15 missing missing;
                               12 16 missing missing])
    sneg = ShiftedArray(v, (0, -2), default = -100)
    @test all(sneg .== coalesce.(s, default(sneg)))
    @test checkbounds(Bool, sv, 123, 123)
end

@testset "bringwithin" begin
    @test ShiftedArrays.bringwithin(1, 1:10) == 1   
    @test ShiftedArrays.bringwithin(11, 1:10) == 1   
    @test ShiftedArrays.bringwithin(12, 1:10) == 2  
    @test ShiftedArrays.bringwithin(0, 1:10) == 10 
    @test ShiftedArrays.bringwithin(-1, 1:10) == 9  
    @test ShiftedArrays.bringwithin((12, 13), axes(randn((3, 4)))) == (3, 1)
    @test ShiftedArrays.bringwithin((-1, 13), axes(randn((3, 4)))) == (2, 1)
end


@testset "CircShiftedVector" begin
    v = [1, 3, 5, 4]
    sv = CircShiftedVector(v, -1)
    @test isequal(sv, CircShiftedVector(v, (-1,)))
    @test length(sv) == 4
    @test all(sv .== [3, 5, 4, 1])
    diff = v .- sv
    @test diff == [-2, -2, 1, 3]
    @test shifts(sv) == (-1,)
    sv2 = CircShiftedVector(v, 1)
    diff = v .- sv2
    @test copy(sv2) == [4, 1, 3, 5]
    @test all(CircShiftedVector(v, 1) .== circshift(v,1))
    sv[2] = 0
    @test collect(sv) == [3, 0, 4, 1]
    @test v == [1, 3, 0, 4]
    sv[3] = 12  # RH changed this behaviour
    @test collect(sv) == [3, 0, 12, 1]
    @test v == [1, 3, 0, 12]
    @test ~checkbounds(Bool, sv, 123)  # RH changed this behaviour
end

@testset "CircShiftedArray" begin
    v = reshape(1:16, 4, 4)
    sv = CircShiftedArray(v, (-2, 0))
    @test length(sv) == 16
    @test sv[1, 3] == 11
    @test shifts(sv) == (-2,0)
    @test isequal(sv, CircShiftedArray(v, -2))
    @test isequal(CircShiftedArray(v, 2), CircShiftedArray(v, (2,)))
    s = CircShiftedArray(v, (0, 2))
    @test isequal(collect(s), [ 9 13 1 5;
                               10 14 2 6;
                               11 15 3 7;
                               12 16 4 8])
end

@testset "circshift" begin
    v = reshape(1:16, 4, 4)
    @test all(circshift(v, (1, -1)) .== ShiftedArrays.circshift(v, (1, -1)))
    @test all(circshift(v, (1,)) .== ShiftedArrays.circshift(v, (1,)))
    @test all(circshift(v, 3) .== ShiftedArrays.circshift(v, 3))
end

@testset "laglead" begin
    v = [1, 3, 8, 12]
    diff = v .- lag(v)
    @test isequal(diff, [missing, 2, 5, 4])

    diff2 = v .- lag(v, 2)
    @test isequal(diff2, [missing, missing, 7, 9])

    @test all(lag(v, 2, default = -100) .== coalesce.(lag(v, 2), -100))

    diff = v .- lead(v)
    @test isequal(diff, [-2, -5, -4, missing])

    diff2 = v .- lead(v, 2)
    @test isequal(diff2, [-7, -9, missing, missing])

    @test all(lead(v, 2, default = -100) .== coalesce.(lead(v, 2), -100))
end
