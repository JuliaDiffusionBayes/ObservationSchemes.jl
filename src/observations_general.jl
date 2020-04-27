import Base: eltype, size, length

"""
    Observation{D,T}

Types inheriting from this struct provide all information about the observation
of the stochastic process being made. `D` denotes the dimension of the
observation whereas `T` its datatype.
"""
abstract type Observation{D,T} end

abstract type ParametrizedObservation{D,T} <: Observation{D,T} end

eltype(::K) where {K<:Observation{D,T}} where {D,T} = T

size(::K) where {K<:Observation{D}} where D = D

length(::K) where {K<:Observation{D}} where D = _size_to_length(D)

_size_to_length(s::Number) = s
_size_to_length(s::Tuple) = prod(s)

"""
    parameter_names

Return names of the parameters of a given object
"""
function parameter_names end
