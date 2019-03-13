module SuffixArrays

export suffixsort

struct SuffixArray{S<:AbstractString,N<:Signed}
    string::S
    n::Int
    index::Array{N,1}
end

function SuffixArray(s::S) where S <: AbstractString
    n = length(s)
    index = zeros(n <= typemax(Int8)  ? Int8  : 
                  n <= typemax(Int16) ? Int16 : 
                  n <= typemax(Int32) ? Int32 : Int64, n)
    return SuffixArray(s,n,index)
end

include("sais.jl")

function suffixsort(s)
    isempty(s) && return SA
    SA = SuffixArray(s)
    SA.n <= 1 && return SA
    SuffixArrays.sais(s, SA.index, 0, SA.n, isascii(s) ? 256 : 65536, false)
    return SA
end


#=contains(haystack, needle)

matchall(substring, s::String)=#
const MAXCHAR = Char(255)

function lcp2(SA,s)
    inv = similar(SA)
    lcparr = similar(SA)
    n = length(SA)
    for i = 1:n
        inv[SA[i]+1] = i-1
    end
    m = 0
    for i = 1:n
        if inv[i] > 0
            j = SA[inv[i]]
            while s[m+i] == s[m+j+1]
                m += 1
            end
            lcparr[inv[i]+1] = m
            m > 0 && (m-=1)
        end
    end
    lcparr[1] = -1
    return lcparr
end

end # module
