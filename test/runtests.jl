using ShiftedArrays, OffsetArrays
using Test

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
    @test isequal(sv[-3:3], Union{Int64, Missing}[missing, missing, missing, 1, 3, 5, 4])
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
    sv[7] = 12
    @test collect(sv) == [3, 0, 12, 1]
    @test v == [1, 3, 0, 12]
    @test checkbounds(Bool, sv, 123)
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

@testset "reduce" begin
    v = [1, 3, 5, 6, 7, 8, 9, 11]
    ss = ShiftedArray.((v,), [-1, -3, -6])
    @test reduce(+, ss, -1:2) == [10, 14, 18, 23]
    @test mapreduce(t -> t^2, +, ss, -1:2) == [58, 90, 126, 195]
    @test isequal(reduce(+, ss, -10:2),
     [missing, missing, missing, missing, missing, 1, 3, 5, 7, 10, 14, 18, 23])
end

@testset "reduce_vec" begin
    v = [1, 3, 5, 6, 7, 8, 9, 11]
    ss = ShiftedArray.((v,), [-1, -3, -6])
    @test reduce_vec(sum, ss, -1:2) == [10, 14, 18, 23]
    @test mapreduce_vec(t -> t^2, sum, ss, -1:2) == [58, 90, 126, 195]
    @test isequal(reduce_vec(sum, ss, -10:2),
     [missing, missing, missing, missing, missing, 1, 3, 5, 7, 10, 14, 18, 23])
end

@testset "offset" begin
    v = [1, 3, 5, 6, 7, 8, 9, 11]
    ss = ShiftedArray.((v,), [-1, -3, -6])
    @test isequal(ShiftedArrays.to_array(ss, -1:2), [missing 3 7; 1 5 8; 3 6 9; 5 7 11])
    @test isequal(ShiftedArrays.to_offsetarray(ss, -1:2), OffsetArray([missing 3 7; 1 5 8; 3 6 9; 5 7 11], -1:2, 1:3))
end
