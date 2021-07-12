
function rand_posisson_process(λ, time_begin, time_end)
    loc = time_begin
    rv = Float64[]
    while true
        loc += rand(Exponential(1/λ))
        if loc >= time_end
            break
        end
        push!(rv, loc)
    end
    return rv
end

function random_push_interpolation(n::Int, λ, σ)
    boundary = unique(round.(Int, rand_posisson_process(λ, 1, n + 1)))
    boundary_warped = sort(clamp.(boundary .+ randn(length(boundary)) * σ, 1, n + 1))
    if boundary[1] > 1
        boundary = [1; boundary]
        boundary_warped = [1; boundary_warped]
    else
        boundary_warped[1] = 1
    end
    if boundary[end] < n + 1
        boundary = [boundary; n + 1]
        boundary_warped = [boundary_warped; n + 1]
    else
        boundary_warped[end] = n+1
    end

    li1 = LinearInterpolation(boundary, boundary_warped)
    x = li1.(1:n) #  for some reasons, x may > n+1
    mask = [true; [x[i-1] < prevfloat(x[i]) && x[i] < n+1 for i in 2:length(x)]]
    x = x[mask]

    # @assert length(unique(x)) == length(x)
    # @assert sort(x) == x

    x2 = vec([x[1:end-1]' ; prevfloat.(x[2:end]')])

    #=
    if length(unique(x2)) != length(x2)
        @show x[end-5:end] x2[end-5:end]
    end
    =#
    # @assert length(unique(x2)) == length(x2)
    # @assert sort(x2) == x2

    if nextfloat(x2[end]) < n+1
        x2 = [x2; [nextfloat(x2[end]), n+1]]
    else
        x2[end] = n+1
        idx = findlast(x->x, mask)
        mask[idx] = false
    end

    # @show length(x2) length(unique(x2)) (x2 == sort(x2)) x2[end-6:end]

    function interp(y)
        # @show length(y) length(mask)
        y = y[mask]
        # y2 = vec([y'; y'])
        y2 = repeat(y, inner=2)
        return LinearInterpolation(x2, y2).(1:n)
    end
    return interp
end
