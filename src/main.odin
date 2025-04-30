package main

import "core:fmt"
import "core:log"
import sdl "vendor:sdl3"
import "core:sort"
import "core:math"

pr :: fmt.println

FPS :: 60
FRAME_TARGET_TIME :: 1000 / FPS

App_State :: struct {
	window: ^sdl.Window,
	renderer: ^sdl.Renderer,
    is_running:  bool,
    window_w: i32,
    window_h: i32,
}
app: ^App_State

Render_Mode :: enum {
    Wireframe_And_Vertices,
    Wireframe,
    Filled_Triangles,
    Filled_Triangles_And_Wireframe,
}

Cull_Method :: enum {
    None,
    Backface,
}

g_color_buffer: []u32
g_color_buffer_texture: ^sdl.Texture
g_previous_frame_time: u64
g_camera_position: Vec3 = {0, 0, 0}
// g_fov_factor: f32 = 640
g_proj_matrix: Mat4
g_triangles_to_render: [dynamic]Triangle
g_mesh: Mesh
g_render_mode: Render_Mode
g_cull_method: Cull_Method
g_light: Light

main :: proc() {
    context.logger = log.create_console_logger()
    app = new(App_State)
    if app.is_running = initialize_window(); !app.is_running {
        log.errorf("Error initializing window: %v", sdl.GetError())
        return
    }
    setup()
    for app.is_running {
        process_input()
        update()
        render()
        free_all(context.temp_allocator)
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
            case sdl.K_1:
                g_render_mode = .Wireframe_And_Vertices
            case sdl.K_2:
                g_render_mode = .Wireframe
            case sdl.K_3:
                g_render_mode = .Filled_Triangles
            case sdl.K_4:
                g_render_mode = .Filled_Triangles_And_Wireframe
            case sdl.K_C:
                g_cull_method = .Backface
            case sdl.K_D:
                g_cull_method = .None
            }
        }
    }
}

update :: proc() {
    next_frame_time := g_previous_frame_time + FRAME_TARGET_TIME
    time_to_wait := next_frame_time - sdl.GetTicks()
    if time_to_wait > 0 && time_to_wait <= FRAME_TARGET_TIME {
        sdl.Delay(u32(time_to_wait))
    }
    g_previous_frame_time = sdl.GetTicks()

    g_mesh.rotation.x += 0.01
    // g_mesh.rotation.y += 0.05
    // g_mesh.rotation.z += 0.05

    // g_mesh.scale.x += 0.02
    // g_mesh.scale.y += 0.02
    // g_mesh.translation.x += 0.1
    g_mesh.translation.z = 5

    scale_matrix := mat4_make_scale(g_mesh.scale)
    rotation_matrix_x := mat4_make_rotation_x(g_mesh.rotation.x)
    rotation_matrix_y := mat4_make_rotation_y(g_mesh.rotation.y)
    rotation_matrix_z := mat4_make_rotation_z(g_mesh.rotation.z)
    translation_matrix := mat4_make_translation(g_mesh.translation)

    world_matrix := mat4_identity()
    // Order matters: scale -> rotate -> translate
    world_matrix = mat4_mul_mat4(scale_matrix, world_matrix)
    world_matrix = mat4_mul_mat4(rotation_matrix_z, world_matrix)
    world_matrix = mat4_mul_mat4(rotation_matrix_y, world_matrix)
    world_matrix = mat4_mul_mat4(rotation_matrix_x, world_matrix)
    world_matrix = mat4_mul_mat4(translation_matrix, world_matrix)

    g_triangles_to_render = make([dynamic]Triangle, context.temp_allocator)
    for face, i in g_mesh.faces {
        face_vertices: [3]Vec3
        face_vertices[0] = g_mesh.vertices[face.a - 1]
        face_vertices[1] = g_mesh.vertices[face.b - 1]
        face_vertices[2] = g_mesh.vertices[face.c - 1]

        // Transformations
        transformed_vertices: [3]Vec4
        for vertex, i in face_vertices {
            transformed_vertices[i] = mat4_mul_vec4(world_matrix, vec4_from_vec3(vertex))
        }

        // Backface Culling
        vertex_a := vec3_from_vec4(transformed_vertices[0])
        vertex_b := vec3_from_vec4(transformed_vertices[1])
        vertex_c := vec3_from_vec4(transformed_vertices[2])
        vector_ab := vertex_b - vertex_a
        vector_ac := vertex_c - vertex_a
        normalize(&vector_ab) // WARN extra instructions, possibly rm if not used later
        normalize(&vector_ac) // WARN extra instructions, possibly rm if not used later

        normal := vec3_cross(vector_ab, vector_ac) // coordinate handedness dependent
        normalize(&normal)

        // form camera ray with A, points towards camera
        camera_ray := g_camera_position - vertex_a

        dot_normal_camera := vec3_dot(normal, camera_ray)

        if g_cull_method == .Backface {
            // cull if negative (pointing away)
            if dot_normal_camera < 0 {
                continue
            }
        }

        // Projections
        projected_points: [3]Vec2
        for transformed_vertex, i in transformed_vertices {
            // projected_vertex := project(vec3_from_vec4(transformed_vertex))
            projected_vertex := mat4_mul_vec4_project(g_proj_matrix, transformed_vertex)

            // Scale into the view
            projected_vertex.x *= f32(app.window_w) / 2
            projected_vertex.y *= f32(app.window_h) / 2

            // Invert y values to account for flipped screen y-coordinates (screen space vs obj file space)
            projected_vertex.y *= -1

            // Translate to middle of screen
            projected_vertex.x += f32(app.window_w) / 2
            projected_vertex.y += f32(app.window_h) / 2

            projected_points[i] = projected_vertex.xy
        }

        // Calc avg depth for each face based on transformed vertices
        avg_depth: f32
        for v in transformed_vertices {
            avg_depth += v.z
        }
        avg_depth /= 3

        // Apply lighting
        light_intensity_factor := -vec3_dot(normal, g_light.direction)
        // pr(light_intensity_factor)
        triangle_color := light_apply_intensity(face.color, light_intensity_factor)

        projected_triangle := Triangle{
            points = projected_points,
            color = triangle_color,
            avg_depth = avg_depth,
        }
        append(&g_triangles_to_render, projected_triangle)
    }
    // Sort triangles to render by avg_depth

    sort_triangles_by_depth(g_triangles_to_render[:])
}

sort_triangles_by_depth :: proc(g_triangles_to_render: []Triangle) {
    sort.quick_sort_proc(g_triangles_to_render, compare_triangle_depth_desc)
}

compare_triangle_depth_desc :: proc(a: Triangle, b: Triangle) -> int {
    return sort.compare_f32s(b.avg_depth, a.avg_depth)
}


render :: proc() {
    draw_grid()
    for triangle in g_triangles_to_render {
        if g_render_mode == .Wireframe_And_Vertices {
            for point in triangle.points {
                draw_rect_filled(point.x - 3, point.y - 3, 6, 6, 0xFFFF0000)
            }
        }
        if g_render_mode == .Wireframe_And_Vertices || g_render_mode == .Wireframe || g_render_mode == .Filled_Triangles_And_Wireframe {
            draw_triangle(
                triangle.points[0].x, triangle.points[0].y,
                triangle.points[1].x, triangle.points[1].y,
                triangle.points[2].x, triangle.points[2].y,
                0xFF00FF00
            )
        }
        if g_render_mode == .Filled_Triangles || g_render_mode == .Filled_Triangles_And_Wireframe {
            draw_filled_triangle(triangle)
        }
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
    g_color_buffer = color_buffer
    g_color_buffer_texture = sdl.CreateTexture(
        app.renderer, 
        sdl.PixelFormat.ARGB8888,
        sdl.TextureAccess.STREAMING,
        app.window_w,
        app.window_h,
    )
    fov := f32(math.PI) / 3
    aspect := f32(app.window_h) / f32(app.window_w)
    znear: f32 = 0.1
    zfar: f32 = 100
    g_proj_matrix = mat4_make_perspective(fov, aspect, znear, zfar)
    g_mesh = init_mesh()
    g_cull_method = .Backface
    g_light = {
        direction = {0, 0, 1}
    }
    // load_cube_mesh_data()
    // load_obj_file_data("./assets/cube.obj")
    load_obj_file_data("./assets/f22.obj")
}

clear_color_buffer :: proc(color: u32) {
    for y in 0..<app.window_h {
        for x in 0..<app.window_w {
            draw_pixel(x, y, color)
        }
    }
}

render_color_buffer :: proc() {
    sdl.UpdateTexture(g_color_buffer_texture, nil, raw_data(g_color_buffer), app.window_w * 4)
    sdl.RenderTexture(app.renderer, g_color_buffer_texture, nil, nil)
}

// project :: proc(point: Vec3) -> Vec2 {
//     return Vec2{
//         (point.x * g_fov_factor) / point.z, 
//         (point.y * g_fov_factor) / point.z,
//     }
// }
