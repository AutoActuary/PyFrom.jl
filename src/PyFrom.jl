module PyFrom
    using Base: Symbol, Tuple
    using PyCall
    export @pyfrom


    struct ImportPhraseException <: Exception 
        var::String
    end

    struct DotExpansionException <: Exception 
        var::String
    end

    macro pyfrom(modname, importphrase)
        return pyfrom(modname, importphrase)
    end
    

    pyfrom(modname, importphrase) = begin
        errmessage() = begin
            ("@pyfrom must follow a pattern like `@pyfrom a.b import c as d, e, f as g`, " *
            "got `@pyfrom $modname $importphrase`")
        end

        nodes, paths = try
            dotpath_expansion(modname)
        catch e
            e isa DotExpansionException  && throw(DotExpansionException(errmessage()))
            rethrow(e)
        end

        importmap = try
            importphrase_to_mapping(importphrase)
        catch e
            e isa ImportPhraseException  && throw(ImportPhraseException(errmessage()))
            rethrow(e)
        end

        # The secret souce
        names = [name for (_, name) in importmap]
        @gensym imports 
        esc(:($imports = $(get_module_imports)($nodes, $paths, $importmap);
              $(Expr(:tuple, names...)) = $imports; 
              $(last($imports))))
    end


    get_module_imports(nodes::Vector{Symbol},
                       paths::Vector{Union{Symbol, Expr}},
                       importmap::Vector{Pair{Symbol, Symbol}}) = begin
        # import from deeper nest, i.e. a -> a.b -> a.b.c -> a.b.c.d
        nextleaf(moduleleaf, node, path) = begin
            if moduleleaf === nothing || !hasproperty(moduleleaf, node)
                PyCall._pywrap_pyimport(pyimport(PyCall.modulename(path)))
            else
                getproperty(moduleleaf, node)
            end
        end

        # find module leaf
        moduleleaf = nothing
        for (node, path) in zip(nodes, paths)
            moduleleaf = nextleaf(moduleleaf, node, path)
        end

        # get relevant children from importmap in a list of modules/pyobjects
        imports = []
        for (node, _) in importmap
            path = Expr(:., paths[end], QuoteNode(node))
            push!(imports, nextleaf(moduleleaf, node, path))
        end

        return imports
    end


    dotpath_expansion(expr) = begin
        errmessage = "Expected dotted expression like `a.b.c.d.e`, got $(expr)"

        nodes = Vector{Symbol}()
        paths = Vector{Union{Symbol, Expr}}()
        ex = expr
        while ex isa Expr && ex.head == (:.)
            push!(paths, ex)

            ex, tail = ex.args[1], ex.args[end]
            if tail isa QuoteNode
                tail = tail.value
            end

            if tail isa Symbol
                push!(nodes, tail)
            else
                throw(DotExpansionException(errmessage))
            end
        end
        if ex isa Symbol
            push!(paths, ex)
            push!(nodes, ex)
        else
            throw(DotExpansionException(errmessage))
        end

        nodes = reverse(nodes)
        paths = reverse(paths)

        return nodes, paths
    end


    importphrase_to_mapping(expr::Expr)::Vector{Pair{Symbol, Symbol}} = begin
        err_message = "Expected import statement pattern like `import a as b, c, d as e, f, g`, got `$(expr)`"

        if expr.head != :import 
            throw(ImportPhraseException(err_message))
        end

        # group `a as b, c as d, ...` as [[:a, :b], [:c, :d], ...]
        pairs = []
        for i in expr.args
            push!(
                pairs,
                if i.head == :as 
                    [i.args[1], i.args[2]] 
                else
                    length(i.args) != 1 && throw(ImportPhraseException(err_message))
                    [i.args[1], i.args[1]]
                end
            )
        end

        # sanitize inputs and convert to [:a=>:b, :c=>d, ...] type of list
        pairs_final = Vector{Pair{Symbol, Symbol}}()
        for pair in pairs
            for (j, item) in enumerate(pair)
                if item isa Symbol
                elseif item isa Expr
                    if item.head == :. && length(item.args) == 1 && item.args[1] isa Symbol
                        pair[j] = item.args[1]
                    else
                        throw(ImportPhraseException(err_message))
                    end
                else
                    throw(ImportPhraseException(err_message))
                end
            end
            push!(pairs_final, pair[1] => pair[2])
        end
        
        return pairs_final
    end

end
