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
        indices = {1,2,3},
        color = 0xFFFF0000,
    },
    {
        indices = {1,3,4},
        color = 0xFFFF0000,
    },
    //right
    {
        indices = {4,3,5},
        color = 0xFF00FF00,
    },
    {
        indices = {4,5,6},
        color = 0xFF00FF00,
    },
    // back
    {
        indices = {6,5,7},
        color = 0xFF0000FF,
    },
    {
        indices = {6,7,8},
        color = 0xFF0000FF,
    },
    // left
    {
        indices = {8,7,2},
        color = 0xFFFF00FF,
    },
    {
        indices = {8,2,1},
        color = 0xFFFF00FF,
    },
    // top
    {
        indices = {2,7,5},
        color = 0xFF00FFFF,
    },
    {
        indices = {2,5,3},
        color = 0xFF00FFFF,
    },
    // bottom
    {
        indices = {6,8,1},
        color = 0xFFFFFF00,
    },
    {
        indices = {6,1,4},
        color = 0xFFFFFF00,
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
