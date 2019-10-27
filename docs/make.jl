using Documenter, ShiftedArrays

makedocs(
    # options
    modules = [ShiftedArrays],
    sitename = "ShiftedArrays.jl",
    format = Documenter.HTML(),
    pages = Any[
        "Introduction" => "index.md",
    ]
)
