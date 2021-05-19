using Documenter, ShiftedArrays

DocMeta.setdocmeta!(ShiftedArrays, :DocTestSetup, :(using ShiftedArrays); recursive=true)

makedocs(
    # options
    modules = [ShiftedArrays],
    sitename = "ShiftedArrays.jl",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
    ),
    pages = Any[
        "Introduction" => "index.md",
        "API" => "api.md",
    ],
    strict = true,
)

# Deploy built documentation from Travis.
# =======================================

deploydocs(
    # options
    repo = "github.com/JuliaArrays/ShiftedArrays.jl.git",
    push_preview = true,
)
