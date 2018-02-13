if !isfile(joinpath(@__DIR__, "already_showed"))
    print_with_color(Base.info_color(), STDERR,
    """
    The shift index convention has changed to be in agreement with Julia's function
    `circshift`. Now a positive shift shits to the right, i.e. `ShiftedVector(v, 1)[2] == v[2-1] == v[1]`.
    Similarly `copy(CircShiftedVector(v, 1)) == circshift(v, 1)`.
    In agreement with Julia Base, the keyword `dim` has been replaced by `dims`.
    For more details see the README at https://github.com/piever/ShiftedArrays.jl
    """)
    touch("already_showed")
end
