using ShiftedArrays, Test
using AbstractFFTs 

@testset "ShiftedVector" begin
    v = [1, 3, 5, 4]
    @test all(v .== ShiftedVector(v))
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
    svnest = ShiftedVector(ShiftedVector(v, 1), 2)
    sv = ShiftedVector(v, 3)
    @test sv === svnest
    sv = ShiftedVector(v, 2, default = nothing)
    sv1 = ShiftedVector(sv, 1)
    sv2 = ShiftedVector(sv, 1, default = 0)
    @test isequal(collect(sv1), [nothing, nothing, nothing, 1])
    @test isequal(collect(sv2), [0, nothing, nothing, 1])
end

@testset "ShiftedArray" begin
    v = reshape(1:16, 4, 4)
    @test all(v .== ShiftedArray(v))
    sv = ShiftedArray(v, (-2, 0))
    @test length(sv) == 16
    @test sv[1, 3] == 11
    @test ismissing(sv[3, 3])
    @test shifts(sv) == (-2,0)
    @test isequal(sv, ShiftedArray(v, -2))
    @test isequal(@inferred(ShiftedArray(v, (2,))), @inferred(ShiftedArray(v, 2)))
    @test isequal(@inferred(ShiftedArray(v)), @inferred(ShiftedArray(v, (0, 0))))
    s = ShiftedArray(v, (0, -2))
    @test isequal(collect(s), [ 9 13 missing missing;
                               10 14 missing missing;
                               11 15 missing missing;
                               12 16 missing missing])
    sneg = ShiftedArray(v, (0, -2), default = -100)
    @test all(sneg .== coalesce.(s, default(sneg)))
    @test checkbounds(Bool, sv, 2, 2)
    @test !checkbounds(Bool, sv, 123, 123)
    svnest = ShiftedArray(ShiftedArray(v, (1, 1)), 2)
    sv = ShiftedArray(v, (3, 1))
    @test sv === svnest
    sv = ShiftedArray(v, 2, default = nothing)
    sv1 = ShiftedArray(sv, (1, 1))
    sv2 = ShiftedArray(sv, (1, 1), default = 0)
    @test isequal(collect(sv1), [nothing   nothing   nothing   nothing
                                 nothing   nothing   nothing   nothing
                                 nothing   nothing   nothing   nothing
                                 nothing  1         5         9      ])
    @test isequal(collect(sv2), [0  0         0         0
                                 0   nothing   nothing   nothing
                                 0   nothing   nothing   nothing
                                 0  1         5         9      ])
end

@testset "padded_tuple" begin
    v = rand(2, 2)
    @test (1, 0) == @inferred ShiftedArrays.padded_tuple(v, 1)
    @test (0, 0) == @inferred ShiftedArrays.padded_tuple(v, ())
    @test (3, 0) == @inferred ShiftedArrays.padded_tuple(v, (3,))
    @test (1, 5) == @inferred ShiftedArrays.padded_tuple(v, (1, 5))
end

@testset "bringwithin" begin
    @test ShiftedArrays.bringwithin(1, 1:10) == 1   
    @test ShiftedArrays.bringwithin(0, 1:10) == 10   
    @test ShiftedArrays.bringwithin(-1, 1:10) == 9 
    
    # test to check for offset axes
    @test ShiftedArrays.bringwithin(5, 5:10) == 5
    @test ShiftedArrays.bringwithin(4, 5:10) == 10
end

@testset "CircShiftedVector" begin
    v = [1, 3, 5, 4]
    @test all(v .== CircShiftedVector(v))
    sv = CircShiftedVector(v, -1)
    @test isequal(sv, CircShiftedVector(v, (-1,)))
    @test length(sv) == 4
    @test all(sv .== [3, 5, 4, 1])
    diff = v .- sv
    @test diff == [-2, -2, 1, 3]
    @test shifts(sv) == (3,)
    sv2 = CircShiftedVector(v, 1)
    diff = v .- sv2
    @test copy(sv2) == [4, 1, 3, 5]
    @test all(CircShiftedVector(v, 1) .== circshift(v, 1))
    sv[2] = 0
    @test collect(sv) == [3, 0, 4, 1]
    @test v == [1, 3, 0, 4]
    sv[3] = 12 
    @test collect(sv) == [3, 0, 12, 1]
    @test v == [1, 3, 0, 12]
    @test sv === setindex!(sv, 12, 3) 
    @test checkbounds(Bool, sv, 2)
    @test !checkbounds(Bool, sv, 123)
    sv = CircShiftedArray(v, 3)
    svnest = CircShiftedArray(CircShiftedArray(v, 2), 1)
    @test sv === svnest
end

@testset "CircShiftedArray" begin
    v = reshape(1:16, 4, 4)
    @test all(v .== CircShiftedArray(v))
    sv = CircShiftedArray(v, (-2, 0))
    @test length(sv) == 16
    @test sv[1, 3] == 11
    @test shifts(sv) == (2, 0)
    @test isequal(sv, CircShiftedArray(v, -2))
    @test isequal(@inferred(CircShiftedArray(v, 2)), @inferred(CircShiftedArray(v, (2,))))
    @test isequal(@inferred(CircShiftedArray(v)), @inferred(CircShiftedArray(v, (0, 0))))
    s = CircShiftedArray(v, (0, 2))
    @test isequal(collect(s), [ 9 13 1 5;
                               10 14 2 6;
                               11 15 3 7;
                               12 16 4 8])
    sv = CircShiftedArray(v, 3)
    svnest = CircShiftedArray(CircShiftedArray(v, 2), 1)
    @test sv === svnest
end

@testset "circshift" begin
    v = reshape(1:16, 4, 4)
    @test all(circshift(v, (1, -1)) .== ShiftedArrays.circshift(v, (1, -1)))
    @test all(circshift(v, (1,)) .== ShiftedArrays.circshift(v, (1,)))
    @test all(circshift(v, 3) .== ShiftedArrays.circshift(v, 3))
    sv = ShiftedArrays.circshift(v, 3)
    svnest = ShiftedArrays.circshift(ShiftedArrays.circshift(v, 2), 1)
    @test sv === svnest
end

@testset "fftshift and ifftshift" begin
    function test_fftshift(x, dims=1:ndims(x))
        @test fftshift(x, dims) == ShiftedArrays.fftshift(x, dims)
        @test ifftshift(x, dims) == ShiftedArrays.ifftshift(x, dims)
    end

    test_fftshift(randn((10,)))
    test_fftshift(randn((11,)))
    test_fftshift(randn((10,)), (1,))
    test_fftshift(randn(ComplexF32, (11,)), (1,))
    test_fftshift(randn((10, 11)), (1,))
    test_fftshift(randn((10, 11)), (2,))
    test_fftshift(randn(ComplexF32,(10, 11)), (1, 2))
    test_fftshift(randn((10, 11)))

    test_fftshift(randn((10, 11, 12, 13)), (2, 4))
    test_fftshift(randn((10, 11, 12, 13)), (5))
    test_fftshift(randn((10, 11, 12, 13)))

    @test (2, 2, 0) == ShiftedArrays.ft_center_diff((4, 5, 6), (1, 2)) # Fourier center is at (2, 3, 0)
    @test (2, 2, 3) == ShiftedArrays.ft_center_diff((4, 5, 6), (1, 2, 3)) # Fourier center is at (2, 3, 4)
end

@testset "laglead" begin
    v = [1, 3, 8, 12]
    diff = v .- ShiftedArrays.lag(v)
    @test isequal(diff, [missing, 2, 5, 4])

    diff2 = v .- ShiftedArrays.lag(v, 2)
    @test isequal(diff2, [missing, missing, 7, 9])

    @test all(ShiftedArrays.lag(v, 2, default = -100) .== coalesce.(ShiftedArrays.lag(v, 2), -100))

    diff = v .- ShiftedArrays.lead(v)
    @test isequal(diff, [-2, -5, -4, missing])

    diff2 = v .- ShiftedArrays.lead(v, 2)
    @test isequal(diff2, [-7, -9, missing, missing])

    @test all(ShiftedArrays.lead(v, 2, default = -100) .== coalesce.(ShiftedArrays.lead(v, 2), -100))

    @test ShiftedArrays.lag(ShiftedArrays.lag(v, 1), 2) === ShiftedArrays.lag(v, 3)
    @test ShiftedArrays.lead(ShiftedArrays.lead(v, 1), 2) === ShiftedArrays.lead(v, 3)
end
