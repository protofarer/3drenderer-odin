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

    string_data := string(raw_data)
    lines, ok := strings.split(string_data, "\n")
    for line in lines {
        if len(line) == 0 do continue

        splits := strings.split(line, " ")
        first_word := splits[0]
        switch first_word {
        case "v":
            vertex: Vec3
            for word, i in splits[1:4] {
                val := strconv.parse_f32(word) or_else 0
                vertex[i] = val
            }
            append(&vertices, vertex)
        case "f":
            face: Face
            for group, i in splits[1:4] {
                num_strings := strings.split(group, "/")
                val := strconv.parse_int(num_strings[0]) or_else 0
                if i == 0 {
                    face.a = val
                } else if i == 1 {
                    face.b = val
                } else if i == 2 {
                    face.c = val
                }
            }
            face.color = 0xFFFFFFFF
            append(&faces, face)
        case:
        }
    }
    g_mesh.vertices = vertices
    g_mesh.faces = faces
}

init_mesh :: proc() -> Mesh {
    return Mesh{scale = {1,1,1}}
}
