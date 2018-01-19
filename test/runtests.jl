using ShiftedArrays, Missings
using Base.Test

@testset "ShiftedVector" begin
    v = [1, 3, 5, 4]
    sv = ShiftedVector(v, 1)
    @test length(sv) == 4
    @test sv[2] == 5
    @test Missings.ismissing(sv[4])
    diff = v .- sv
    @test diff[1:3] == [-2, -2, 1]
    @test ismissing(diff[4])
    @test shifts(sv) == (1,)
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
