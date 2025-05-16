package main 

import "core:log"
import "core:image"
import "core:image/png"
import "core:mem"
import "core:slice"

Tex2 :: struct {
    u: f32,
    v: f32,
}

Texture :: struct {
    width: i32,
    height: i32,
    pixels: []u32,
    size: i32,
    // metadata: image.Image_Metadata
    // channels: int,
    // depth: int,
}

load_png_texture_data :: proc(filename: string) -> (texture: Texture, ok: bool) {
    img, err := image.load_from_file(filename)
    if err != nil {
        log.errorf("Trying to read image file %v returned %v\n", filename, err)
        return {}, false
    }
    defer free(img)
    // pr("Image loaded:", img.width, "x", img.height, "channels:", img.channels)

    pixel_count := img.width * img.height

    // Check if there's enough data
    if len(img.pixels.buf) < pixel_count * img.channels {
        log.errorf("Image data size mismatch: %v bytes for %v pixels with %v channels\n", 
                 len(img.pixels.buf), pixel_count, img.channels)
        return {}, false
    }

    pixels_u8 := slice.clone(img.pixels.buf[:])
    pixels_u32 := mem.slice_data_cast([]u32, pixels_u8)

    out_texture := Texture {
        width = i32(img.width),
        height = i32(img.height),
        size = i32(img.width * img.height),
        pixels = pixels_u32,
    }
    return out_texture, true
}
