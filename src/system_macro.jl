function make_system(f::F, configs::Vararg{SystemConfig, N}) where {F <: Function, N}
    return System(f, configs)
end
