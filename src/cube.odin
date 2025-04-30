package main 

cube_mesh_vertices := [?]Vec3{
    {-1,-1,-1},
    {-1, 1,-1},
    { 1, 1,-1},
    { 1,-1,-1},
    { 1, 1, 1},
    { 1,-1, 1},
    {-1, 1, 1},
    {-1,-1, 1},
}

cube_mesh_faces := [?]Face{
    // front
    {
        a = 1,
        b = 2,
        c = 3,
        color = 0xFFFFFFFF,
    },
    {
        a = 1,
        b = 3,
        c = 4,
        color = 0xFFFFFFFF,
    },
    //right
    {
        a = 4,
        b = 3,
        c = 5,
        color = 0xFFFFFFFF,
    },
    {
        a = 4,
        b = 5,
        c = 6,
        color = 0xFFFFFFFF,
    },
    // back
    {
        a = 6,
        b = 5,
        c = 7,
        color = 0xFFFFFFFF,
    },
    {
        a = 6,
        b = 7,
        c = 8,
        color = 0xFFFFFFFF,
    },
    // left
    {
        a = 8,
        b = 7,
        c = 2,
        color = 0xFFFFFFFF,
    },
    {
        a = 8,
        b = 2,
        c = 1,
        color = 0xFFFFFFFF,
    },
    // top
    {
        a = 2,
        b = 7,
        c = 5,
        color = 0xFFFFFFFF,
    },
    {
        a = 2,
        b = 5,
        c = 3,
        color = 0xFFFFFFFF,
    },
    // bottom
    {
        a = 6,
        b = 8,
        c = 1,
        color = 0xFFFFFFFF,
    },
    {
        a = 6,
        b = 1,
        c = 4,
        color = 0xFFFFFFFF,
    },
}

load_cube_mesh_data :: proc() {
    for face in cube_mesh_faces {
        append(&g_mesh.faces, face)
    }
    for vertex in cube_mesh_vertices {
        append(&g_mesh.vertices, vertex)
    }
}
