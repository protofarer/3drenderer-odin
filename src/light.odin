package main
import "core:fmt"

Light :: struct {
    direction: Vec3,
}

init_light :: proc() {
    g_light = {
        direction = {0, 0, 1}
    }
}

light_apply_intensity :: proc(original_color: Color_Value, pct: f32) -> Color_Value {
    pct := pct
    if pct < 0 do pct = 0
    else if pct > 1 do pct = 1

    a := original_color & 0xFF000000
    r := (original_color & 0x00FF0000) >> 16 // shift bytes right for proper multiplication
    g := (original_color & 0x0000FF00) >> 8
    b := (original_color & 0x000000FF)

    g = u32(f32(g) * pct)
    r = u32(f32(r) * pct)
    b = u32(f32(b) * pct)

    r = min(r, 0xFF)
    g = min(g, 0xFF)
    b = min(b, 0xFF)

    return a | (r << 16) | (g << 8) | b
}
