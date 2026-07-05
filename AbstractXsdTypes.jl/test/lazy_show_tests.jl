@testitem "propertynames excludes _node; print_tree does not force-materialize uninit lazy fields" begin
    using LazilyInitializedFields

    @lazy mutable struct LazyShowTestType <: AbstractXsdTypes.AbstractXSDComplex
        _node::Union{Nothing,Int}
        @lazy Element_a::String = _init_touch_counter_a
        @lazy Element_b::String = _init_touch_counter_b
        __xml_attributes::Union{Nothing,Dict{String,String}}
        __validated::Bool
    end

    const TOUCH_COUNTS = Dict(:a => 0, :b => 0)
    function _init_touch_counter_a(::LazyShowTestType)
        TOUCH_COUNTS[:a] += 1
        return "value-a"
    end
    function _init_touch_counter_b(::LazyShowTestType)
        TOUCH_COUNTS[:b] += 1
        return "value-b"
    end

    obj = LazyShowTestType(1, uninit, uninit, nothing, true)

    # propertynames excludes the internal _node field
    @test :_node ∉ propertynames(obj)
    @test :Element_a in propertynames(obj)

    # printing must not touch either lazy field
    io = IOBuffer()
    show(io, obj)
    @test TOUCH_COUNTS[:a] == 0
    @test TOUCH_COUNTS[:b] == 0
    printed = String(take!(io))
    @test occursin("uninit", printed)

    # after a real access, printing reflects the now-initialized value without re-triggering init
    @test obj.Element_a == "value-a"
    @test TOUCH_COUNTS[:a] == 1
    io2 = IOBuffer()
    show(io2, obj)
    @test TOUCH_COUNTS[:a] == 1  # not incremented by printing
    @test occursin("value-a", String(take!(io2)))
end
