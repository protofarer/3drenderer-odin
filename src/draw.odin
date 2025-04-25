package main

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

draw_rect_filled_i32 :: proc(x: i32, y: i32, w: i32, h:i32, color: u32) {
    for y_i in y..<y+h {
        for x_i in x..<x+w {
            draw_pixel(x_i, y_i, color)
        }
    }
}

draw_rect_filled_f32 :: proc(x: f32, y: f32, w: f32, h:f32, color: u32) {
    for y_i in i32(y)..<i32(y+h) {
        for x_i in i32(x)..<i32(x+w) {
            draw_pixel(x_i, y_i, color)
        }
    }
}

draw_pixel :: proc {
    draw_pixel2,
    draw_pixel3,
}

draw_pixel2 :: proc(x: i32, y: i32, color: u32) {
    condition := x >= 0 && x < app.window_w && y >= 0 && y < app.window_h
    assert(condition, "Pixel must be within window bounds")
    app.color_buffer[(app.window_w * y) + x] = color
}

draw_pixel3 :: proc(x: f32, y: f32, color: u32) {
    condition := x >= 0 && x < f32(app.window_w) && y >= 0 && y < f32(app.window_h)
    assert(condition, "Pixel must be within window bounds")
    app.color_buffer[(app.window_w * i32(y)) + i32(x)] = color
}
