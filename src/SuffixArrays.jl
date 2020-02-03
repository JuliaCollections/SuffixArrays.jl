module SuffixArrays

export suffixsort

const CodeUnits = Union{UInt8,UInt16}
const IndexTypes = Union{Int8,Int16,Int32,Int64}
const IndexVector = Vector{<:IndexTypes}

include("sais.jl")

function suffixsort(V::AbstractVector{U}; offset::Integer=1) where {U<:CodeUnits}
    n = length(V)
    T = n ≤ typemax(Int8)  ? Int8  :
        n ≤ typemax(Int16) ? Int16 :
        n ≤ typemax(Int32) ? Int32 : Int64
    I = zeros(T, n)
    n ≤ 1 && return I
    sais(V, I, 0, n, Int(typemax(U))+1, false)
    offset ≠ 0 && (I .+= offset)
    return I
end

function suffixsort(s::AbstractString; offset::Integer=1)
    return suffixsort(codeunits(s), offset=offset)
end

end # module
