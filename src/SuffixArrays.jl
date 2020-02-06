module SuffixArrays

export suffixsort

const CodeUnits = Union{UInt8,UInt16}
const IndexTypes = Union{Int8,Int16,Int32,Int64}
const IndexVector = AbstractVector{<:IndexTypes}

include("sais.jl")

function suffixsort(V::AbstractVector{U}, base::Integer=1) where {U<:CodeUnits}
    0 ≤ base || throw(ArgumentError("unsupported negative indexing base: $base"))
    n = length(V)
    # unsigned index type to return
    T = n+base-1 ≤ typemax(UInt8)  ? UInt8  :
        n+base-1 ≤ typemax(UInt16) ? UInt16 :
        n+base-1 ≤ typemax(UInt32) ? UInt32 : UInt64
    n ≤ 1 && return fill(T(base), n)
    # signed index type for algorithm
    S = n ≤ typemax(Int8)  ? Int8  :
        n ≤ typemax(Int16) ? Int16 :
        n ≤ typemax(Int32) ? Int32 : Int64
    if sizeof(T) == sizeof(S)
        I = zeros(T, n)
        sais(V, reinterpret(S, I), 0, n, Int(typemax(U))+1, false)
        base ≠ 0 && (I .+= base)
        return I
    else
        I = zeros(S, n)
        sais(V, I, 0, n, Int(typemax(U))+1, false)
        I′ = Vector{T}(undef, n)
        @inbounds for (i, x) in enumerate(I)
            I′[i] = (x + base) % T
        end
        return I′
    end
end

function suffixsort(s::AbstractString, base::Integer=1)
    return suffixsort(codeunits(s), base)
end

end # module
