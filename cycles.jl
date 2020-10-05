# MIT License

# Copyright (c) 2020 Makoto Suwama

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Code used to compute cycles coming from the sum of squares of digits in base b for the paper Integer Dynamics with Dino Lorenzini, Mentzelos Melistas, Arvind Suresh and Haiyang Wang
# For example, to check in base b, all cycles starting at x+b*y with low<= y <= high, run
# julia cycles.jl low high b
# May need to change the data type of b from UInt32 to other type depending on how large the b is
# Also see correctness.pdf for the correctness of the code.

const numCycles=3;

# Parameters parsed from the command line
low = parse(Int, ARGS[1]);
high = parse(Int, ARGS[2]);
const b = parse(Int, ARGS[3]);

# Directory to save the files
directory = "";
output = directory * "spTestJ" * string(b) * "-" * string(low) * "-" * string(high) * ".txt";

# check a number d has been seen already
# seen is an array of arrays of sets and a number n = d1 + d2*b + d3*b^2 is stored as d1 in seen[d3+1][d2+1]
function isSeen(seen,d)
    return d[1] in seen[d[3]+1][d[2]+1];
end;
# add number d to seen
# seen is an array of arrays of sets and a number n = d1 + d2*b + d3*b^2 is stored as d1 in seen[d3+1][d2+1]
function addSeen!(seen,d)
    push!(seen[d[3]+1][d[2]+1], d[1])
end;
# replaces d with [x,y,0]
function createD!(d,x,y)
    d[1] = x;
    d[2] = y;
    d[3] = 0;
end
# Checks if max(d[1],d[2]) + min(d[1],d[2])*b + d[2]*b^2 is smaller than x+b*y
# Uses separate comparison for speed purpose
function isSmaller(d,x,y)
    return d[3] == 0 && (min(d[1],d[2]) < y || (min(d[1],d[2])==y && max(d[1],d[2]) < x))
end

# start the sum of the square procedure until it hits a cycle or a number already seen
# Returns True if it finds a new cycle
function traverse(x,y,d,seen,cycles,L)
    # if the number already appeared then skip it
    if x in seen[1][y+1]
        return false
    end;
    n = x+b*y;
    
    # pops L until it is empty and adds n
    # this is faster than L = [n]
    while length(L) > 0
        pop!(L);
    end;
    push!(L,n);
    while !(isSeen(seen,d))
        addSeen!(seen,d)
        n = sum(i^2 for i in d);
        push!(L,n)
        digits!(d, n,base = b)
        # if d is less than x+b*y then we have seen it already
        if isSmaller(d,x,y)
            return false
        end
    end
    # find the position of n in L
    # if n is in L and not the last then there is a cycle starting at the first appearance of n
    p = findfirst(isequal(n),L);
    if p != nothing && p < length(L)
        push!(cycles, L[p:length(L)-1])
        return true
    end
    return false
end

# Check all the numbers x+b*y with low<=y<=high
function checkYInterval(low, high, seen, cycles)
    d=Array{UInt64}(undef,3)
    L=[];
    for y=low:high
        # Check if the progress needs to be printed
        if y % interval == 0
            println(y, " ", time()-t0)
            flush(stdout)
        end
        # See correctness.pdf for the upper bound on x
        for x=max(y,ceil(Int, sqrt(y*b-y^2+1/4)+1/2)):b-1
            createD!(d,x,y)
            if traverse(x,y,d,seen,cycles,L)
                #if length(cycles) >= numCycles
                #    return nothing
                #end
            end
        end
        # delete unncessary seen to save memory. Boolean is chosen to save space
        seen[1][y+1] = Set{Bool}()
    end
end 

# Adds a cycle starting at ini
function addKnownCycle(seen, cycles, ini, d)
    c = [];
    while true
        digits!(d,ini,base = b)
        if isSeen(seen, d)
            push!(cycles, c)
            return
        end
        addSeen!(seen,d)
        push!(c, ini)
        ini = sum(i^2 for i in d)
    end
end


# Initialise the variables
# interval is used to determine how often should we print progress
const t0 = time();
const interval =  10^ceil(Int,log(10,(high-low)/100));

# b is UInt32
# indexing is off by 1
# if n = [a,b,c] then check if a is in seen[c+1][b+1]
# keeps track of [a,b,c] where a>=b and c=0 or 1
seen = [[ Set{UInt32}() for i=1:b], [Set{UInt32}() for i=1:b]];
cycles = [[1]];
push!(seen[1][1],1);
d=Array{UInt64}(undef,3);

addKnownCycle(seen, cycles, 91610640434,d);

checkYInterval(low, high, seen, cycles)

io = open(output,"w");
println(io, b);
println(io, [length(c) for c in cycles]);
println(io, [c[1] for c in cycles]);
flush(io);
close(io);
