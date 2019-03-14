using SuffixArrays
using Test

readstring(s) = read(s, String) 

function test_suffix(args)
    for file in args
        T = open(readstring,file)
        t = @elapsed SA = suffixsort(T)
        println("Sorting '$file' took: $t")
        @test sufcheck(T,SA.index) == 0
    end
end

function sufcheck(T,SA)
    n = length(T)
    n == 0 && (println("Done."); return 0)
    n < 0 && (println("Invalid length $n"); return -1)
    C = zeros(Int,256)
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
            p = n-1
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

function walkdir(dir,files)
    t = readdir(dir)
    for f in t
        f == ".git" && continue
        j = joinpath(dir,f)
        if isdir(j)
            append!(files,walkdir(j,files))
        else
            push!(files,j)
        end
    end
    return unique(files)
end

files = initwalk(dirname(dirname(@__FILE__)),[])
test_suffix(files)
