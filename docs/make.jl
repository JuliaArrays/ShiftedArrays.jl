using Documenter, ShiftedArrays

DocMeta.setdocmeta!(ShiftedArrays, :DocTestSetup, :(using ShiftedArrays); recursive=true)

makedocs(
    # options
    modules = [ShiftedArrays],
    sitename = "ShiftedArrays.jl",
    format = Documenter.HTML(),
    pages = Any[
        "Introduction" => "index.md",
        "API" => "api.md",
    ]
)

# Deploy built documentation from Travis.
# =======================================

deploydocs(
    # options
    repo = "github.com/JuliaArrays/ShiftedArrays.jl.git",
    target = "build",
    deps = nothing,
    make = nothing,
)
