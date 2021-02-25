using ShiftedArrays, Test, Dates

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

  
    v = [4, 5, 6]
    times = [1989, 1991, 1992]
    @test all(lag(v, times) .=== [missing, missing, 5])
    @test all(lag(v, times; default = 0) .=== [0, 0, 5])
    @test all(lead(v, times) .=== [missing, 6, missing])
    @test all(lead(v, times; default = 0) .=== [0, 6, 0])
    times = [Date(1989, 1, 1), Date(1989, 1, 3), Date(1989, 1, 4)]
    @test all(lag(v, times, Day(1)) .=== [missing, missing, 5])
    @test all(lag(v, times, Day(2)) .=== [missing, 4, missing])
    @test all(lag(v, times, Day(5)) .=== [missing, missing, missing])
    @test all(lead(v, times, Day(1)) .=== [missing, 6, missing])
    @test all(lead(v, times, Day(1)) .=== lag(v, times, -Day(1)))
    @test all(lead(v, times, Day(2)) .=== [5, missing, missing])
    @test all(lead(v, times, Day(5)) .=== [missing, missing, missing])
    times = [DateTime(1989, 1, 1), DateTime(1989, 1, 3), DateTime(1989, 1, 4)]
    @test all(lag(v, times, Millisecond(1)) .=== [missing, missing, missing])
    @test all(lag(v, times, Day(1)) .=== [missing, missing, 5])
    times = [Date(1989, 1, 1), Date(1989, 1, 3), Date(1989, 1, 3)]
    @test_throws ErrorException lag(v, times, Day(1))
end
