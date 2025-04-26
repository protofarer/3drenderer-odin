package main

import "core:fmt"
import "core:log"
import sdl "vendor:sdl3"

pr :: fmt.println

FPS :: 60
FRAME_TARGET_TIME :: 1000 / FPS

App_State :: struct {
	window: ^sdl.Window,
	renderer: ^sdl.Renderer,
    is_running:  bool,
    color_buffer: []u32, // CSDR ptr or sep struct "buffer(s)"
    color_buffer_texture: ^sdl.Texture,
    window_w: i32,
    window_h: i32,
    previous_frame_time: u64,
}
app: ^App_State

camera_position: Vec3 = {0, 0, -5}
g_fov_factor: f32 = 640

// no. of vertices projected
g_triangles_to_render: [dynamic]Triangle

g_mesh: Mesh

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
        clear(&g_triangles_to_render)
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

update :: proc() {
    next_frame_time := app.previous_frame_time + FRAME_TARGET_TIME
    time_to_wait := next_frame_time - sdl.GetTicks()
    if time_to_wait > 0 && time_to_wait <= FRAME_TARGET_TIME {
        sdl.Delay(u32(time_to_wait))
        // Wait
    }
    app.previous_frame_time = sdl.GetTicks()

    g_mesh.rotation.x += 0.05
    // g_mesh.rotation.y += 0.05
    // g_mesh.rotation.z += 0.05

    for face, i in g_mesh.faces {
        face_vertices: [3]Vec3
        face_vertices[0] = g_mesh.vertices[face[0] - 1]
        face_vertices[1] = g_mesh.vertices[face[1] - 1]
        face_vertices[2] = g_mesh.vertices[face[2] - 1]

        projected_triangle: Triangle

        for vertex, i in face_vertices {
            transformed_vertex := vec3_rotate_y(vertex, g_mesh.rotation.y)
            transformed_vertex = vec3_rotate_x(transformed_vertex, g_mesh.rotation.x)
            transformed_vertex = vec3_rotate_z(transformed_vertex, g_mesh.rotation.z)

            // Translate away from camera
            transformed_vertex.z -= camera_position.z

            // Project
            projected_vertex := project(transformed_vertex)

            // Scale and translate to middle of screen
            projected_vertex.x += f32(app.window_w) / 2
            projected_vertex.y += f32(app.window_h) / 2

            projected_triangle[i] = projected_vertex
        }
        append(&g_triangles_to_render, projected_triangle)
    }
}

render :: proc() {
    draw_grid()

    for triangle in g_triangles_to_render {
        // draw vertices
        for point in triangle {
            draw_rect_filled(
                point.x, 
                point.y, 
                3, 3, 0xFFFF0000
            )
        }
        // draw edges
        draw_triangle(triangle)
    }

    render_color_buffer()
    clear_color_buffer(0xFF000000)

    sdl.RenderPresent(app.renderer)
}

shutdown :: proc() {
    sdl.DestroyRenderer(app.renderer)
    sdl.DestroyWindow(app.window)
    sdl.Quit()
    delete(g_mesh.faces)
    delete(g_mesh.vertices)
    delete(g_triangles_to_render)
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
    g_mesh = Mesh{}
    load_cube_mesh_data()
    load_obj_file_data("./assets/f22.obj")
    // pr(g_mesh.faces)
    // pr(g_mesh.vertices)
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
        (point.x * g_fov_factor) / point.z, 
        (point.y * g_fov_factor) / point.z,
    }
}
