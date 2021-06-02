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
    @test @macroexpand( @pyfrom math import a as aa, b as bb, c ) isa Expr
    @test_throws Exception @pyfrom math import a as aa, b as bb, c

    # Do we understand a.b.c.d correctly?
    @test PyFrom.dotpath_expansion(:(a.b.c.d)) isa Tuple
    @test PyFrom.dotpath_expansion(:(a)) isa Tuple
    @test_throws PyFrom.DotExpansionException PyFrom.dotpath_expansion(:(a."b".c.d))
    @test_throws PyFrom.DotExpansionException PyFrom.dotpath_expansion(:(a.c.d + 5))


    # Do we understand import ... correctly?
    @test PyFrom.importphrase_to_mapping(:(import a, b, c)) == [:a=>:a, :b=>:b, :c=>:c]
    @test PyFrom.importphrase_to_mapping(:(import a as A, b, c)) == [:a=>:A, :b=>:b, :c=>:c]
    @test_throws PyFrom.ImportPhraseException PyFrom.importphrase_to_mapping(:(import a as A, b.c, c))

end;
