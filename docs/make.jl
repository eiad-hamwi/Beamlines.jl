using Beamlines
using Documenter

DocMeta.setdocmeta!(Beamlines, :DocTestSetup, :(using Beamlines); recursive=true)

makedocs(;
    modules=[Beamlines],
    authors="mattsignorelli <mgs255@cornell.edu> and contributors",
    sitename="Beamlines.jl",
    format=Documenter.HTML(;
        canonical="https://mattsignorelli.github.io/Beamlines.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/mattsignorelli/Beamlines.jl",
    devbranch="main",
)
