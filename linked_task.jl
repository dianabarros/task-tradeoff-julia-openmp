using Base.Threads
using BenchmarkTools

const N = 30
const FS = 10

mutable struct Node
    data::Int64
    fibdata::Int64
    next::Union{Node, Nothing}
end

function fib(n::Int64)
    if n < 2
        return n
    else
        x = fib(n - 1)
        y = fib(n - 2)
        return x + y
    end
end

function processwork(p::Node)
    p.fibdata = fib(p.data)
end
    
function init_list()
    head = Node(FS, 1, nothing)
    tmp = head
    for i in 1:N-1
        node = Node(FS + i, i, nothing)
        tmp.next = node
        tmp = node
    end
    return head
end

function linked_task()
    p = init_list()
    vec_aux = Array{Node,1}(undef,N)
    for i in 1:N
        vec_aux[i] = p
        p = p.next
    end
    benchmarks = @benchmark begin
        @sync for i in 1:N
            Threads.@spawn processwork($vec_aux[i])
        end
    end
end