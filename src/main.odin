package main

import "core:fmt"
import "core:log"
import sdl "vendor:sdl3"
import "core:sort"
import "core:math"
import "core:mem"
import "core:image"

pr :: fmt.println

FPS :: 60
FRAME_TARGET_TIME :: 1000 / FPS

MAX_TRIANGLES  :: 20000

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
    Textured,
    Textured_And_Wireframe,
}

Cull_Method :: enum {
    None,
    Backface,
}

g_previous_frame_time: u64
g_camera_position: Vec3 = {0, 0, 0}

g_color_buffer: []u32
g_color_buffer_texture: ^sdl.Texture

g_proj_matrix: Mat4
g_mesh_triangles_to_render: [MAX_NUM_MESHES][dynamic]Triangle

MAX_NUM_MESHES :: 10
g_meshes: [MAX_NUM_MESHES]Mesh
g_meshes_count: int

g_light: Light

g_render_mode: Render_Mode
g_cull_method: Cull_Method

g_z_buffer: []f32

g_camera: Camera

g_dt: f32

g_frustrum_planes: [Frustrum_Plane]Plane

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

    g_color_buffer = make([]u32, app.window_w * app.window_h)
    g_z_buffer = make([]f32, app.window_h * app.window_w)

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
            case sdl.K_5:
                g_render_mode = .Textured
            case sdl.K_6:
                g_render_mode = .Textured_And_Wireframe
            case sdl.K_C:
                g_cull_method = .Backface
            case sdl.K_X:
                g_cull_method = .None
            case sdl.K_R:
                update_camera_position({g_camera.position.x, g_camera.position.y + 2 * g_dt, g_camera.position.z})
            case sdl.K_F:
                update_camera_position({g_camera.position.x, g_camera.position.y - 2 * g_dt, g_camera.position.z})
            case sdl.K_A:
                rotate_camera_yaw(-0.3 * g_dt)
                // TODO: calc new direction
            case sdl.K_D:
                rotate_camera_yaw(0.3 * g_dt)
            case sdl.K_W:
                rotate_camera_pitch(-0.3 * g_dt)
            case sdl.K_S:
                rotate_camera_pitch(0.3 * g_dt)
            case sdl.K_UP:
                update_camera_forward_velocity(get_camera_direction() * 7)
                update_camera_position(get_camera_position() + get_camera_forward_velocity() * g_dt)
            case sdl.K_DOWN:
                update_camera_forward_velocity(get_camera_direction() * -7)
                update_camera_position(get_camera_position() + get_camera_forward_velocity() * g_dt)
            case sdl.K_LEFT:
                update_camera_position({g_camera.position.x - 2 * g_dt, g_camera.position.y, g_camera.position.z})
            case sdl.K_RIGHT:
                update_camera_position({g_camera.position.x + 2 * g_dt, g_camera.position.y, g_camera.position.z})
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
    g_dt = f32(sdl.GetTicks() - g_previous_frame_time) / 1000
    g_previous_frame_time = sdl.GetTicks()

    for &mesh, mesh_idx in g_meshes {
        // g_mesh.rotation.x += 1 * g_dt
        // g_mesh.rotation.y += -0.02
        // g_mesh.rotation.z += 0.05
        // g_mesh.scale.x += 0.02
        // g_mesh.scale.y += 0.02
        // g_mesh.translation.x += 0.1

        scale_matrix := mat4_make_scale(mesh.scale)
        rotation_matrix_x := mat4_make_rotation_x(mesh.rotation.x)
        rotation_matrix_y := mat4_make_rotation_y(mesh.rotation.y)
        rotation_matrix_z := mat4_make_rotation_z(mesh.rotation.z)
        translation_matrix := mat4_make_translation(mesh.translation)

        // update camera direction based on yaw, pitch, and unit target
        update_camera_lookat_target()

        // View matrix
        up_direction := Vec3{0, 1, 0}
        target := get_camera_target()
        view_matrix := mat4_look_at(g_camera.position, target, up_direction)

        world_matrix := mat4_identity()
        // Order matters: scale -> rotate -> translate
        world_matrix = mat4_mul_mat4(scale_matrix, world_matrix)
        world_matrix = mat4_mul_mat4(rotation_matrix_z, world_matrix)
        world_matrix = mat4_mul_mat4(rotation_matrix_y, world_matrix)
        world_matrix = mat4_mul_mat4(rotation_matrix_x, world_matrix)
        world_matrix = mat4_mul_mat4(translation_matrix, world_matrix)

        triangles_to_render := make([dynamic]Triangle, context.temp_allocator)
        for face, i in mesh.faces {
            face_vertices: [3]Vec3
            face_vertices[0] = mesh.vertices[face.a]
            face_vertices[1] = mesh.vertices[face.b]
            face_vertices[2] = mesh.vertices[face.c]

            // Transformations
            transformed_vertices: [3]Vec4
            for vertex, j in face_vertices {
                // World Space
                transformed_vertex := vec4_from_vec3(vertex)
                transformed_vertex = mat4_mul_vec4(world_matrix, transformed_vertex)
                // Camera Space
                transformed_vertex = mat4_mul_vec4(view_matrix, transformed_vertex)
                transformed_vertices[j] = transformed_vertex 
            }

            // Backface Culling
            face_normal := get_triangle_normal(transformed_vertices)

            // form camera ray with A, points towards camera
            origin: Vec3
            vertex_a := vec3_from_vec4(transformed_vertices[0])
            camera_ray := origin - vertex_a

            dot_normal_camera := dot(face_normal, camera_ray)

            if g_cull_method == .Backface {
                // cull if negative (pointing away)
                if dot_normal_camera < 0 {
                    continue
                }
            }

            // Clipping
            polygon := create_polygon_from_triangle(
                         vec3_from_vec4(transformed_vertices[0]), 
                         vec3_from_vec4(transformed_vertices[1]),
                         vec3_from_vec4(transformed_vertices[2]),
                         face.a_uv, face.b_uv, face.c_uv,
                     )
            clip_polygon(&polygon)
            triangles_after_clipping, num_triangles_after_clipping := triangles_from_polygon(polygon)

            for t := 0; t < num_triangles_after_clipping; t += 1 {
                triangle_after_clipping := triangles_after_clipping[t]

                // Projections
                projected_points: [3]Vec4
                for transformed_vertex, i in triangle_after_clipping.points {
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

                    projected_points[i] = projected_vertex
                }

                // Apply lighting
                light_intensity_factor := -dot(face_normal, g_light.direction)
                triangle_color := light_apply_intensity(face.color, light_intensity_factor)

                triangle_to_render := Triangle{
                    points = projected_points,
                    color = triangle_color,
                    texcoords = {
                        {triangle_after_clipping.texcoords[0].u, triangle_after_clipping.texcoords[0].v},
                        {triangle_after_clipping.texcoords[1].u, triangle_after_clipping.texcoords[1].v},
                        {triangle_after_clipping.texcoords[2].u, triangle_after_clipping.texcoords[2].v},
                    }
                }
                if len(triangles_to_render) * mesh_idx < MAX_TRIANGLES {
                    append(&triangles_to_render, triangle_to_render)
                }
            }
        }
        g_mesh_triangles_to_render[mesh_idx] = triangles_to_render
    }
}

render :: proc() {
    clear_color_buffer(0xFF000000)
    clear_z_buffer()
    draw_grid()
    for mesh, mesh_idx in g_meshes {
        for triangle in g_mesh_triangles_to_render[mesh_idx] {
            if g_render_mode == .Wireframe_And_Vertices {
                for point in triangle.points {
                    draw_rect_filled(point.x - 3, point.y - 3, 6, 6, 0xFFFF0000)
                }
            }
            if is_rendering_wireframe() {
                draw_triangle(
                    triangle.points[0].x, triangle.points[0].y,
                    triangle.points[1].x, triangle.points[1].y,
                    triangle.points[2].x, triangle.points[2].y,
                    0xFF00FF00
                )
            }
            if is_rendering_textures() {
                draw_textured_triangle(triangle, mesh.texture)
            }
            if is_rendering_filled() {
                draw_filled_triangle(triangle)
            }
        }
    }
    render_color_buffer()
}

is_rendering_filled :: proc() -> bool {
    return g_render_mode == .Filled_Triangles || 
           g_render_mode == .Filled_Triangles_And_Wireframe 
}

is_rendering_wireframe :: proc() -> bool {
    return  g_render_mode == .Wireframe_And_Vertices || 
            g_render_mode == .Wireframe || 
            g_render_mode == .Filled_Triangles_And_Wireframe || 
            g_render_mode == .Textured_And_Wireframe
}

is_rendering_textures :: proc() -> bool {
    return g_render_mode == .Textured || 
           g_render_mode == .Textured_And_Wireframe 
}

shutdown :: proc() {
    sdl.DestroyRenderer(app.renderer)
    sdl.DestroyWindow(app.window)
    sdl.Quit()
    for &mesh in g_meshes {
        delete(mesh.texture.pixels)
    }
    delete(g_color_buffer)
    delete(g_z_buffer)
    return
}

setup :: proc() {
    log.info("Begin setup...")
    // allocate and slice
    g_color_buffer_texture = sdl.CreateTexture(
        app.renderer, 
        sdl.PixelFormat.ABGR8888, // PNG RGBA internally, on little-endian (AMD) bytes reversed
        sdl.TextureAccess.STREAMING,
        app.window_w,
        app.window_h,
    )
    aspect_x := f32(app.window_w) / f32(app.window_h)
    aspect_y := f32(app.window_h) / f32(app.window_w)
    fov_y := f32(math.PI) / 3
    fov_x := math.atan(math.tan(fov_y / 2) * aspect_x) * 2
    aspect := f32(app.window_h) / f32(app.window_w)
    z_near: f32 = 0.1
    z_far: f32 = 100
    g_proj_matrix = mat4_make_perspective(fov_y, aspect_y, z_near, z_far)
    g_cull_method = .Backface

    init_frustrum_planes(fov_x, fov_y, z_near, z_far)
    init_camera()
    init_light()

    inputs := [?]Mesh_Initialization_Params {
        {
            obj_file = "assets/f117.obj",
            tex_file = "assets/f117.png",
            scale = {1,1,1},
            translation = {0,0,10},
            rotation = {0,0,0},
        },
        {
            obj_file = "assets/cube.obj",
            tex_file = "assets/cube.png",
            scale = {1,1,1},
            translation = {5,0,10},
            rotation = {0,0,0},
        },
        {
            obj_file = "assets/efa.obj",
            tex_file = "assets/efa.png",
            scale = {1,1,1},
            translation = {-5,0,10},
            rotation = {0,0,0},
        },
    }

    for input in inputs {
        if mesh, ok_mesh := init_mesh(input.obj_file, input.scale, input.translation, input.rotation); ok_mesh {
            log.info("Loaded object file to mesh:", input.obj_file)
            if tex_file, ok := input.tex_file.?; ok {
                if texture, ok_tex := load_texture(tex_file); ok_tex {
                    mesh.texture = texture
                }
            }
            g_meshes[g_meshes_count] = mesh
            g_meshes_count += 1
        }
    }
    log.info("Loaded", g_meshes_count, "meshes")
    log.info("Setup complete")
}

load_texture :: proc(filepath: string) -> (Texture, bool) {
    if texture, ok_tex := load_png_texture_data(filepath); ok_tex {
        log.info("Loaded texture file:", filepath)
        return texture, true
    } else {
        log.error("Failed to load texture file:", filepath)
        return {}, false
    }
}

clear_color_buffer :: proc(color: u32) {
    for i in 0..<app.window_h*app.window_w {
        draw_pixel(i % app.window_w, i/app.window_w, color)
    }
}

render_color_buffer :: proc() {
    sdl.UpdateTexture(g_color_buffer_texture, nil, raw_data(g_color_buffer), app.window_w * 4)
    sdl.RenderTexture(app.renderer, g_color_buffer_texture, nil, nil)
    sdl.RenderPresent(app.renderer)
}

clear_z_buffer :: proc() {
    mem.zero_slice(g_z_buffer)
}
