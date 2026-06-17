abstract type AbstractCommand end

struct CommandBuffer{T <: Tuple}
    data::T
end
CommandBuffer() = CommandBuffer(())

@inline push_cmd(cb::CommandBuffer, cmd::AbstractCommand) = CommandBuffer((cb.data..., cmd))

