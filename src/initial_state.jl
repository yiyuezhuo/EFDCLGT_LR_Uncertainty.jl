
struct LowRankMatNormal{T}
    mu::Matrix{T}
    mat_vec::Vector{Matrix{T}}
end

function Base.rand(dist::LowRankMatNormal)
    return dist.mu + sum(randn(length(dist.mat_vec)) .* dist.mat_vec)
end

Base.rand(dist::LowRankMatNormal, n::Int) = [rand(dist) for _ in 1:n]


function fit(::Type{LowRankMatNormal}, template::AbstractSimulationTemplate, day_limit=Day(typemax(Int)))
    replacer = set_sim_length!(Replacer(template, [efdc_inp]), Day(1))

    collector = Collector(replacer, [wqini_inp, WQWCRST_OUT])
    collector_vec = Collector[collector]

    day_end = min(get_total_length(Day, template), day_limit)
    
    ProgressMeter.@showprogress for _ in Day(1):Day(1):day_end
        collector = Collector{Restarter}(collector)
        push!(collector_vec, collector)
    end

    wqini_df_vec = map(collector_vec[1:end-1]) do collector
        collector[wqini_inp].df
    end
    WQWCRST_OUT_df_vec = map(collector_vec[1:end-1]) do collector
        collector[WQWCRST_OUT].df
    end
    
    for idx in 2:length(wqini_df_vec)
        @assert wqini_df_vec[idx] == WQWCRST_OUT_df_vec[idx-1]
    end

    df_vec = [wqini_df_vec; WQWCRST_OUT_df_vec[end]]
    idx_vec= findall(std(reduce(vcat, Matrix.(df_vec)), dims=1)[1, :] .> 0)
    name_vec = names(df_vec[1])[idx_vec][4:end] # drop std=0 and IJK index

    @info "drop index $(setdiff(Set(names(df_vec[1])), Set(name_vec)))"

    log_matrix_vec = map(df_vec) do df
        return log.(Matrix(df[!, name_vec]))
    end

    diff_log_matrix_vec = log_matrix_vec[2:end] - log_matrix_vec[1:end-1]
    mean_diff_log_matrix_vec = mean(diff_log_matrix_vec)

    uncentered_diff_log_matrix_vec = [mat - mean_diff_log_matrix_vec for mat in diff_log_matrix_vec]

    return LowRankMatNormal(mean_diff_log_matrix_vec, uncentered_diff_log_matrix_vec), name_vec
end

struct PositiveDataFrameDisturber{T}
    dist::LowRankMatNormal
    coef::T
    name_vec::Vector{String}
end

Base.broadcastable(pdfd::PositiveDataFrameDisturber) = Ref(pdfd) 

function cond_rand!(dst_df::AbstractDataFrame, pdfd::PositiveDataFrameDisturber, df::AbstractDataFrame)
    sub_mat = exp.(log.(Matrix(df[!, pdfd.name_vec])) + rand(pdfd.dist) * pdfd.coef)
    for (idx, col_name) in enumerate(pdfd.name_vec)
        dst_df[!, col_name] = sub_mat[:, idx]
    end
end

function cond_rand(pdfd::PositiveDataFrameDisturber, df::AbstractDataFrame)
    df_ret = deepcopy(df)
    cond_rand!(df_ret, pdfd, df)
    return df_ret
end

function save(io, pdfd::PositiveDataFrameDisturber)
    bson(io, mu=pdfd.dist.mu, mat_vec=pdfd.dist.mat_vec, coef=pdfd.coef, name_vec=pdfd.name_vec)
end

function load(io, ::Type{PositiveDataFrameDisturber})
    rd = BSON.load(io)
    name_vec = Vector{String}(rd[:name_vec])  # BSON save Vector{String} as Vector{Any}
    mat_vec = Vector{typeof(rd[:mat_vec][1])}(rd[:mat_vec])  # BSON save Vector{Matrix} as Vector{Any}
    dist = LowRankMatNormal(rd[:mu], mat_vec)
    return PositiveDataFrameDisturber(dist, rd[:coef], name_vec)
end
