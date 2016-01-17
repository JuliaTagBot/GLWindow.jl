function renderloop_inner(screen)
    fb = framebuffer(screen)
    yield()
    resize!(fb, width(screen))
    prepare(fb)
    render(screen)
    #Read all the selection queries
    push_selectionqueries!(screen)

    display(fb, screen)

    swapbuffers(screen)
end

"""
Blocking renderloop
"""
function renderloop(screen::Screen)
    while isopen(screen)
        renderloop_inner(screen)
    end
end

function prepare(fb::GLFramebuffer)
    glDisable(GL_SCISSOR_TEST)
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id)
    glDrawBuffers(2, [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1])
end

function display(fb::GLFramebuffer, screen)
    glDisable(GL_SCISSOR_TEST)
    glBindFramebuffer(GL_FRAMEBUFFER, 0)
    glViewport(screen.area.value)
    glClear(GL_COLOR_BUFFER_BIT)
    render(fb.postprocess)
end

function GLAbstraction.render(x::Screen, parent::Screen=x, context=x.area.value)
    if isopen(x) && !ishidden(x)
        sa    = value(x.area)
        sa    = SimpleRectangle(context.x+sa.x, context.y+sa.y, sa.w, sa.h) # bring back to absolute values
        pa    = context
        sa_pa = intersect(pa, sa) # intersection with parent
        if sa_pa != SimpleRectangle{Int}(0,0,0,0) # if it is in the parent area
            glEnable(GL_SCISSOR_TEST)
            glScissor(sa_pa)
            glViewport(sa)
            if alpha(x.color) > 0
                glClearColor(red(x.color), green(x.color), blue(x.color), alpha(x.color))
                glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
            end
            render(x.renderlist)
            for screen in x.children
                render(screen, x, sa)
            end
        end
    end
end