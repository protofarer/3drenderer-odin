package main

import "core:os"
import "core:text/scanner"
import "core:log"
import "core:strconv"
import "core:strings"
import "core:image"

Mesh :: struct {
    vertices: [dynamic]Vec3,
    faces: [dynamic]Face,
    texture: Texture,
    scale: Vec3,
    rotation: Vec3,
    translation: Vec3,
}

Mesh_Initialization_Params :: struct {
    obj_file: string,
    tex_file: Maybe(string),
    scale: Vec3,
    translation: Vec3,
    rotation: Vec3,
}

init_mesh :: proc(filepath: string, scale: Vec3, translation: Vec3, rotation: Vec3) -> (Mesh, bool) {
    vertices, faces, ok_obj := load_obj_file_data(filepath)
    if !ok_obj {
        log.errorf("Failed to load object file:", filepath)
        return {}, false
    }
    mesh := Mesh{
        scale = scale,
        translation = translation,
        rotation = rotation,
        vertices = vertices,
        faces = faces,
    }
    return mesh, true
}

// Handles triangles only
load_obj_file_data :: proc(filename: string) -> (out_vertices: [dynamic]Vec3, out_faces: [dynamic]Face, ok: bool) {
    raw_data, read_ok := os.read_entire_file_from_filename(filename)
    if !read_ok {
        log.error("Error reading file:", filename)
        return nil, nil, false
    }
    defer delete(raw_data)

    vertices: [dynamic]Vec3
    faces: [dynamic]Face
    tex_coords: [dynamic]Tex2
    defer delete(tex_coords)

    string_data := string(raw_data)
    lines, _ok := strings.split(string_data, "\n")
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
    return vertices, faces, true
}
