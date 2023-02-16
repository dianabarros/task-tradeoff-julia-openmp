using Pkg
Pkg.activate(".")

using Base.Threads
using BenchmarkTools, DataFrames, CSV, Dates, Statistics

const benchmark_samples = 10
const benchmark_evals = 1

function calculate_imbalance(times)
    mean_time = mean(times)
    maximum_time = maximum(times)
    λ = (maximum_time/mean_time - 1) * 100
    return λ
end

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

function fib_loop(n::Int64)
    n1 = 0
    n2 = 1
    count = 0
    if n > 1
        while count < n
            nth = n1 + n2
            n1 = n2
            n2 = nth
            count += 1
        end
    end
    return n1
end

function processwork(p::Node)
    p.fibdata = fib_loop(p.data)
end
    
function init_list(N::Int64, FS::Int64)
    head = Node(FS, 1, nothing)
    tmp = head
    for i in 1:N-1
        node = Node(FS + i*10, i, nothing)
        tmp.next = node
        tmp = node
    end
    return head
end

function print_list_for(vec_aux::Vector{Node}, N::Int64)
    for i in 1:N
        println("data: ", vec_aux[i].data, " - fibdata: ", vec_aux[i].fibdata)
    end
end

function for_loop(vec_aux::Vector{Node}, N::Int64, suite::Dict{T}) where T
    @threads for i in 1:N
        task_stats = @timed processwork(vec_aux[i])
        suite["task_time"][threadid()] += task_stats.time
    end
end

function linked_for(N::Int64, FS::Int64, suite::Dict{T}) where T
    p = init_list(N, FS)
    vec_aux = Array{Node,1}(undef,N)
    for i in 1:N
        vec_aux[i] = p
        p = p.next
    end
    # benchmarks = @benchmark for_loop($vec_aux, $N) samples=benchmark_samples evals=benchmark_evals
    time = (@timed for_loop(vec_aux, N, suite)).time
    suite["total_time"] = time
    #print_list_for(vec_aux, N)
    # return benchmarks
    return time
end

function print_list_tasks(p::Node)
    while !isnothing(p)
        println("data: ", p.data, " - fibdata: ", p.fibdata)
        p = p.next
    end
end

function task_loop(p::Node, suite::Dict{T}) where T
    tmp = p
    @sync while !isnothing(tmp)
        task_stats = @timed begin
            pp = tmp
            Threads.@spawn processwork(pp)
            tmp = tmp.next
        end
        suite["task_time"][threadid()] += task_stats.time
    end
end

function linked_task(N::Int64, FS::Int64, suite::Dict{T}) where T
    head = init_list(N, FS)
    p = head
    # benchmarks = @benchmark task_loop($p) samples=benchmark_samples evals=benchmark_evals
    time = (@timed task_loop(p, suite)).time
    suite["total_time"] = time
    p = head
    # print_list_tasks(p)
    # return benchmarks
    return time
end

function seq_loop(p::Node, suite::Dict{T}) where T
    while !isnothing(p)
        task_stats = @timed begin
            processwork(p)
            p = p.next
        end
        suite["task_time"][threadid()] += task_stats.time
    end
end

function linked(N::Int64, FS::Int64, suite::Dict{T}) where T
    head = init_list(N, FS)
    p = head
    # benchmarks = @benchmark seq_loop($p) samples=benchmark_samples evals=benchmark_evals
    time = (@timed seq_loop(p,suite)).time
    suite["total_time"] = time
    p = head
    # return benchmarks
    return time
end

function run_lists()
    sizes = [1000,10000,100000]
    fib_start = 50
    df = DataFrame(func=String[], size=Int64[], n_threads=Int64[], total_time=Float64[], imbalance=Float64[])
    funcs = [linked, linked_for, linked_task]
    for func in funcs
        for size in sizes
            println(now(), " - Running ", func, " function with size ", size)
            # exec_times = func(size, fib_start).times
            # mean_time = (sum(exec_times)/benchmark_samples)/1e9 #nano to seconds
            for _ in 1:benchmark_samples
                suite = Dict(
                    "total_time" => 0.0,
                    "task_time" => zeros(Float64, nthreads())
                )
                func(size, fib_start, suite)
                imbalance = calculate_imbalance(suite["task_time"])
                push!(df, (func=string(func), size=size, n_threads=nthreads(), total_time=suite["total_time"], imbalance=imbalance))
                CSV.write("julia_executions_t$(nthreads()).csv",df)
                println(now(), " - CSV written.")
            end
        end
    end
end

# df |>
#        @vlplot(
#            :bar,
#            x={"func:n", title="Scheduling", axis=false, sort=["Sequential", "Static", "Dynamic"]},
#            y={"time:q", scale={type="log",base=20}, axis={grid=false}, title="Time (s)"},
#            column={"size:n", title="Size",sort=["Small","Medium","Large"]},
#                config={
#                view={stroke=:transparent},
#                axis={domainWidth=1},
#            },
#            color={"func:n", title="Scheduling", scale={range=["#e7ba52","#1f77b4","#9467bd"]}, sort=["Sequential", "Static", "Dynamic"]}
#            )



# df |>
#               @vlplot(
#                   :bar,
#                   title={text="Linked List Execution Times", anchor="middle", fontSize=20},
#                   x={"func:n", title="Scheduling", axis=false, sort=["Static", "Dynamic"]},
#                   y={"time:q", scale={type="log",base=20}, axis={grid=false, titleFontSize=14}, title="Time (s)"},
#                   column={"size:n",
#                           title="Size",
#                           sort=["Small","Medium","Large"],
#                           header={labelOrient="bottom", titleOrient="bottom", titleFontSize=14, labelFontSize=12}
#                    },
#                   config={
#                       view={stroke=:transparent},
#                       axis={domainWidth=1},
#                   },
#                   color={"func:n",
#                          title="Scheduling",
#                          axis={titleFontSize=14},
#                          scale={range=["#e7ba52","#1f77b4","#9467bd"]},
#                          sort=["Static", "Dynamic"],
#                          legend={titleFontSize=14,
#                                  labelFontSize=12
#                          }
#                    },
#                   width=70,
#                   height=190
#                   )
run_lists()