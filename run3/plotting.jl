using DataFrames, CSV, VegaLite, Statistics

run_ = "run3"

c_df = DataFrame(CSV.File("$(run_)/c_executions_t2.csv"))
julia_df = DataFrame(CSV.File("$(run_)/julia_executions_t2.csv"))
i = 4
while i <= 16
    c_df = vcat(c_df, DataFrame(CSV.File("$(run_)/c_executions_t$(i).csv")))
    julia_df = vcat(julia_df, DataFrame(CSV.File("$(run_)/julia_executions_t$(i).csv")))
    i = i*2
end

input_sizes = Dict(
    1000 => "Small",
    10000 => "Medium",
    100000 => "Large"
)

c_df[:, "input"] = [input_sizes[val] for val in c_df.size]
julia_df[:, "input"] = [input_sizes[val] for val in julia_df.size]

julia_gb = groupby(julia_df, [:func, :size, :input, :n_threads])
julia_df = combine(julia_gb, 
    [:total_time, :imbalance] .=>  mean, [:total_time, :imbalance] .=> std)
julia_df = rename(julia_df, Dict(:total_time_mean => :total_time, :imbalance_mean => :imbalance))
julia_df = julia_df[:, [:func, :size, :n_threads, :total_time, :imbalance, :input]]

julia_funcs = Dict(
    "linked" => "Julia Sequential",
    "linked_for" => "Julia - @threads",
    "linked_task" => "Julia - @spawn"
)
c_funcs = Dict(
    "linked" => "C Sequential",
    "linked_for" => "C - OpenMP Parallel For",
    "linked_task" => "C - OpenMP Task"
)

c_df[:, :func2] = [c_funcs[func] for func in c_df.func]
julia_df[:, :func2] = [julia_funcs[func] for func in julia_df.func]
c_df = c_df[:, [:func2, :size, :n_threads, :total_time, :imbalance, :input]]
c_df = rename(c_df, Dict(:func2=> :func))
julia_df = julia_df[:, [:func2, :size, :n_threads, :total_time, :imbalance, :input]]
julia_df = rename(julia_df, Dict(:func2=> :func))

imbalance_df = vcat(c_df, julia_df)
imbalance_df = imbalance_df[imbalance_df.func .!= c_funcs["linked"], :]
imbalance_df = imbalance_df[imbalance_df.func .!= julia_funcs["linked"], :]

c_seq = c_df[c_df.func .== c_funcs["linked"], :]
julia_seq = julia_df[julia_df.func .== julia_funcs["linked"], :]
c_parallel = vcat(c_df[c_df.func .== c_funcs["linked_for"], :], c_df[c_df.func .== c_funcs["linked_task"], :])
julia_parallel = vcat(julia_df[julia_df.func .== julia_funcs["linked_for"], :], julia_df[julia_df.func .== julia_funcs["linked_task"], :])

c_parallel_seq_df = innerjoin(c_parallel, c_seq, on=[:size, :input, :n_threads], renamecols="_parallel" => "_seq")
julia_parallel_seq_df = innerjoin(julia_parallel, julia_seq, on=[:size, :input, :n_threads], renamecols="_parallel" => "_seq")

c_parallel_seq_df = hcat(c_parallel_seq_df, DataFrame(speedup=Vector{Union{Missing,Float64}}(missing, size(c_parallel_seq_df, 1))))
julia_parallel_seq_df = hcat(julia_parallel_seq_df, DataFrame(speedup=Vector{Union{Missing,Float64}}(missing, size(julia_parallel_seq_df, 1))))

c_speedup_df = select(c_parallel_seq_df, :, 
[:total_time_parallel, :total_time_seq] => ((total_time_parallel, total_time_seq) -> (total_time_seq ./ total_time_parallel)) => :speedup)
julia_speedup_df = select(julia_parallel_seq_df, :, 
[:total_time_parallel, :total_time_seq] => ((total_time_parallel, total_time_seq) -> (total_time_seq ./ total_time_parallel)) => :speedup)

df = vcat(c_speedup_df, julia_speedup_df)

speedup_plot = df |>
    @vlplot(
        mark={:line, clip=true},
        x={"n_threads:q", axis={title="Number of Threads"}},
        y={:speedup, axis={title="Speedup"}},
        color={:func_parallel, axis={title="Parallel Implementation"}},
        column={
            :input, axis={title="Input size"},
            sort={field=:input,order=:descending} 
        },
        # row={
        #     :input, axis={title="Input Size"},
        #     sort={field=:input,order=:descending}    
        # }
        width=165
    )

speedup_plot |> save("$(run_)/speedup_plot.png")

imbalance_plot = imbalance_df |>
    @vlplot(
        mark={:line, clip=true},
        x={"n_threads:q", axis={title="Number of Threads"}},
        y={"imbalance:q", axis={title="λ (%)"}},
        color={:func, axis={title="Parallel Implementation"}, scale={domain=["C - OpenMP Parallel For","C - OpenMP Task","Julia - @threads","Julia - @spawn"]}},
        column={
            "input:n", 
            axis={title="Input size"},
            sort=["Small", "Medium, Large"]
        },
        width=165
    )
imbalance_plot |> save("$(run_)/imbalance_plot.png")