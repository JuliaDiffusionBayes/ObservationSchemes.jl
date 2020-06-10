"""
    print_parameters(all_obs::AllObservations)

Print information about the variable parameters about which the
`all_obs.param_depend` object stores some interdependency information.
"""
function print_parameters(all_obs::AllObservations)
    num_rec = length(all_obs.recordings)
    params = collect(keys(all_obs.param_depend))
    obs = collect(keys(all_obs.param_depend))
    p_and_o = collect(unique(hcat(obs, params)))
    println()
    println("There are $num_rec independent recordings.")
    println("There are also $(length(p_and_o)) variable parameters.")
    println("* * *")
    println("You may define the var-parameters using the following template:")
    println("# start of template")
    println("using OrderedCollections")
    println()
    println("θ_init = OrderedDict(")
    for (i,p) in enumerate(p_and_o)
        println("\t:$p => ... , # param $i")
    end
    println(")")
    println("# end of template")
    println("and in an MCMC setting you may let your parameter update step ")
    println("refer to a subset of indices you wish to update using the order ")
    println("given above.")
    println("* * *")
end



const _SYMS = Tuple{Vararg{Pair{Int64,Symbol},N} where N} # localθidx, pname
const _OBSIDX = Tuple{Vararg{Pair{Int64,Int64},N} where N} # localθidx, obsidx
"""
    local_symbols(
        all_obs::AllObservations,
        objects::AbstractArray{<:AbstractArray},
        f::Function,
        θsym::Vector{Symbol}
    ) where T

`objects` is usually an array of arrays that must in total have the same number
of elements as there are observations in the recording. It may however have a
different jagged structure. The output is of the same structure as `objects`
and gives for each `o` in `object` a corresponding lists of parameters and
observations it depends on.
"""
function local_symbols(
        all_obs::AllObservations,
        objects::AbstractArray{<:AbstractArray},
        f::Function,
        θsym::Vector{Symbol}
    ) where T
    all_p_symbols = Vector{Vector{_SYMS}}(undef, length(objects))
    all_o_indices = Vector{Vector{_OBSIDX}}(undef, length(objects))
    _i = _j = 1

    for i in eachindex(objects)
        all_p_symbols[i] = Vector{_SYMS}(undef, length(objects[i]))
        all_o_indices[i] = Vector{_OBSIDX}(undef, length(objects[i]))

        for j in eachindex(objects[i])
            plocal, olocal = find_local_names(all_obs, θsym, (_i, _j))
            all_p_symbols[i][j] = Tuple(
                filter(s->hasproperty(f(objects[i][j]), s[2]), plocal)
            )
            all_o_indices[i][j] = Tuple(olocal)
            _j += 1
            if _j > length(all_obs.recordings[_i].obs)
                _j = 1
                _i += 1
            end
        end
    end
    all_p_symbols, all_o_indices
end


function find_local_names(all_obs::AllObservations, θsym, (i, j))
    plocal = Pair{Int64,Symbol}[]
    p_dep = all_obs.param_depend_rev[i]

    for k in 1:length(p_dep)
        global_symbol, local_symbol = p_dep[k]
        idx = findfirst(x->x==global_symbol, θsym)
        if idx != nothing
            push!(plocal, (idx => local_symbol))
        end
    end

    olocal = Pair{Int64,Int64}[]
    o_dep = all_obs.obs_depend_rev[i][j]

    for k in 1:length(o_dep)
        global_symbol, local_idx = o_dep[k]
        idx = findfirst(x->x==global_symbol, θsym)
        if idx != nothing
            push!(olcal, (idx => local_idx))
        end
    end
    plocal, olocal
end
