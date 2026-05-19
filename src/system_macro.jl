struct Mut{T} end
struct Res{T} end
struct ResMut{T} end
struct Query{T, F} end
struct With{T} end
struct Without{T} end
struct CommandBuffer end

using MacroTools

function capture_query(query_args)
    # Ensure it's an array to iterate over (handles single-argument fallback)
    if !(query_args isa AbstractArray)
        query_args = Any[query_args]
    end

    comp_types = Any[]
    w = Any[]
    wo = Any[]

    for arg in query_args
        # Handle kwargs if a semicolon is used: Query(...; with=(...))
        if arg isa Expr && arg.head == :parameters
            for kw in arg.args
                if @capture(kw, with = (w_args__,))
                    w = w_args
                elseif @capture(kw, without = (wo_args__,))
                    wo = wo_args
                end
            end

            # Handle standard kwargs: Query(..., with=(...))
        elseif @capture(arg, with = (w_args__,))
            w = w_args

        elseif @capture(arg, without = (wo_args__,))
            wo = wo_args

            # Handle the main component tuple: (A, B) or ()
        elseif @capture(arg, (comps__,))
            comp_types = comps

        else
            error("Unrecognized Query argument: $arg")
        end
    end

    write_comps = Symbol[]
    read_comps = Symbol[]

    for x in comp_types
        if @capture(x, Mut(t_Symbol))
            push!(write_comps, t)
        elseif @capture(x, t_Symbol)
            push!(read_comps, t)
        else
            error("Expr $x can't be converted into a component type")
        end
    end

    return quote
        Helmsman.QueryData(
            $(Expr(:tuple, read_comps...)),
            $(Expr(:tuple, write_comps...)),
            $(Expr(:tuple, w...)),
            $(Expr(:tuple, wo...))
        )
    end
end

function capture_resource_mut(expr)
    @capture(expr, t_Symbol) || error("Expression is not a Symbol")
    return :(Helmsman.ResourceData(true, $t))
end

function capture_resource(expr)
    @capture(expr, t_Symbol) || error("Expression is not a Symbol")
    return :(Helmsman.ResourceData(false, $t))
end

macro system(expr)
    @capture(
        expr, (f_(args__) = body_) | (
            function f_(args__)
                body_
            end
        )
    ) ||
        error("The system macro has to be applied to functions")


    queries = Dict{Symbol, Expr}()
    resources = Dict{Symbol, Expr}()
    command_buffer_name::Union{Nothing, Symbol} = nothing
    needs_command_buffer = false

    for x in args

        # 1. Safely split the argument into `variable_name::type_signature`
        if @capture(x, var_::argtype_)

            # 2. Pattern match against the type signature
            if @capture(argtype, Query(query_args__))
                queries[var] = capture_query(query_args)

            elseif @capture(argtype, Res(res_body_))
                resources[var] = capture_resource(res_body)

            elseif @capture(argtype, ResMut(res_body_))
                resources[var] = capture_resource_mut(res_body)

                # (Matches both cmds::CommandBuffer and cmds::CommandBuffer())
            elseif @capture(argtype, CommandBuffer() | CommandBuffer)
                command_buffer_name = var
                needs_command_buffer = true
            else
                @warn "Unrecognized argument type: $argtype"
            end

        else
            @warn "Argument $x is missing a type annotation"
        end
    end

    setup_exprs = Expr[]

    for (var, query_expr) in queries
        push!(setup_exprs, :($var = Helmsman.fetch_query(world, $query_expr)))
    end

    for (var, res_expr) in resources
        push!(setup_exprs, :($var = Helmsman.fetch_resource(world, $res_expr)))
    end

    if !isnothing(command_buffer_name)
        push!(setup_exprs, :($(command_buffer_name) = Helmsman.CommandBuffer(world)))
    end

    return esc(
        quote

            Helmsman.System(
                world -> begin
                end,
                $(Expr(:tuple, values(queries)...)),
                $(Expr(:tuple, values(resources)...)),
                $needs_command_buffer
            )

        end
    )
end
