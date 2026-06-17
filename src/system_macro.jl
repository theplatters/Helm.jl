using MacroTools

function qualify_symbols(expr)
    if expr === :Query
        return :(Helm.Query)
    elseif expr === :Mut
        return :(Helm.Mut)
    elseif expr === :Res
        return :(Helm.Res)
    elseif expr === :ResMut
        return :(Helm.ResMut)
    elseif expr === :Filter
        return :(Helm.Filter)
    elseif expr isa Expr
        return Expr(expr.head, map(qualify_symbols, expr.args)...)
    else
        return expr
    end
end

macro system(expr)
    if @capture(expr, (name_(args__) = body_) | (function name_(args__) body_ end))
        vars = Symbol[]
        types = Any[]
        for arg in args
            if @capture(arg, var_::type_)
                push!(vars, var)
                push!(types, qualify_symbols(type))
            else
                error("All arguments to a system must have type annotations, got: $arg")
            end
        end
        return esc(quote
            $name = Helm.System(($(vars...),) -> $body, ($(types...),))
        end)
    else
        error("The @system macro must be applied to a function definition")
    end
end
