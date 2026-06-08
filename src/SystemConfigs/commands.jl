struct Cmds <: SystemConfig end


reads(::Cmds) = ()
writes(::Cmds) = ()
reads(::Type{Cmds}) = ()
writes(::Type{Cmds}) = ()
