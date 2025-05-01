package main 

import "core:log"
import "core:image"
import "core:image/png"
import "core:mem"

Tex2 :: struct {
    u: f32,
    v: f32,
}

load_png_texture_data :: proc(filename: string) {
    img, err := image.load_from_file(filename)
    if err != nil {
        log.errorf("Trying to read image file %v returned %v\n", filename, err)
        return
    }

    pr("Image loaded:", img.width, "x", img.height, "channels:", img.channels)

    pixel_count := img.width * img.height
    g_texture = make([]u32, pixel_count)

    // Check if we have enough data
    if len(img.pixels.buf) < pixel_count * img.channels {
        log.errorf("Image data size mismatch: %v bytes for %v pixels with %v channels\n", 
                 len(img.pixels.buf), pixel_count, img.channels)
        return
    }

    // Safely convert pixels one by one
    src := img.pixels.buf[:]

    // unneeded, simply passed correct sdl.PixelFormat to texture
    // for i := 0; i < pixel_count; i += 1 {
    //     base := i * img.channels
    //
    //     // Default values in case we don't have enough channels
    //     r, g, b, a: u8 = 0, 0, 0, 255
    //
    //     // Read available channels
    //     // png are in RGBA format
    //     if base < len(src) {
    //         r = src[base]
    //     } 
    //     if base+1 < len(src) {
    //         g = src[base+1]
    //     } 
    //     if base+2 < len(src) {
    //         b = src[base+2]
    //     } 
    //     if img.channels >= 4 && base+3 < len(src) {
    //         a = src[base+3]
    //     }
    //
    //     g_texture[i] = (u32(a) << 24) | (u32(b) << 16) | (u32(g) << 8) | u32(r)
    // }

    g_texture = mem.slice_data_cast([]u32, src)

    g_texture_width = i32(img.width)
    g_texture_height = i32(img.height)
    pr("Texture conversion completed successfully")
}
