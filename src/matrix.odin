package main

import "core:math"

Mat3 :: matrix[3, 3]f32
Mat4 :: matrix[4, 4]f32

// | 1 0 0 0 |
// | 0 1 0 0 |
// | 0 0 1 0 |
// | 0 0 0 1 |
mat4_identity :: proc() -> Mat4 {
    return {
        1,0,0,0,
        0,1,0,0,
        0,0,1,0,
        0,0,0,1,
    }
}

// | sx  0  0  0 |
// |  0 sy  0  0 |
// |  0  0 sz  0 |
// |  0  0  0  1 |
mat4_make_scale :: proc(s: Vec3) -> Mat4 {
    m := mat4_identity()
    m[0,0] = s.x
    m[1,1] = s.y
    m[2,2] = s.z
    return m
}

// | 1  0  0  tx |
// | 0  1  0  ty |
// | 0  0  1  tz |
// | 0  0  0  1  |
mat4_make_translation :: proc(t: Vec3) -> Mat4 {
    m := mat4_identity()
    m[0,3] = t.x
    m[1,3] = t.y
    m[2,3] = t.z
    return m
}

// | 1  0  0  0 |
// | 0  c -s  0 |
// | 0  s  c  0 |
// | 0  0  0  1 |
mat4_make_rotation_x :: proc(angle: f32) -> Mat4 {
    c := math.cos(angle)
    s := math.sin(angle)
    m := mat4_identity()
    m[1,1] = c
    m[1,2] = -s
    m[2,1] = s
    m[2,2] = c
    return m
}

// |  c  0  s  0 |
// |  0  1  0  0 |
// | -s  0  c  0 |
// |  0  0  0  1 |
mat4_make_rotation_y :: proc(angle: f32) -> Mat4 {
    c := math.cos(angle)
    s := math.sin(angle)
    m := mat4_identity()
    m[0,0] = c
    m[0,2] = s
    m[2,0] = -s
    m[2,2] = c
    return m
}

// | c -s  0  0 |
// | s  c  0  0 |
// | 0  0  1  0 |
// | 0  0  0  1 |
mat4_make_rotation_z :: proc(angle: f32) -> Mat4 {
    c := math.cos(angle)
    s := math.sin(angle)
    m := mat4_identity()
    m[0,0] = c
    m[0,1] = -s
    m[1,0] = s
    m[1,1] = c
    return m
}

mat4_mul_vec4 :: proc(m: Mat4, v: Vec4) -> Vec4 {
    out: Vec4
    out.x = m[0, 0] * v.x + m[0, 1] * v.y + m[0, 2] * v.z + m[0, 3] * v.w
    out.y = m[1, 0] * v.x + m[1, 1] * v.y + m[1, 2] * v.z + m[1, 3] * v.w
    out.z = m[2, 0] * v.x + m[2, 1] * v.y + m[2, 2] * v.z + m[2, 3] * v.w
    out.w = m[3, 0] * v.x + m[3, 1] * v.y + m[3, 2] * v.z + m[3, 3] * v.w
    return out
}

mat4_mul_mat4 :: proc(a: Mat4, b: Mat4) -> Mat4 {
    m: Mat4
    for i in 0..<4 {
        for j in 0..<4 {
            m[i,j] = a[i,0]*b[0,j] + a[i,1]*b[1,j] + a[i,2]*b[2,j] + a[i,3]*b[3,j]
        }
    }
    return m
}

mat4_make_perspective :: proc(fov: f32, aspect: f32, znear: f32, zfar: f32) -> Mat4 {
    m: Mat4
    k := (1 / math.tan(fov / 2))
    m[0,0] = aspect * k
    m[1,1] = k
    m[2,2] = (-zfar * znear) / (zfar - znear)
    m[3,2] = 1
    return m
}

mat4_mul_vec4_project :: proc(mat_proj: Mat4, v: Vec4) -> Vec4 {
    out := mat4_mul_vec4(mat_proj, v)
    if out.w != 0 {
        out.x /= out.w
        out.y /= out.w
        out.z /= out.w
    }
    return out
}
