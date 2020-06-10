import Base: eltype, size, length

"""
    Observation{D,T}

Types inheriting from this struct provide all information about the observation
of the stochastic process being made. `D` denotes the dimension of the
observation whereas `T` its eltype.
"""
abstract type Observation{D,T} end

"""
    ParametrizedObservation{D,T} <: Observation{D,T}

Same as observations but additionally, types inheriting from this struct depend
on some parameters (that may in practice be unknown).
"""
abstract type ParametrizedObservation{D,T} <: Observation{D,T} end

"""
    eltype(::Type{K}) where {K<:Observation{D,T}}

Type of each entry of the collection holding an observation.
"""
eltype(::Type{K}) where {K<:Observation{D,T}} where {D,T} = T

eltype(::K) where K<:Observation = eltype(K)

"""
    size(::Type{K}) where {K<:Observation{D}}

Size of the observation
"""
size(::Type{K}) where {K<:Observation{D}} where D = D

size(::K) where K<:Observation = size(K)

"""
    length(::Type{K}) where {K<:Observation{D}}

Length of the observation (equal to a number of entries in a vector holding the
data)
"""
length(::Type{K}) where {K<:Observation{D}} where D = _size_to_length(D)

length(::K) where K<:Observation = length(K)

_size_to_length(s::Number) = s
_size_to_length(s::Tuple) = prod(s)

#TODO check if can be removed, doesn't seem to be used
"""
    parameter_names

Return names of the parameters of a given object
"""
function parameter_names end

# TODO check if can be safely removed
function clone end

function set_parameters!(obs::Observation, η, entries)
    for (i_η, i_obs) in entries
        obs.θ[i_obs] = η[i_η]
    end
end
