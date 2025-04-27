package main

import "core:math"
import "core:math/linalg"

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32

vec2_new :: proc(x: f32, y: f32) -> Vec2 {
    return {x, y}
}

normalize :: proc {
    normalize_vec2,
    normalize_vec3,
}

normalize_vec2 :: proc(v: ^Vec2) {
    v^ = linalg.normalize0(v^)
}

normalize_vec3 :: proc(v: ^Vec3) {
    v^ = linalg.normalize0(v^)
}

vec3_new :: proc(x: f32, y: f32, z: f32) -> Vec3 {
    return {x, y, z}
}

vec3_clone :: proc(v: Vec3) -> Vec3 {
    return v.xyz
}

vec3_invert :: proc(v: ^Vec3) {
    v^ *= -1
}

vec3_normal :: proc(a: Vec3, b: Vec3) -> Vec3 {
    cross := linalg.cross(a, b)
    magnitude := linalg.length(cross)
    return cross / magnitude
}

vec3_rotate_x :: proc(v: Vec3, angle: f32) -> Vec3 {
    return {
        v.x,
        v.y * math.cos(angle) - v.z * math.sin(angle),
        v.y * math.sin(angle) + v.z * math.cos(angle),
    }
}

vec3_rotate_y :: proc(v: Vec3, angle: f32) -> Vec3 {
    return {
        v.x * math.cos(angle) - v.z * math.sin(angle),
        v.y,
        v.x * math.sin(angle) + v.z * math.cos(angle),
    }
}

vec3_rotate_z :: proc(v: Vec3, angle: f32) -> Vec3 {
    return {
        v.x * math.cos(angle) - v.y * math.sin(angle),
        v.x * math.sin(angle) + v.y * math.cos(angle),
        v.z,
    }
}

vec4_from_vec3 :: proc(v: Vec3) -> Vec4 {
    return {v.x, v.y, v.z, 1}
}

vec3_from_vec4 :: proc(v: Vec4) -> Vec3 {
    return {v.x, v.y, v.z}
}

vec2_from_vec4 :: proc(v: Vec4) -> Vec2 {
    return {v.x, v.y}
}
