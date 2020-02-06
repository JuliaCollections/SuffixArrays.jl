# SuffixArrays

[![Build Status](https://travis-ci.org/JuliaCollections/SuffixArrays.jl.svg?branch=master)](https://travis-ci.org/JuliaCollections/SuffixArrays.jl)

A Julia package for computing [Suffix Arrays](http://en.wikipedia.org/wiki/Suffix_array).
The underlying suffix array sorting implementation is a pure Julia port of [sais](https://sites.google.com/site/yuta256/sais), by Yuta Mori.

You can use the package by running:
```julia
julia> using SuffixArrays
julia> s = "banana"
"banana"

julia> sa = suffixsort(s)
6-element Array{UInt8,1}:
 0x06
 0x04
 0x02
 0x01
 0x05
 0x03

julia> [s[i:end] for i in sa]
6-element Array{String,1}:
 "a"
 "ana"
 "anana"
 "banana"
 "na"
 "nana"

julia> issorted(ans)
true
```

The `suffixsort` function can compute a suffix array for vectors of `UInt8` or `UInt16` values, or for strings with code units that are one of these two types.
When generating a suffix array for a string, the suffix indices are in terms of code units, not characters, which means that some indices will be into the middle of characters that span multiple code units.
For UTF-8 and UTF-16 this doesn't affect using the suffix array as search index since a valid substring cannot start in the middle of a character anyway.
In other words, invalid substrings occuring in the suffix array will simply not match.

By default, `suffixsort(v)` produces an array of 1-based indices, but it can be called as `suffixsort(v, 2)` in order to produce an array of 0-based indices, which may be desirable to interface with 0-based libraries (or to save a tiny bit of space).
