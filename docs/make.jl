using Documenter, ShiftedArrays

makedocs(
    # options
    doctest = false,
    modules = [ShiftedArrays],
    sitename = "ShiftedArrays.jl",
    format = Documenter.HTML(),
    pages = Any[
        "Introduction" => "index.md",
    ]
)
