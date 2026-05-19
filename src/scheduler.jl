struct Mutable{T} end

struct Scheduler
    _schedules::Vector{Schedule}
end
