"""
    FirstPassageAbstract

Types ihneriting from this struct define the type of information stored about
first-passage times
"""
abstract type FirstPassageAbstract end

"""
    NoFirstPassageTimes <: FirstPassageAbstract

Compile-time indicator that the observation stores no first-passage time data
"""
struct NoFirstPassageTimes <: FirstPassageAbstract end

"""
    FirstPassageTimeInfo{C,L,U,A,R} <: FirstPassageAbstract

Compile-time indicator for the first-passage time information conveyed by the
data-point. `C` lists the affected coordinates (of the observations, not the
process), `L` indicates the level, `U` are indicators for whether the respective
first-passage times are up-crossings and `A` is and indicator for whether
an additional reset needs to be reached before first-passage time (note that
reset time is defined as a first-passage time to a corresponding reset level
stored in `R` that happens anytime before the actual first-passage time,
the reset-time happens in the direction opposite to the direction of
first-passage time crossing; additionally, the coordinate can reach the
first-passage time level prior to being reset).

    FirstPassageTimeInfo(
        coords,
        levels,
        upcrossings,
        additional_reset_required,
        reset_levels=tuple()
    )

Base constructor.
"""
struct FirstPassageTimeInfo{C,L,U,A,R} <: FirstPassageAbstract

    FirstPassageTimeInfo{C,L,U,A,R}() where {C,L,U,A,R} = new{C,L,U,A,R}()

    function FirstPassageTimeInfo(
            coords,
            levels,
            upcrossings,
            additional_reset_required,
            reset_levels=tuple()
        )
        N = length(coords)
        @assert length(levels) == length(upcrossings) == N
        @assert length(additional_reset_required) == N
        @assert all( map(c->(typeof(c)<:Integer), coords) )
        @assert all( map(l->(typeof(l)<:AbstractFloat), levels) )
        @assert all( map(u->(typeof(u)==Bool), upcrossings) )
        @assert all( map(a->(typeof(a)==Bool), additional_reset_required) )
        C, L, U = Tuple(coords), Tuple(levels), Tuple(upcrossings)
        A = Tuple(additional_reset_required)

        M = length(reset_levels)
        any(A) && @assert (M == N || M == sum(A))
        R_vec = Union{Float64,Nothing}[]
        if M == N
            # just to keep with the convention
            for i in 1:N
                A[i] && push!(R_vec, reset_levels[i])
                !A[i] && push!(R_vec, nothing)
            end
        else
            counter = 1
            for i in 1:N
                A[i] && (push!(R_vec, reset_levels[counter]); counter += 1)
                !A[i] && push!(R_vec, nothing) # this is never used
            end
        end
        R = Tuple(R_vec)

        new{C,L,U,A,R}()
    end
end

strip_fpt_info(::Type{FirstPassageTimeInfo{C,L,U,A,R}}) where {C,L,U,A,R} = (C,L,U,A,R)

cpad(s, n) = cpad(string(s), n)

function cpad(s::String, n::Integer)
    rpad_n = div(max(0, n-length(s)), 2)+length(s)
    lpad(reverse(lpad(reverse(s), rpad_n)),n)
end

Base.summary(io::IO, fpt::Type{<:FirstPassageTimeInfo}) = _summary_fpt(io, fpt)
Base.summary(fpt::Type{<:FirstPassageTimeInfo}) = summary(Base.stdout, fpt)


function _summary_fpt(io::IO, ::Type{NoFirstPassageTimes}; prepend="")
    println(io, prepend, "No first passage times recorded.")
end

function _summary_fpt(io::IO, fpt; prepend="")
    (
        coords,
        levels,
        upcrossings,
        additional_reset_required,
        reset_levels
    ) = strip_fpt_info(fpt)
    pad_len = 14
    println(io, prepend, "First passage times of the observation `v`: ")
    println(io, prepend, repeat("-", pad_len*5+6))
    println(
        io,
        prepend,
        "|", cpad("coordinate", pad_len), "|", cpad("level", pad_len),
        "|", cpad("up-crossing", pad_len), "|", cpad("extra reset", pad_len),
        "|", cpad("reset level", pad_len), "|"
    )
    println(io, prepend, repeat("-", pad_len*5+6))
    for (coord, lev, upcross, addres, reslvl) in zip(strip_fpt_info(fpt)...)
        println(
            io,
            prepend,
            "|", cpad(coord, pad_len), "|", cpad(lev, pad_len),
            "|", cpad((upcross ? "up-crossing" : "down-crossing"), pad_len),
            "|", cpad((addres ? "✔" : "✘"), pad_len),
            "|", cpad((addres ? reslvl : "✘"), pad_len), "|"
        )
    end
end
