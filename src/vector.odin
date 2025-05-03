package main

import "core:math"

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32

normalize :: proc {
    normalize_vec2,
    normalize_vec3,
}

normalize_vec2 :: proc(v: ^Vec2) {
    l := length(v^)
    if l == 0 do return
    v.x /= l
    v.y /= l
}

normalize_vec3 :: proc(v: ^Vec3) {
    l := length(v^)
    if l == 0 do return
    v.x /= l
    v.y /= l
    v.z /= l
}

length :: proc {
    length_vec2,
    length_vec3,
}

length_vec2 :: proc(v: Vec2) -> f32 {
    return math.sqrt(v.x * v.x + v.y * v.y)
}

length_vec3 :: proc(v: Vec3) -> f32 {
    return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
}

vec2_new :: proc(x: f32, y: f32) -> Vec2 {
    return {x, y}
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

cross :: proc {
    vec2_cross,
    vec3_cross,
}

vec2_cross :: proc(a: Vec2, b: Vec2) -> f32 {
    return a.x * b.y - a.y * b.x
}

vec3_cross :: proc(a: Vec3, b: Vec3) -> Vec3 {
    return Vec3{
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x,
    }
}

dot :: proc {
    vec3_dot,
}

vec3_dot :: proc(a: Vec3, b: Vec3) -> f32 {
    return (a.x * b.x) + (a.y * b.y) + (a.z * b.z)
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
    return v.xyz
}
