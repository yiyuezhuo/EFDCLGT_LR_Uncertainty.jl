
using Test
using Dates
using Logging

using EFDCLGT_LR_Files
using EFDCLGT_LR_Files: name
using Statistics
using EFDCLGT_LR_Uncertainty

debug_logger = SimpleLogger(stdout, Logging.Debug)
default_logger = global_logger()
global_logger(debug_logger)

template = SimulationTemplate(ENV["WATER_ROOT"], Day, Hour)

@testset "EFDCLGT_LR_Uncertainty" begin
    dst_root = tempname()
    mkdir(dst_root)

    random_push(dst_root, 2, 1/24, 10)
    random_initial_state(dst_root, 2, 0.1, Day(2))

    @test isdir(joinpath(dst_root, "1"))
    @test isdir(joinpath(dst_root, "2"))
    @test !isdir(joinpath(dst_root, "3"))

    for ftype in [qser_inp, wqpsc_inp, wqini_inp]
        d0 = load(template, ftype)
        d1 = load(joinpath(dst_root, "1", name(ftype)), ftype)
        d2 = load(joinpath(dst_root, "2", name(ftype)), ftype)

        if ftype == wqini_inp
            @test d1.df != d2.df
        else
            for k in keys(d1)
                if ftype == qser_inp
                    if std(d0[k][!, :flow]) == 0
                        continue
                    end
                end
                @test d1[k] != d2[k]
            end
        end
    end

    rm(dst_root, recursive=true)

end