struct CommandBuffer{T <: Tuple{AbstractCommand}}
    data::T
end
CommandBuffer() = CommandBuffer(())

@inline push_cmd(cb::CommandBuffer{T}, cmd) where {T} = CommandBuffer((cb.data..., cmd))
