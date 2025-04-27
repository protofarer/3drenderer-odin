package main

import "core:math/linalg"

Mat3 :: linalg.Matrix3f32
Mat4 :: linalg.Matrix4f32

mat4_identity :: proc() -> Mat4 {
    return linalg.identity(Mat4)
}

// TODO: vec4_t mat4_mul_vec4_project(mat4_t mat_proj, vec4_t v);


// lib 
// - matrix3_look_at matrix4_look_at
// - mat4 x mat4
// - mat3/4 scale translate
// - mat4 perspective
// mat4_t mat4_make_scale(float sx, float sy, float sz);
// mat4_t mat4_make_translation(float tx, float ty, float tz);

// - linalg.mul => 
    // matrix_mul,
    // matrix_mul_differ,
    // matrix_mul_vector, matrix_mul_vector(a: Mat, b: Vec)
// vec4_t mat4_mul_vec4(mat4_t m, vec4_t v);

// linalg.matrix4_from_euler_angle_x/y/z
// mat4_t mat4_make_rotation_x(float angle);
// mat4_t mat4_make_rotation_y(float angle);
// mat4_t mat4_make_rotation_z(float angle);

// linalg.matrix4_perspective(fovy, aspect, near, far, flip_z_axis)
// mat4_t mat4_make_perspective(float fov, float aspect, float znear, float zfar);

