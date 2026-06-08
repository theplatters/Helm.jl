struct ResourceData{D, M} <: SystemConfig end

Res(::Type{T}) where {T} = ResourceData{T, false}()
ResMut(::Type{T}) where {T} = ResourceData{T, true}()

reads(::ResourceData{T, false}) where {T} = (T,)

writes(::ResourceData{T, false}) where {T} = ()
writes(::ResourceData{T, true}) where {T} = (T,)


reads(::Type{ResourceData{D, false}}) where {D} = (D,)
reads(::Type{ResourceData{D, true}}) where {D} = ()

writes(::Type{ResourceData{D, false}}) where {D} = ()
writes(::Type{ResourceData{D, true}}) where {D} = (D,)
