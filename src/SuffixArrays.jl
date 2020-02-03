module SuffixArrays

export suffixsort

include("sais.jl")

function suffixsort(V::AbstractVector{UInt8}; offset::Integer=1)
    n = length(V)
    T = n ≤ typemax(Int8)  ? Int8  :
        n ≤ typemax(Int16) ? Int16 :
        n ≤ typemax(Int32) ? Int32 : Int64
    I = zeros(T, n)
    n ≤ 1 && return I
    sais(V, I, 0, n, 256, false)
    offset ≠ 0 && (I .+= offset)
    return I
end

function suffixsort(s::Union{String,SubString{String}}; offset::Integer=1)
    return suffixsort(codeunits(s), offset=offset)
end

end # module
