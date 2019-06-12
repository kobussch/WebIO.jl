using WebIO
using Test

# NOTE: We use `@eval` a lot here for two reasons.
#   1. Because `struct` definitions are only allowed at the top level.
#   2. To delay execution of the `@register_renderable` macro so that the macro
#      evaluation happens at test time (this avoids invalid invocations from
#      preventing the rest of the test suite from even running and is also
#      necessary to try to catch errors raised by the macro).

@testset "WebIO.@register_renderable" begin

    @testset "@register_renderable for symbol" begin
        MyTypeName = gensym()
        @eval struct $MyTypeName dom::WebIO.Node end
        @eval WebIO.render(x::$MyTypeName) = x.dom
        @eval WebIO.@register_renderable($MyTypeName)

        MyType = @eval $MyTypeName
        @test hasmethod(show, (IO, WebIO.WEBIO_NODE_MIME, MyType))
        myinstance = MyType(node(:p, "Hello, world!"))
        myinstance_json = sprint(show, WebIO.WEBIO_NODE_MIME(), myinstance)
        myinstance_html = sprint(show, MIME("text/html"), myinstance)
        @test occursin("Hello, world!", myinstance_json)
        @test occursin("Hello, world!", myinstance_html)
    end

    @testset "@register_renderable with do-block syntax" begin
        MyTypeName = gensym()
        @eval struct $MyTypeName dom::WebIO.Node end

        MyType = @eval $MyTypeName
        @eval @WebIO.register_renderable($MyType) do x
            return x.dom
        end

        @test hasmethod(show, (IO, WebIO.WEBIO_NODE_MIME, MyType))
        myinstance = MyType(node(:p, "Hello, world!"))
        myinstance_json = sprint(show, WebIO.WEBIO_NODE_MIME(), myinstance)
        myinstance_html = sprint(show, MIME("text/html"), myinstance)
        @test occursin("Hello, world!", myinstance_json)
        @test occursin("Hello, world!", myinstance_html)
    end

    @testset "@register_renderable with invalid syntax" begin
        # Yay for parentheses hell!
        @test_throws Exception @eval @WebIO.register_renderable(NotReal)

        MyTypeName = gensym()
        @eval struct $MyTypeName end
        @test_throws Exception @eval(
            @WebIO.register_renderable($MyTypeName) do arg1, arg2
                return node(:p, foo)
            end
        )
    end

end
