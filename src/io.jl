
# Call EFDCLGT_LR_Files to create some files. It may be better to proceed as script, but Julia...

function random_push!(qser_tad::Dict{Tuple{String, Int}, DateDataFrame}, wqpsc_tad::Dict{String, DateDataFrame}, λ, σ)
    ts = timestamp(first(values(qser_tad)))
    interp = random_push_interpolation(length(ts), λ, σ)
    for (key, ta) in qser_tad
        for na in names(ta)
            ta[!, na] .= interp(ta[!, na].df)
        end
    end
    for (key, ta) in wqpsc_tad
        for na in names(ta)
            ta[!, na] .= interp(ta[!, na].df)
        end
    end
    return qser_tad, wqpsc_tad
end

"""
This function is expected to called from REPL by end user, the default argument is just taken to show.
"""
function random_push(dst_root::String = ENV["WATER_UPSTREAM"],
                    n::Int=10,
                    λ=1/24,
                    σ=2,
                    template::AbstractSimulationTemplate = SimulationTemplate(ENV["WATER_ROOT"], Day, Hour, [qser_inp, wqpsc_inp]),
                    base_qser_inp::qser_inp = template[qser_inp],
                    base_wqpsc_inp::wqpsc_inp = template[wqpsc_inp])
    @info "random_push: dst_root=$dst_root n=$n, λ=$λ, σ=$σ"

    base_qser_tad = align(template, base_qser_inp)
    base_wqpsc_tad = align(template, base_wqpsc_inp)
    
    probe_qser_inp = deepcopy(base_qser_inp)
    probe_wqpsc_inp = deepcopy(base_wqpsc_inp)
    
    for idx in 1:n
        p = joinpath(dst_root, string(idx))
        if !isdir(p)
            mkdir(p)
        end

        qser_tad = deepcopy(base_qser_tad)
        wqpsc_tad = deepcopy(base_wqpsc_tad)
        random_push!(qser_tad, wqpsc_tad, λ, σ)

        update!(template, probe_qser_inp, qser_tad)
        update!(template, probe_wqpsc_inp, wqpsc_tad)

        p_qser = joinpath(p, name(qser_inp))
        p_wqpsc = joinpath(p, name(wqpsc_inp))
        
        save(p_qser, probe_qser_inp)
        save(p_wqpsc, probe_wqpsc_inp)

        @info "write $p_qser $p_wqpsc"
    end
end

name(::Type{<:PositiveDataFrameDisturber}) = "pdfd.bson"

_get_path(T::Type{<:PositiveDataFrameDisturber}) = joinpath(ENV["WATER_META"], name(T))

function load(T::Type{PositiveDataFrameDisturber})
    p = _get_path(T)
    @info "Load PositiveDataFrameDisturber from $p"
    load(p, T)
end

function save(d::T) where T <: PositiveDataFrameDisturber
    p = _get_path(T)
    save(p, d)
end

function exists(T::Type{PositiveDataFrameDisturber})
    return _get_path(T) |> isfile
end

function random_initial_state(dst_root::String = ENV["WATER_UPSTREAM"],
                            n::Int=10,
                            coef=0.1,
                            day_limit=Day(typemax(Int)),
                            template::AbstractSimulationTemplate = SimulationTemplate(ENV["WATER_ROOT"], Day, Hour),
                            base_wqini_inp=load(template, wqini_inp);
                            force_estimate=false)
    if exists(PositiveDataFrameDisturber) && !force_estimate
        pdfd = load(PositiveDataFrameDisturber)
    else
        if force_estimate
            @info "force_estimate=$force_estimate, creating..."
        else
            @info "Can't find cache for PositiveDataFrameDisturber, creating..."
        end
        dist, name_vec = fit(LowRankMatNormal, template, day_limit)
        pdfd = PositiveDataFrameDisturber(dist, coef, name_vec)
        save(pdfd)
        @info "Write $(_get_path(PositiveDataFrameDisturber))"
    end

    probe_wqini_inp = deepcopy(base_wqini_inp)

    for idx in 1:n
        p = joinpath(dst_root, string(idx))
        if !isdir(p)
            mkdir(p)
        end

        cond_rand!(probe_wqini_inp.df, pdfd, base_wqini_inp.df)

        p_wqini_inp = joinpath(p, name(wqini_inp))

        save(p_wqini_inp, probe_wqini_inp)
        @info "write $p_wqini_inp"
    end
end
