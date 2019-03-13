#=
 * sais
 * Copyright (c) 2008-2010 Yuta Mori All Rights Reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 =#

#= Suffixsorting =#
mutable struct IntArray
    a::Array{Int,1}
    pos::Int
end
import Base: getindex, setindex!
getindex(a::IntArray,key) = a.a[a.pos + Int(key)]
setindex!(a::IntArray,value,key) = a.a[a.pos + Int(key)] = value

# "banana" = [5 3 1 0 4 2]
# "banana" = [6, 4, 2, 1, 5, 3]

#TODO
 #refactor code to simplify
 #build user interface for string operations

function getcounts(T,C,n,k)
    for i = 1:k
        C[i] = 0
    end
    for i = 1:n
        C[Int(T[i])+1] += 1
    end
end

function getbuckets(C,B,k,isend)
    sum = 0
    if isend != false
        for i = 1:k
            sum += C[i]
            B[i] = sum
        end
    else
        for i = 1:k
            sum += C[i]
            B[i] = sum - C[i]
        end
    end
end

function sais(T, SA, fs, n, k, isbwt)
    pidx = 0
    flags = 0
    if k <= 256
        C = IntArray(zeros(Int,k),0)
        if k <= fs
            B = IntArray(SA,n + fs - k)
            flags = 1
        else
            B = IntArray(zeros(Int,k),0)
            flags = 3
        end
    elseif k <= fs
        C = IntArray(SA,n + fs - k)
        if k <= fs - k
            B = IntArray(SA,n + fs - 2k)
            flags = 0
        elseif k <= 1024
            B = IntArray(zeros(Int,k),0)
            flags = 2
        else
            B = C
            flags = 8
        end
    else
        C = B = IntArray(zeros(Int,k),0)
        flags = 4 | 8
    end
    # stage 1
    getcounts(T,C,n,k)
    getbuckets(C,B,k,true)
    for i = 1:n
        SA[i] = 0
    end
    b = -1
    i = j = n
    m = 0
    c0 = c1 = T[n]
    i -= 1
    while 1 <= i && ((c0 = T[i]) >= c1)
        c1 = c0
        i -= 1
    end
    while 1 <= i
        c1 = c0
        i -= 1
        while 1 <= i && ((c0 = T[i]) <= c1)
            c1 = c0
            i -= 1
        end
        if 1 <= i
            0 <= b && (SA[b+1] = j)
            b = (B[Int(c1)+1] -= 1)
            j = i-1
            m += 1
            c1 = c0
            i -= 1
            while 1 <= i && ((c0 = T[i]) >= c1)
                c1 = c0
                i -= 1
            end
        end
    end
    if 1 < m
        LMSsort(T,SA,C,B,n,k)
        name = LMSpostproc(T,SA,n,m)
    elseif m == 1
        SA[b+1] = j+1
        name = 1
    else
        name = 0
    end
    # stage 2
    if name < m
        newfs = n + fs - 2m
        if flags & (1 | 4 | 8) == 0
            if (k + name) <= newfs
                newfs -= k
            else
                flags |= 8
            end
        end
        j = 2m + newfs
        for i = (m + (n >> 1)):-1:(m+1)
            if SA[i] != 0
                SA[j] = SA[i] - 1
                j -= 1
            end
        end
        RA = IntArray(SA, m + newfs)
        sais(RA,SA,newfs,m,name,false)

        i = n
        j = 2m
        c0 = c1 = T[n]
        while 1 <= (i -= 1) && ((c0 = T[i]) >= c1)
            c1 = c0
        end
        while 1 <= i
            c1 = c0
            while 1 <= (i -= 1) && ((c0 = T[i]) <= c1)
                c1 = c0
            end
            if 1 <= i
                SA[j] = i
                j -= 1
                c1 = c0
                while 1 <= (i -= 1) && ((c0 = T[i]) >= c1)
                    c1 = c0
                end
            end
        end
        for i = 1:m
            SA[i] = SA[m+SA[i]+1]
        end
        if flags & 4 != 0
            C = B = IntArray(zeros(Int,k),0)
        end
        if flags & 2 != 0
            B = IntArray(zeros(Int,k),0)
        end
    end
    # stage 3
    flags & 8 != 0 && getcounts(T,C,n,k)
    if 1 < m
        getbuckets(C,B,k,true)
        i = m-1
        j = n
        p = SA[m]
        c1 = T[p+1]
        while true
            c0 = c1
            q = B[Int(c0)+1]
            while q < j
                j -= 1
                SA[j+1] = 0
            end
            while true
                j -= 1
                SA[j+1] = p
                i -= 1
                i < 0 && break
                p = SA[i+1]
                c1 = T[p+1]
                c1 != c0 && break
            end
            i < 0 && break
        end
        while 0 < j
            j -= 1
            SA[j+1] = 0
        end
    end
    if isbwt == false
        induceSA(T,SA,C,B,n,k)
    else
        pidx = computeBWT(T,SA,C,B,n,k)
    end
    return SA
end

function LMSsort(T, SA, C, B, n, k)
    C == B && getcounts(T,C,n,k)
    getbuckets(C,B,k,false)
    j = n - 1
    c1 = T[j+1]
    b = B[Int(c1)+1]
    j -= 1
    SA[b+1] = T[j+1] < c1 ? ~j : j
    b += 1
    for i = 1:n
        if 0 < (j = SA[i])
            if (c0 = T[j+1]) != c1
                B[Int(c1)+1] = b
                c1 = c0
                b = B[Int(c1)+1]
            end
            j -= 1
            SA[b+1] = T[j+1] < c1 ? ~j : j
            b += 1
            SA[i] = 0
        elseif j < 0
            SA[i] = ~j
        end
    end
    C == B && getcounts(T,C,n,k)
    getbuckets(C,B,k,true)
    c1 = 0
    b = B[c1+1]
    for i = n:-1:1
        if 0 < (j = SA[i])
            c0 = T[j+1]
            if Int(c0) != Int(c1)
                B[c1+1] = b
                c1 = c0
                b = B[Int(c1)+1]
            end
            j -= 1
            b -= 1
            SA[b+1] = T[j+1] > c1 ? ~(j+1) : j
            SA[i] = 0
        end
    end
end

function LMSpostproc(T,SA,n,m)
    i = 1
    while (p = SA[i]) < 0
        SA[i] = ~p
        i += 1
    end
    if i-1 < m
        j = i
        i += 1
        while true
            if (p = SA[i]) < 0
                SA[j] = ~p
                j += 1
                SA[i] = 0
                j-1 == m && break
            end
            i += 1
        end
    end

    i = j = n
    c0 = c1 = T[n]
    while 1 <= (i -= 1) && ((c0 = T[i]) >= c1)
        c1 = c0
    end
    while 1 <= i
        c1 = c0
        while 1 <= (i -= 1) && ((c0 = T[i]) <= c1)
            c1 = c0
        end
        if 1 <= i
            SA[m + (i >> 1) + 1] = j - i
            j = i + 1
            c1 = c0
            while 1 <= (i -= 1) && ((c0 = T[i]) >= c1)
                c1 = c0
            end
        end
    end
    name = 0
    q = n
    qlen = 0
    for i = 1:m
        p = SA[i]
        plen = SA[m + (p >> 1) + 1]
        diff = true
        if plen == qlen && (q + plen < n)
            j = 0
            while j < plen && T[p+j+1] == T[q+j+1]
                j += 1
            end
            j == plen && (diff = false)
        end
        if diff != false
            name += 1
            q = p
            qlen = plen
        end
        SA[m + (p >> 1) + 1] = name
    end
    return name
end

function induceSA(T,SA,C,B,n,k)
    C == B && getcounts(T,C,n,k)
    getbuckets(C,B,k,false)
    j = n - 1
    c1 = T[j+1]
    b = B[Int(c1)+1]
    SA[b+1] = 0 < j && T[j] < c1 ? ~j : j
    b += 1
    for i = 1:n
        j = SA[i]
        SA[i] = ~j
        if 0 < j
            j -= 1
            if (c0 = T[j+1]) != c1
                B[Int(c1)+1] = b
                c1 = c0
                b = B[Int(c1)+1]
            end
            SA[b+1] = 0 < j && T[j] < c1 ? ~j : j
            b += 1
        end
    end
    C == B && getcounts(T,C,n,k)
    getbuckets(C,B,k,true)
    c1 = 0
    b = B[c1+1]
    for i = n:-1:1
        if 0 < (j = SA[i])
            j -= 1
            c0 = T[j+1]
            if Int(c0) != Int(c1)
                B[Int(c1)+1] = b
                c1 = c0
                b = B[Int(c1)+1]
            end
            b -= 1
            SA[b+1] = j == 0 || T[j] > c1 ? ~j : j
        else
            SA[i] = ~j
        end
    end
end

function computeBWT(T,SA,C,B,n,k)
    pidx = -1
    C == B && getcounts(T,C,n,k)
    getbuckets(C,B,k,false)
    j = n-1
    c1 = T[j+1]
    b = B[Int(c1)+1]
    SA[b+1] = 0 < j && T[j] < c1 ? ~j : j
    b += 1
    for i = 1:n   
        if 0 < (j = SA[i])
            j -= 1
            c0 = T[j+1]
            SA[i] = ~c0
            if c0 != c1
                B[Int(c1)+1] = b
                c1 = c0
                b = B[c1+1]
            end
            SA[b+1] = 0 < j && T[j] < c1 ? ~j : j
            b += 1
        elseif j != 0
            SA[i] = ~j
        end
    end
    C == B && getcounts(T,C,n,k)
    getbuckets(C,B,k,true)
    c1 = 0
    b = B[Int(c1)+1]
    for i = n:-1:1
        if 0 < (j = SA[i])
            j -= 1
            c0 = T[j+1]
            SA[i] = c0
            if c0 != c1
                B[Int(c1)+1] = b
                c1 = c0
                b = B[Int(c1)+1]
            end
            b -= 1
            SA[b+1] = 0 < j && T[j] > c1 ? ~(T[j]) : j
        elseif j != 0
            SA[i] = ~j
        else
            pidx = i-1
        end
    end
    return pidx
end
