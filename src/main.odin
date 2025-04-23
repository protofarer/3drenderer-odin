package main

import "core:fmt"
import "core:log"
import sdl "vendor:sdl3"

pr :: fmt.println

WINDOW_W :: 1080
WINDOW_H :: 720

App_State :: struct {
	window: ^sdl.Window,
	renderer: ^sdl.Renderer,
    is_running:  bool,
    color_buffer: [WINDOW_W * WINDOW_H]u32, // CSDR ptr
    color_buffer_texture: ^sdl.Texture,
}
app: ^App_State

main :: proc() {
    context.logger = log.create_console_logger()
    app = new(App_State)
    app.is_running = initialize_window()
    setup()

    for app.is_running {
        process_input()
        update()
        render()
    }
    shutdown()
}

initialize_window :: proc() -> bool {
    if !sdl.Init({ .VIDEO }) {
        log.errorf("Error initializing SDL: %v", sdl.GetError())
        return false
    }
	// RESIZABLE
    if app.window = sdl.CreateWindow("3D Software Renderer", WINDOW_W, WINDOW_H, {}); app.window == nil {
        log.errorf("CreateWindow error: %v", sdl.GetError())
        return false
    }
    if app.renderer = sdl.CreateRenderer(app.window, nil); app.renderer == nil {
        log.errorf("CreateRenderer error: %v", sdl.GetError())
        return false
    }
    sdl.SetWindowPosition(app.window, 100, 100)
    return true
}

process_input :: proc() {
    e: sdl.Event
    for sdl.PollEvent(&e) {
        #partial switch e.type {
        case .QUIT:
            app.is_running = false
        case .KEY_DOWN:
            switch e.key.key {
            case sdl.K_ESCAPE:
                app.is_running = false
            }
        }
    }
}

update :: proc() {
}

render :: proc() {
    sdl.RenderClear(app.renderer)
    sdl.SetRenderDrawColor(app.renderer, 0, 0, 0, 255)
    sdl.RenderClear(app.renderer)
    render_color_buffer()
    clear_color_buffer(0xFFFFFF00)
    sdl.RenderPresent(app.renderer)
}

shutdown :: proc() {
    sdl.DestroyRenderer(app.renderer)
    sdl.DestroyWindow(app.window)
    sdl.Quit()
    return
}

setup :: proc() {
    app.color_buffer[(WINDOW_W * 10) + 20] = 0xFF00FF00
    app.color_buffer_texture = sdl.CreateTexture(
        app.renderer, 
        sdl.PixelFormat.ARGB8888,
        sdl.TextureAccess.STREAMING,
        WINDOW_W,
        WINDOW_H,
    )
}

clear_color_buffer :: proc(color: u32) {
    for y in 0..<WINDOW_H {
        for x in 0..<WINDOW_W {
            app.color_buffer[(WINDOW_W * y) + x] = color
        }
    }
}

render_color_buffer :: proc() {
    // TODO: think last arg (pitch) is bad. pitch :: number of bytes in a row/pitch of buffer
    sdl.UpdateTexture(app.color_buffer_texture, nil, &app.color_buffer, WINDOW_W * 4)
    sdl.RenderTexture(app.renderer, app.color_buffer_texture, nil, nil)
}
