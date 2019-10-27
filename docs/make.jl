using Documenter, ShiftedArrays

DocMeta.setdocmeta!(ShiftedArrays, :DocTestSetup, :(using ShiftedArrays); recursive=true)

makedocs(
    # options
    modules = [ShiftedArrays],
    sitename = "ShiftedArrays.jl",
    format = Documenter.HTML(),
    pages = Any[
        "Introduction" => "index.md",
    ]
)
