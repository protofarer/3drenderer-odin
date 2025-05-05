package main

Camera :: struct {
    position: Vec3,
    direction: Vec3,
    forward_velocity: Vec3,
    yaw: f32,
    pitch: f32,
}

init_camera :: proc() {
    g_camera = { 
        position = {},
        direction = {0,0,1},
    }
}

mat4_look_at :: proc(eye: Vec3, target: Vec3, up: Vec3) -> Mat4 {
    z := target - eye
    normalize(&z)
    x := cross(up, z)
    normalize(&x)
    y := cross(z, x)

    m: Mat4
    m = {
        x.x, x.y, x.z, -dot(x,eye),
        y.x, y.y, y.z, -dot(y,eye),
        z.x, z.y, z.z, -dot(z,eye),
        0,   0,   0,   1,
    }
    return m
}

get_camera_position :: proc() -> Vec3 {
    return g_camera.position
}

get_camera_forward_velocity :: proc() -> Vec3 {
    return g_camera.forward_velocity
}

get_camera_direction :: proc() -> Vec3 {
    return g_camera.direction
}

get_camera_yaw :: proc() -> f32 {
    return g_camera.yaw
}

get_camera_pitch :: proc() -> f32 {
    return g_camera.pitch
}

update_camera_position :: proc(position: Vec3) {
    g_camera.position = position
}

update_camera_direction :: proc(direction: Vec3) {
    g_camera.direction = direction
}

update_camera_forward_velocity :: proc(forward_velocity: Vec3) {
    g_camera.forward_velocity = forward_velocity
}

rotate_camera_yaw :: proc(angle: f32) {
    g_camera.yaw += angle
}

rotate_camera_pitch :: proc(angle: f32) {
    g_camera.pitch += angle
}

update_camera_lookat_target :: proc() {
    // Init target looking down z-axis
    target := Vec3{0, 0, 1}

    camera_yaw_rotation := mat4_make_rotation_y(g_camera.yaw)
    camera_pitch_rotation := mat4_make_rotation_x(g_camera.pitch)

    rotation_matrix := mat4_identity()
    rotation_matrix = mat4_mul_mat4(camera_pitch_rotation, rotation_matrix)
    rotation_matrix = mat4_mul_mat4(camera_yaw_rotation, rotation_matrix)
    direction := mat4_mul_vec4(rotation_matrix, vec4_from_vec3(target))
    update_camera_direction(vec3_from_vec4(direction))
}

get_camera_target :: proc() -> Vec3 {
    target := g_camera.position + g_camera.direction
    return target
}
