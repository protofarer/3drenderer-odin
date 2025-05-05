package main

Camera :: struct {
    position: Vec3,
    direction: Vec3,
    forward_velocity: Vec3,
    yaw: f32,
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
