using PyFrom
using Test

@testset "PyFrom" begin
    
    # Correct syntax
    @pyfrom collections.abc import Callable
    @test Callable !== nothing

    # Correct syntax
    @pyfrom math import inf as py∞, pi as pyπ, tau
    @test pyπ ≈ π
    @test py∞ ≈ Inf
    @test tau ≈ 2π

    # Incorrect syntax
    @test_throws LoadError @macroexpand @pyfrom math import a.b.c as d
    @test_throws PyFrom.ImportPhraseException PyFrom.pyfrom(:math, :(import a.b.c as d))

    # Correct syntax, but wrong imports
    @test PyFrom.pyfrom(:math, :(import a as aa, b as bb, c)) isa Expr
    @test_throws PyCall.PyError @pyfrom math import a as aa, b as bb, c

end;
