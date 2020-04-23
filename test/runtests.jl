using Test
using SuffixArrays

function test_suffix(args)
    for file in args
        data = codeunits(read(file, String))
        t = @elapsed suffixes = suffixsort(data, 0)
        println("Sorting '$file' took: $t")
        @test sufcheck(data, suffixes) == 0
    end
end

function sufcheck(T, SA)
    n = length(T)
    n == 0 && (println("Done."); return 0)
    n < 0 && (println("Invalid length $n"); return -1)
    C = zeros(Int, 256)
    for i = 1:n
        if SA[i] < 0 || n <= SA[i]
            println("Out of range $n")
            println("SA[$i] = $(SA[i])")
            return -2
        end
    end
    for i = 2:n
        if T[SA[i-1]+1] > T[SA[i]+1]
            println("Suffixes in wrong order")
            println("T[SA[$(i-1)]+1] = $(T[SA[(i-1)]+1])")
            println("T[SA[$i]+1] = $(T[SA[i]+1])")
            return -3
        end
    end
    for i = 1:n
        C[Int(T[i])+1] += 1
    end
    p = 0
    for i = 1:256
        t = C[i]
        C[i] = p
        p += t
    end
    q = C[Int(T[n])+1]
    C[Int(T[n])+1] += 1
    for i = 1:n
        p = SA[i]
        if 0 < p
            p -= 1
            c = T[p+1]
            t = C[Int(c)+1]
        else
            p = n - 1
            c = T[p+1]
            t = q
        end
        if t < 0 || p != SA[t+1]
            println("Suffixes in wrong position")
            return -4
        end
        if t != q
            C[Int(c)+1] += 1
            if n <= C[Int(c)+1] || T[SA[C[Int(c)+1]+1]+1] != c
                C[Int(c)+1] = -1
            end
        end
    end
    println("Done.")
    return 0
end

function initwalk(dir, files)
    files = walkdir("$dir/src", files)
    files = walkdir("$dir/test", files)
    files
end

function walkdir(dir, files)
    t = readdir(dir)
    for f in t
        f == ".git" && continue
        j = joinpath(dir, f)
        if isdir(j)
            append!(files, walkdir(j, files))
        else
            push!(files, j)
        end
    end
    return unique(files)
end

@testset "source files" begin
    files = initwalk(dirname(dirname(@__FILE__)), [])
    test_suffix(files)
end

@testset "UTF-8 strings" begin
    s = "¡Hello, 😄 world!"
    sa = suffixsort(s)
    suffixes = [String(codeunits(s)[i:end]) for i in sa]
    @test issorted(suffixes)
end

## define a simple UTF-16 string type ##

struct UTF16 <: AbstractString
    codeunits::Vector{UInt16}
end
UTF16(s::String) = UTF16(Base.transcode(UInt16, s))

Base.codeunits(s::UTF16) = s.codeunits
Base.ncodeunits(s::UTF16) = length(s.codeunits)
Base.isvalid(s::UTF16, i::Int) = isvalid(iterate(s, i)[1])
Base.isless(s::UTF16, t::UTF16) = s.codeunits < t.codeunits

function Base.iterate(s::UTF16, i::Int=1)
    i ≤ length(s.codeunits) || return
    u = s.codeunits[i]
    0xD800 ≤ u ≤ 0xDBFF || return Char(u), i+1
    # otherwise is a high surrogate
    v = s.codeunits[i+1]
    # not followed by low surrogate
    0xDC00 ≤ v ≤ 0xDFFF || return Char(u), i+1
    # u, v are high/low surrogate pair
    Char(0x10000 + (UInt32(u & 0x03ff) << 10) | (v & 0x03ff)), i+2
end

@testset "UTF-16 strings" begin
    s = UTF16("¡Hello, 😄 world!")
    sa = suffixsort(s)
    suffixes = [UTF16(codeunits(s)[i:end]) for i in sa]
    @test issorted(suffixes)
end

@testset "Issue #15 fix" begin
    s = join(rand('a':'z', 10000)) * '\$'
    sa = suffixsort(s)
    suffixes = [String(codeunits(s)[i:end]) for i in sa]
    @test issorted(suffixes)

    utext = rand(0x0001:0x0020, 4000)
    sa = suffixsort(utext)
    suffixes = [utext[i:end] for i in sa]
    @test issorted(suffixes)
end
