package main

import "core:math"

DEFAULT_COLOR :: 0xFFFFFFFF
Color_Value :: u32

draw_grid :: proc() {
    d :: 20
    for y in 0..<app.window_h/d {
        for x in 0..<app.window_w/d {
            draw_pixel(x * d, y * d, 0xFF006600)
        }
    }
}

draw_rect_filled :: proc {
    draw_rect_filled_f32,
    draw_rect_filled_i32,
}

draw_rect_filled_i32 :: proc(x: i32, y: i32, w: i32, h:i32, color: Color_Value = DEFAULT_COLOR) {
    for y_i in y..<y+h {
        for x_i in x..<x+w {
            draw_pixel(x_i, y_i, color)
        }
    }
}

draw_rect_filled_f32 :: proc(x: f32, y: f32, w: f32, h:f32, color: Color_Value = DEFAULT_COLOR) {
    for y_i in i32(y)..<i32(y+h) {
        for x_i in i32(x)..<i32(x+w) {
            draw_pixel(x_i, y_i, color)
        }
    }
}

draw_pixel :: proc {
    draw_pixel_i32,
    draw_pixel_f32,
}

draw_pixel_i32 :: proc(x: i32, y: i32, color: Color_Value = DEFAULT_COLOR) {
    condition := x < 0 || x >= app.window_w || y < 0 || y >= app.window_h
    if !condition {
        g_color_buffer[(app.window_w * y) + x] = color
    }
}

draw_pixel_f32 :: proc(x: f32, y: f32, color: Color_Value = DEFAULT_COLOR) {
    condition := x < 0 || x >= f32(app.window_w) || y < 0 || y >= f32(app.window_h)
    if !condition {
        g_color_buffer[(app.window_w * i32(y)) + i32(x)] = color
    }
}

draw_line :: proc {
    draw_line_i32,
    draw_line_f32,
}

draw_line_i32 :: proc(x0, y0, x1, y1: i32, color: Color_Value = DEFAULT_COLOR) {
    dx := x1 - x0
    dy := y1 - y0

    sx := abs(dx)
    sy := abs(dy)
    side_length := sx >= sy ? sx : sy

    inc_x := f32(dx) / f32(side_length)
    inc_y := f32(dy) / f32(side_length)

    curr_x : f32 = f32(x0)
    curr_y : f32 = f32(y0)

    for i in 0..<side_length {
        draw_pixel(math.round(curr_x), math.round(curr_y), color)
        curr_x += inc_x
        curr_y += inc_y
    }
}

draw_line_f32 :: proc(x0, y0, x1, y1: f32, color: Color_Value = DEFAULT_COLOR) {
    dx := x1 - x0
    dy := y1 - y0

    sx := abs(dx)
    sy := abs(dy)
    side_length := sx >= sy ? sx : sy

    inc_x := dx / side_length
    inc_y := dy / side_length

    curr_x := x0
    curr_y := y0

    for i in 0..<side_length {
        draw_pixel(math.round(curr_x), math.round(curr_y), color)
        curr_x += inc_x
        curr_y += inc_y
    }
}
