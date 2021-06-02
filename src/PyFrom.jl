module PyFrom
    using Base: Symbol, Tuple, UV_PROCESS_WINDOWS_VERBATIM_ARGUMENTS
    using PyCall
    export @pyfrom


    struct ImportPhraseException <: Exception 
        var::String
    end


    macro pyfrom(modname, importphrase)
        return pyfrom(modname, importphrase)
    end


    pyfrom(modname, importphrase) = begin
        errmessage() = begin
            ("@pyfrom must follow a pattern like `@pyfrom a.b import c as cc, d, e as ee, f, g`, " *
            "got `@pyfrom $modname $importphrase`")
        end

        importmap = try
            importphrase_to_mapping(importphrase)
        catch e
            e isa ImportPhraseException  && throw(ImportPhraseException(errmessage()))
            rethrow(e)
        end

        # list of creeping module paths, like [:(a), :(a.b), :(a.b.c), :(a.b.c.d)]
        nodes = []
        paths = []
        ex = modname
        while ex isa Expr && ex.head == (:.)
            push!(paths, ex)

            ex, tail = ex.args[1], ex.args[end]
            if tail isa QuoteNode
                tail = tail.value
            end

            if tail isa Symbol
                push!(nodes, tail)
            else
                throw(ErrorException(errmessage))
            end
        end
        if ex isa Symbol
            push!(paths, ex)
            push!(nodes, ex)
        else
            throw(ErrorException(errmessage))
        end

        nodes = reverse(nodes)
        paths = reverse(paths)

        # The secret souce
        @gensym get_module_imports moduleleaf imports node path pyobj_temp ii

        # Rename list of modules into their final names `aa = imports[1]; bb = imports[2]; ...`
        add_names_to_imports = Expr(:block, 
                                    [:(
                                    $name = $imports[$i]
                                    ) for (i, (_, name)) in enumerate(importmap)]...)

        esc(quote
            # Generated function to retrieve all the imports
            $get_module_imports() = begin
                $moduleleaf = nothing
                for ($node, $path) in zip($nodes, $paths)

                    if $moduleleaf === nothing
                        $moduleleaf =  $PyCall._pywrap_pyimport(pyimport($PyCall.modulename($path)))
                    elseif !hasproperty($moduleleaf, $node)
                        $pyobj_temp = $PyCall._pywrap_pyimport(pyimport($PyCall.modulename($path)))
                        #setproperty!($moduleleaf, $node, $pyobj_temp)

                        $moduleleaf = $pyobj_temp
                    else
                        $moduleleaf =  getproperty($moduleleaf, $node)
                    end
                end

                # Get all the ``... import a as aa, b as bb, c as cc, ...` into 
                # list a of objects `imports =  [_, _, _, ...]`
                $imports = []
                for ($node, _) in $importmap
                    if hasproperty($moduleleaf, $node)
                        push!($imports, getproperty($moduleleaf, $node))
                    else
                        $path = Expr(:., $paths[end], QuoteNode($node))
                        push!($imports, $PyCall._pywrap_pyimport(pyimport(PyCall.modulename($path))))
                    end
                end

                return $imports
            end

            $imports = $get_module_imports()

            # final names `aa = imports[1]; bb = imports[2]; ...`
            $add_names_to_imports
        end)

    end

    importphrase_to_mapping(expr::Expr) = begin
        err_message = "Expected import statement pattern like `import c as cc, d, e as ee, f, g`, got `$(expr)`"

        if expr.head != :import 
            throw(ImportPhraseException(err_message))
        end

        pairs = []
        for i in expr.args
            push!(
                pairs,
                i.head == :as ?  [i.args[1], i.args[2]] : [i.args[1], i.args[1]]
            )
        end

        # Extract only the symbols from the mapping
        for (i, pair) in enumerate(pairs)
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
            pairs[i] = pair[1] => pair[2]
        end
        
        return pairs
    end

end