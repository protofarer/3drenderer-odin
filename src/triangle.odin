package main

import "core:math"

// Vertex indices, order matters
Face :: struct {
    a: int,
    b: int,
    c: int,
    color: Color_Value,
    a_uv: Tex2, // CSDR uv index instead of coordinate, since vt is avail in obj file
    b_uv: Tex2,
    c_uv: Tex2,
}

Triangle :: struct {
    points: [3]Vec4,
    color: Color_Value,
    texcoords: Tex_Coords
}
Tex_Coords :: [3]Tex2

draw_triangle :: proc(x0,y0,x1,y1,x2,y2: f32, color: Color_Value = DEFAULT_COLOR) {
    draw_line(x0, y0, x1, y1, color)
    draw_line(x1, y1, x2, y2, color)
    draw_line(x2, y2, x0, y0, color)
}

draw_filled_triangle :: proc(triangle: Triangle) {
    p := triangle.points
    if p[0].y > p[1].y {
        swap(&p[0].y, &p[1].y)
        swap(&p[0].x, &p[1].x)
        swap(&p[0].z, &p[1].z)
        swap(&p[0].w, &p[1].w)
    }
    if p[1].y > p[2].y {
        swap(&p[1].y, &p[2].y)
        swap(&p[1].x, &p[2].x)
        swap(&p[1].z, &p[2].z)
        swap(&p[1].w, &p[2].w)
    }
    if p[0].y > p[1].y {
        swap(&p[0].y, &p[1].y)
        swap(&p[0].x, &p[1].x)
        swap(&p[0].z, &p[1].z)
        swap(&p[0].w, &p[1].w)
    }

    point_a := p[0]
    point_b := p[1]
    point_c := p[2]

    // render flat bottom (top) triangle
    inv_slope_1: f32 = 0
    inv_slope_2: f32 = 0

    if p[1].y - p[0].y != 0 do inv_slope_1 = (p[1].x - p[0].x) / math.abs(p[1].y - p[0].y)
    if p[2].y - p[0].y != 0 do inv_slope_2 = (p[2].x - p[0].x) / math.abs(p[2].y - p[0].y)

    // don't render a triangle perpendicular to camera (a line)
    if p[1].y - p[0].y != 0 {
        for y := p[0].y; y <= p[1].y; y += 1 {
            x_start := p[1].x + (y - p[1].y) * inv_slope_1
            x_end := p[0].x + (y - p[0].y) * inv_slope_2

            if x_end < x_start do swap(&x_start, &x_end)

            for x := x_start; x <= x_end; x += 1 {
                draw_triangle_pixel(x, y, triangle)
            }
        }
    }

    // render flat top (bottom) triangle
    inv_slope_1 = 0
    inv_slope_2 = 0

    if p[2].y - p[1].y != 0 do inv_slope_1 = (p[2].x - p[1].x) / math.abs(p[2].y - p[1].y)
    if p[2].y - p[0].y != 0 do inv_slope_2 = (p[2].x - p[0].x) / math.abs(p[2].y - p[0].y)

    // don't render a triangle perpendicular to camera (a line)
    if p[2].y - p[1].y != 0 {
        for y := p[1].y; y <= p[2].y; y += 1 {
            x_start := p[1].x + (y - p[1].y) * inv_slope_1
            x_end := p[0].x + (y - p[0].y) * inv_slope_2

            if x_end < x_start do swap(&x_start, &x_end)

            for x := x_start; x <= x_end; x += 1 {
                draw_triangle_pixel(x, y, triangle)
            }
        }
    }
}

draw_triangle_pixel :: proc(x, y: f32, triangle: Triangle) {
    p := Vec2{x,y}
    point_a := triangle.points[0]
    point_b := triangle.points[1]
    point_c := triangle.points[2]
    weights := barycentric_weights(point_a.xy, point_b.xy, point_c.xy, p)
    alpha := weights.x
    beta := weights.y
    gamma := weights.z
    interpolated_reciprocal_w := (1 / point_a.w) * alpha + (1 / point_b.w) * beta + (1 / point_c.w) * gamma

    // diverge from course, since now z_buffer cleared to 0 instead of 1
    // interpolated_reciprocal_w = 1 - interpolated_reciprocal_w

    if interpolated_reciprocal_w > g_z_buffer[(app.window_w * i32(y)) + i32(x)] {
        draw_pixel(x, y, triangle.color)
        g_z_buffer[(app.window_w * i32(y)) + i32(x)] = interpolated_reciprocal_w
    }
}

fill_flat_bottom_triangle :: proc(x0, y0, x1, y1, x2, y2: f32, color: Color_Value = DEFAULT_COLOR) {
    inv_slope_1 := (x1 - x0) / (y1 - y0)
    inv_slope_2 := (x2 - x0) / (y2 - y0)
    x_left := x0
    x_right := x0
    for y := y0; y <= y2; y += 1 {
        draw_line(x_left, y, x_right, y, color)
        x_left += inv_slope_1
        x_right += inv_slope_2
    }
}

fill_flat_top_triangle :: proc(x0, y0, x1, y1, x2, y2: f32, color: Color_Value = DEFAULT_COLOR) {
    // inv_slope_1 := (x0 - x2) / (y0 - y2)
    // inv_slope_2 := (x1 - x2) / (y1 - y2)
    inv_slope_1 := (x2 - x0) / (y2 - y0)
    inv_slope_2 := (x2 - x1) / (y2 - y1)
    x_left := x2
    x_right := x2
    for y := y2; y >= y0; y -= 1 {
        draw_line(x_left, y, x_right, y, color)
        x_left -= inv_slope_1
        x_right -= inv_slope_2
    }
}

// Draw textured pixel at position x,y using interpolation
// TODO: change sig to use a_uv, b_uv..
draw_triangle_texel :: proc(
    x: f32, y: f32,
    texture: []u32,
    point_a: Vec4, point_b: Vec4, point_c: Vec4,
    a_uv: Tex2, b_uv: Tex2, c_uv: Tex2,
) {
    p := Vec2{x,y}
    weights := barycentric_weights(point_a.xy, point_b.xy, point_c.xy, p)
    alpha := weights.x
    beta := weights.y
    gamma := weights.z

    // (Step 1, start using 1/w to transform to linear screen space)

    // Store interpolated u,v,1/w for current pixel
    interpolated_u: f32
    interpolated_v: f32
    interpolated_reciprocal_w: f32

    // Step 2 -  Interpolate u/w, v/w values using barycentric weights and the factor 1/w
    interpolated_u = (a_uv.u / point_a.w) * alpha + (b_uv.u / point_b.w) * beta + (c_uv.u / point_c.w) * gamma
    interpolated_v = (a_uv.v / point_a.w) * alpha + (b_uv.v / point_b.w) * beta + (c_uv.v / point_c.w) * gamma

    // Interpolate value of 1/w for current pixel
    interpolated_reciprocal_w = (1 / point_a.w) * alpha + (1 / point_b.w) * beta + (1 / point_c.w) * gamma

    // Step 3 - Undo perspective transform
    interpolated_u /= interpolated_reciprocal_w
    interpolated_v /= interpolated_reciprocal_w

    // Map u,v, to full texture width and height
    // hacky to keep resulting index within bounds. This is a hack because of negative (invalid) weights
    tex_x := math.abs(i32(interpolated_u * f32(g_texture_width))) % g_texture_width
    tex_y := math.abs(i32(interpolated_v * f32(g_texture_height))) % g_texture_height

    // (hack) Adjust 1/w so that closer pixels have smaller values
   // interpolated_reciprocal_w = 1 - interpolated_reciprocal_w

    buffer_index := app.window_w * i32(y) + i32(x)
    // TODO: rm hack?
    if int(buffer_index) >= len(g_z_buffer) { return }
    if interpolated_reciprocal_w > g_z_buffer[buffer_index] {
        index := ((g_texture_width * tex_y) + tex_x)
        // TODO: rm hack?
        if int(index) >= len(texture) { return }
        draw_pixel(x, y, texture[index])
        g_z_buffer[(app.window_w * i32(y)) + i32(x)] = interpolated_reciprocal_w
    }
}

draw_textured_triangle :: proc(triangle: Triangle, texture: []u32) {
    p := triangle.points
    t := triangle.texcoords
    if p[0].y > p[1].y {
        swap(&p[0].y, &p[1].y)
        swap(&p[0].x, &p[1].x)
        swap(&p[0].z, &p[1].z)
        swap(&p[0].w, &p[1].w)
        swap(&t[0].u, &t[1].u)
        swap(&t[0].v, &t[1].v)
    }
    if p[1].y > p[2].y {
        swap(&p[1].y, &p[2].y)
        swap(&p[1].x, &p[2].x)
        swap(&p[1].z, &p[2].z)
        swap(&p[1].w, &p[2].w)
        swap(&t[1].u, &t[2].u)
        swap(&t[1].v, &t[2].v)
    }
    if p[0].y > p[1].y {
        swap(&p[0].y, &p[1].y)
        swap(&p[0].x, &p[1].x)
        swap(&p[0].z, &p[1].z)
        swap(&p[0].w, &p[1].w)
        swap(&t[0].u, &t[1].u)
        swap(&t[0].v, &t[1].v)
    }

    t[0].v = 1 - t[0].v
    t[1].v = 1 - t[1].v
    t[2].v = 1 - t[2].v

    point_a := p[0]
    point_b := p[1]
    point_c := p[2]

    // render flat bottom (top) triangle
    inv_slope_1: f32 = 0
    inv_slope_2: f32 = 0

    if p[1].y - p[0].y != 0 do inv_slope_1 = (p[1].x - p[0].x) / math.abs(p[1].y - p[0].y)
    if p[2].y - p[0].y != 0 do inv_slope_2 = (p[2].x - p[0].x) / math.abs(p[2].y - p[0].y)

    // don't render a triangle perpendicular to camera (a line)
    if p[1].y - p[0].y != 0 {
        for y := p[0].y; y <= p[1].y; y += 1 {
            x_start := p[1].x + (y - p[1].y) * inv_slope_1
            x_end := p[0].x + (y - p[0].y) * inv_slope_2

            if x_end < x_start do swap(&x_start, &x_end)

            for x := x_start; x <= x_end; x += 1 {
                // draw_pixel(x, y, 0xFFFF00FF)
                draw_triangle_texel(x, y, texture, point_a, point_b, point_c, t[0], t[1], t[2])
            }
        }
    }

    // render flat top (bottom) triangle
    inv_slope_1 = 0
    inv_slope_2 = 0

    if p[2].y - p[1].y != 0 do inv_slope_1 = (p[2].x - p[1].x) / math.abs(p[2].y - p[1].y)
    if p[2].y - p[0].y != 0 do inv_slope_2 = (p[2].x - p[0].x) / math.abs(p[2].y - p[0].y)

    // don't render a triangle perpendicular to camera (a line)
    if p[2].y - p[1].y != 0 {
        for y := p[1].y; y <= p[2].y; y += 1 {
            x_start := p[1].x + (y - p[1].y) * inv_slope_1
            x_end := p[0].x + (y - p[0].y) * inv_slope_2

            if x_end < x_start do swap(&x_start, &x_end)

            for x := x_start; x <= x_end; x += 1 {
                draw_triangle_texel(x, y, texture, point_a, point_b, point_c, t[0], t[1], t[2])
                // draw_pixel(x, y, 0xFFFF00FF)
            }
        }
    }
}

barycentric_weights :: proc(a: Vec2, b: Vec2, c: Vec2, p: Vec2) -> Vec3 {
    ac := c - a
    ab := b - a
    ap := p - a
    pc := c - p
    pb := b - p

    // cross product order matters!
    area_parallelogram_abc := cross(ac, ab)
    area_parallelogram_pbc := cross(pc, pb)
    area_parallelogram_pca := cross(ac, ap)

    alpha := area_parallelogram_pbc / area_parallelogram_abc
    beta := area_parallelogram_pca / area_parallelogram_abc
    gamma := 1 - alpha - beta
    return {alpha, beta, gamma}
}
