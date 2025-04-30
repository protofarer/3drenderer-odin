package main

// Vertex indices, order matters
Face :: struct {
    a: int,
    b: int,
    c: int,
    color: Color_Value,
    a_uv: Tex2,
    b_uv: Tex2,
    c_uv: Tex2,
}

Triangle :: struct {
    points: [3]Vec2,
    color: Color_Value,
    avg_depth: f32,
} 
