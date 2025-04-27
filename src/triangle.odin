package main

// Vertex indices, order matters
Face :: struct {
    indices: [3]int,
    color: Color_Value,
}

// Points of triangle in screen space
Triangle :: struct {
    points: [3]Vec2,
    color: Color_Value,
} 
