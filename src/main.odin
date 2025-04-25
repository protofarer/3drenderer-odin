package main

import "core:fmt"
import "core:log"
import sdl "vendor:sdl3"

pr :: fmt.println

App_State :: struct {
	window: ^sdl.Window,
	renderer: ^sdl.Renderer,
    is_running:  bool,
    color_buffer: []u32, // CSDR ptr or sep struct "buffer(s)"
    color_buffer_texture: ^sdl.Texture,
    window_w: i32,
    window_h: i32,
}
app: ^App_State

N_POINTS :: 9*9*9
camera_position: Vec3 = {0, 0, -5}
fov_factor: f32 = 640

cube_points: [N_POINTS]Vec3
projected_points: [N_POINTS]Vec2

main :: proc() {
    context.logger = log.create_console_logger()
    app = new(App_State)
    if app.is_running = initialize_window(); !app.is_running {
        log.errorf("Error initializing window. Exiting.")
        return
    }
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

    // display_count: i32
    // displays := sdl.GetDisplays(&display_count)
    // log.debug("Available Displays...")
    // for i in 0..<display_count {
    //     log.debug("DisplayId:", displays[i])
    // }
    display_mode := sdl.GetCurrentDisplayMode(2)
    app.window_w = display_mode.w
    app.window_h = display_mode.h
	// RESIZABLE
    if app.window = sdl.CreateWindow("3D Software Renderer", app.window_w, app.window_h, {.BORDERLESS}); app.window == nil {
        log.errorf("CreateWindow error: %v", sdl.GetError())
        return false
    }
    sdl.SetWindowPosition(app.window, 0, 0)
    sdl.SetWindowFullscreen(app.window, true)

    if app.renderer = sdl.CreateRenderer(app.window, nil); app.renderer == nil {
        log.errorf("CreateRenderer error: %v", sdl.GetError())
        return false
    }
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

cube_rotation: Vec3
update :: proc() {
    cube_rotation.x += 0.05
    cube_rotation.y += 0.05
    cube_rotation.z += 0.05
    for p, i in cube_points {
        point := p

        transformed_point := vec3_rotate_y(point, cube_rotation.y)
        transformed_point = vec3_rotate_x(transformed_point, cube_rotation.x)
        transformed_point = vec3_rotate_z(transformed_point, cube_rotation.z)

        transformed_point.z -= camera_position.z
        projected_point := project(transformed_point)
        projected_points[i] = projected_point
    }
}

render :: proc() {
    draw_grid()

    for p in projected_points {
        draw_rect_filled(
            p.x + (f32(app.window_w) / 2), 
            p.y + (f32(app.window_h)/2), 
            4, 4, 0xFFFF0000
        )
    }

    render_color_buffer()
    clear_color_buffer(0xFF000000)

    sdl.RenderPresent(app.renderer)
}

shutdown :: proc() {
    sdl.DestroyRenderer(app.renderer)
    sdl.DestroyWindow(app.window)
    sdl.Quit()
    return
}

setup :: proc() {
    // allocate and slice
    color_buffer := make([]u32, app.window_w * app.window_h)
    app.color_buffer = color_buffer
    app.color_buffer_texture = sdl.CreateTexture(
        app.renderer, 
        sdl.PixelFormat.ARGB8888,
        sdl.TextureAccess.STREAMING,
        app.window_w,
        app.window_h,
    )

    point_count: int
    for x:f32 = -1; x <= 1; x += 0.25 {
        for y:f32 = -1; y <= 1; y += 0.25 {
            for z:f32 = -1; z <= 1; z += 0.25 {
                new_point := Vec3{x, y, z}
                cube_points[point_count] = new_point
                point_count += 1
            }
        }
    }
}

clear_color_buffer :: proc(color: u32) {
    for y in 0..<app.window_h {
        for x in 0..<app.window_w {
            draw_pixel(x, y, color)
        }
    }
}

render_color_buffer :: proc() {
    sdl.UpdateTexture(app.color_buffer_texture, nil, raw_data(app.color_buffer), app.window_w * 4)
    sdl.RenderTexture(app.renderer, app.color_buffer_texture, nil, nil)
}

project :: proc(point: Vec3) -> Vec2 {
    return Vec2{
        (point.x * fov_factor) / point.z, 
        (point.y * fov_factor) / point.z,
    }
}
