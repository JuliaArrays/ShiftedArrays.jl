using ShiftedArrays, Missings
using Base.Test

@testset "ShiftedVector" begin
    v = [1, 3, 5, 4]
    sv = ShiftedVector(v, 1)
    @test isequal(sv, ShiftedVector(v, 1; dim = 1))
    @test isequal(sv, ShiftedVector(v, (1,)))
    @test length(sv) == 4
    @test sv[2] == 5
    @test ismissing(sv[4])
    diff = v .- sv
    @test diff[1:3] == [-2, -2, 1]
    @test ismissing(diff[4])
    @test shifts(sv) == (1,)
end

@testset "ShiftedArray" begin
    v = reshape(1:16, 4, 4)
    sv = ShiftedArray(v, (2, 0))
    @test length(sv) == 16
    @test sv[1, 3] == 11
    @test ismissing(sv[3,3])
    @test shifts(sv) == (2,0)
    @test isequal(sv, ShiftedArray(v, 2))
    @test isequal(ShiftedArray(v, (0,2)), ShiftedArray(v, 2; dim = 2))
end

@testset "laglead" begin
    v = [1, 3, 8, 12]
    diff = v .- lag(v)
    @test diff[2:4] == [2, 5, 4]
    @test ismissing(diff[1])

    diff2 = v .- lag(v, 2)
    @test diff2[3:4] == [7, 9]
    @test ismissing(diff2[1]) && ismissing(diff2[2])

    diff = v .- lead(v)
    @test diff[1:3] == [-2, -5, -4]
    @test ismissing(diff[4])

    diff2 = v .- lead(v, 2)
    @test diff2[1:2] == [-7, -9]
    @test ismissing(diff2[3]) && ismissing(diff2[4])
end

@testset "reduce" begin
    v = [1, 3, 5, 6, 7, 8, 9, 11]
    ss = ShiftedArray.((v,), [1, 3, 6])
    @test reduce(+, ss, -1:2) == [10, 14, 18, 23]
    @test mapreduce(t -> t^2, +, ss, -1:2) == [58, 90, 126, 195]
    @test isequal(reduce(+, ss, -10:2),
     [missing, missing, missing, missing, missing, 1, 3, 5, 7, 10, 14, 18, 23])
end

@testset "reduce_vec" begin
    v = [1, 3, 5, 6, 7, 8, 9, 11]
    ss = ShiftedArray.((v,), [1, 3, 6])
    @test reduce_vec(sum, ss, -1:2) == [10, 14, 18, 23]
    @test mapreduce_vec(t -> t^2, sum, ss, -1:2) == [58, 90, 126, 195]
    @test isequal(reduce_vec(sum, ss, -10:2),
     [missing, missing, missing, missing, missing, 1, 3, 5, 7, 10, 14, 18, 23])
end
