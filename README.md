# SuffixArrays

[![Build Status](https://travis-ci.org/quinnj/SuffixArrays.jl.svg?branch=master)](https://travis-ci.org/quinnj/SuffixArrays.jl)

A Julia interface to working with [Suffix Arrays](http://en.wikipedia.org/wiki/Suffix_array). The underlying suffix array sorting implementation is a pure Julia port of [sais](https://sites.google.com/site/yuta256/sais), by Yuta Mori.

You can use the package by running:
```julia
using Pkg
add("SuffixArrays")
#Pkg.add("SuffixArrays") for julia prior to v0.7
using SuffixArrays
sa = suffixsort("banana")
sa.index # access the underlying sorted suffix array; returned indices are currently 0-based
```

This package is brand new (8/2/2014) and will probably go through some more iterating, but performance is already impressive being 10x faster than the Java `sais` implementation and about 1.3x slower than the native C version.

Convenient interface features are being planned to aid in doing fast substring search and other suffix array tricks. I'd also like to explore extensions to the core algorithm to leverage Julia's distributed arrays, parallelization, and UTF8/16/32 string handling capabilties.

As always, bugs and requests are more than welcome and can be submitted through the [github issue tracker](https://github.com/quinnj/SuffixArrays.jl/issues).
