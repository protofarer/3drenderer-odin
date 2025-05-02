package main

import "core:os"
import "core:text/scanner"
import "core:log"
import "core:strconv"
import "core:strings"

// TODO: optimizations: face, vertex, etc.. de-duplication

Mesh :: struct {
    vertices: [dynamic]Vec3,
    faces: [dynamic]Face,
    scale: Vec3,
    rotation: Vec3,
    translation: Vec3,
}

// Handles triangles only
load_obj_file_data :: proc(filename: string) {
    raw_data, read_ok := os.read_entire_file_from_filename(filename)
    if !read_ok {
        log.error("Error reading file:", filename)
        return
    }
    defer delete(raw_data)

    vertices: [dynamic]Vec3
    faces: [dynamic]Face
    tex_coords: [dynamic]Tex2
    defer delete(tex_coords)

    string_data := string(raw_data)
    lines, ok := strings.split(string_data, "\n")
    for line in lines {
        if len(line) == 0 do continue

        splits := strings.split(line, " ")
        first_word := splits[0]
        switch first_word {
        case "v":
            vertex: Vec3
            vertex[0] = strconv.parse_f32(splits[1]) or_else 0
            vertex[1] = strconv.parse_f32(splits[2]) or_else 0
            vertex[2] = strconv.parse_f32(splits[3]) or_else 0
            append(&vertices, vertex)
        case "f":
            face: Face
            for group, i in splits[1:4] {
                val_strings := strings.split(group, "/")
                vertex_no := strconv.parse_int(val_strings[0]) or_else 0
                tex_coord_no := strconv.parse_int(val_strings[1]) or_else 0
                if i == 0 {
                    face.a = vertex_no - 1
                    face.a_uv = tex_coords[tex_coord_no - 1]
                } else if i == 1 {
                    face.b = vertex_no - 1
                    face.b_uv = tex_coords[tex_coord_no - 1]
                } else if i == 2 {
                    face.c = vertex_no - 1
                    face.c_uv = tex_coords[tex_coord_no - 1]
                }
            }
            face.color = 0xFFFFFFFF
            append(&faces, face)
        case "vt":
            tex_coord: Tex2
            tex_coord.u = strconv.parse_f32(splits[1]) or_else 0
            tex_coord.v = strconv.parse_f32(splits[2]) or_else 0
            append(&tex_coords, tex_coord)
        case:
        }
    }
    g_mesh.vertices = vertices
    g_mesh.faces = faces
}

init_mesh :: proc() -> Mesh {
    return Mesh{scale = {1,1,1}}
}
