if !isfile(joinpath(@__DIR__, "already_showed"))
    print_with_color(Base.info_color(), STDERR,
    """
    The shift index convention has changed to be in agreement with Julia's function
    `circshift`. Now a positive shift shits to the right, i.e. `ShiftedVector(v, 1)[2] == v[2-1] == v[1]`.
    Similarly `copy(CircShiftedVector(v, 1)) == circshift(v, 1)`.
    In agreement with the Base function `circshift`, the `dim` keyword argument is no longer
    supported. If the shift vector is too short (or if you input an integer) only the first
    few dimensions will be shifted.
    For more details see https://github.com/piever/ShiftedArrays.jl
    """)
    touch("already_showed")
end
