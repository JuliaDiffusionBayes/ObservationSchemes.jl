

macro parametrized_linear_gsn(name, ex::Expr, p...)
    parse_linear_gsn(name, MacroTools.striplines(ex), p)
end

function parse_linear_gsn(name, ex::Expr, ::Any)
    name, curly_name, template_args = process_name(name)
    p = (
        name = name,
        curly_name = curly_name,
        template_args = template_args,
        parameters = Vector{Tuple{Symbol,Union{Symbol,Expr}}}(
            undef,
            0
        ),
        fns = Vector{Expr}(undef, 0),
    )
    parse_parameter_lines!(ex, p)
    parse_function_lines!(ex, p, x->(x in [:L, :Σ, :μ]))
end

#NOTE originally defined in DiffusionDefinition, define in one place only and import
function process_name end
process_name(name::Symbol) = name, name, Any[]
process_name(name::Expr) = name.args[1], name, name.args[2:end]


function parse_parameter_lines!(ex::Expr, p)
    for line in ex.args
        @assert line.head == :-->
        name = line.args[1]
        name in [:L, :Σ, :v, :μ] || append!(p.parameters, [(name, line.args[2])])
    end
end

function parse_function_lines!(ex::Expr, p)
    for line in ex.args
        @assert line.head == :-->
        name = line.args[1]
        name in [:L, :Σ, :μ] && append!(p.fns, parse_function(name, line.args[2]))
    end
end

function parse_function!(name, fn_body)

end
