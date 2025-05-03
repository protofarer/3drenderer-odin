package main

import "core:math"

MAX_NUM_POLY_VERTICES :: 10
MAX_NUM_POLY_TRIANGLES :: 10

Frustrum_Plane :: enum {
    Left, Right, Top, Bottom, Near, Far
}

Plane :: struct {
    point: Vec3,
    normal: Vec3,
}

init_frustrum_planes :: proc(fov: f32, z_near: f32, z_far: f32) {
    cos_half := math.cos(fov/2)
    sin_half := math.sin(fov/2)

    origin: Vec3 = {0,0,0}
    g_frustrum_planes[.Left] = {
        point = origin,
        normal = {
            cos_half,
            0,
            sin_half,
        },
    }
    g_frustrum_planes[.Right] = {
        point = origin,
        normal = {
            -cos_half,
            0,
            sin_half,
        },
    }
    g_frustrum_planes[.Top] = {
        point = origin,
        normal = {
            0,
            -cos_half,
            sin_half,
        },
    }
    g_frustrum_planes[.Bottom] = {
        point = origin,
        normal = {
            0,
            cos_half,
            sin_half,
        },
    }
    g_frustrum_planes[.Near] = {
        normal = {0, 0, z_near},
        point = {
            0,
            0,
            1,
        },
    }
    g_frustrum_planes[.Far] = {
        normal = {0, 0, z_far},
        point = {
            0,
            0,
            -1,
        },
    }
}

clip_polygon_against_plane :: proc(polygon: ^Polygon, plane_type: Frustrum_Plane) {
    // clip new triangles algo
    plane_point := g_frustrum_planes[plane_type].point
    plane_normal := g_frustrum_planes[plane_type].normal

    inside_vertices: [MAX_NUM_POLY_VERTICES]Vec3
    num_inside_vertices := 0

    previous_vertex: Vec3 = polygon.vertices[polygon.num_vertices - 1]
    current_vertex: Vec3

    previous_dot: f32 = dot(previous_vertex - plane_point, plane_normal)
    current_dot: f32

    for i in 0..<polygon.num_vertices {
        current_vertex = polygon.vertices[i]
        current_dot := dot(current_vertex - plane_point, plane_normal)

        // the line formed by this pair of vertices intersects the plane
        if current_dot * previous_dot < 0 {
            t := previous_dot / (previous_dot - current_dot)
            intersection_point := previous_vertex + t * (current_vertex - previous_vertex)

            inside_vertices[num_inside_vertices] = intersection_point
            num_inside_vertices += 1
        }
        // don't forget to add inside ones, this is not exclusive to the above block
        if current_dot > 0 {
            inside_vertices[num_inside_vertices] = current_vertex
            num_inside_vertices += 1
        }

        previous_dot = current_dot
        previous_vertex = current_vertex
    }

    polygon.vertices = inside_vertices
    polygon.num_vertices = num_inside_vertices
}

clip_polygon :: proc(polygon: ^Polygon) {
    clip_polygon_against_plane(polygon, Frustrum_Plane.Left)
    clip_polygon_against_plane(polygon, Frustrum_Plane.Right)
    clip_polygon_against_plane(polygon, Frustrum_Plane.Top)
    clip_polygon_against_plane(polygon, Frustrum_Plane.Bottom)
    clip_polygon_against_plane(polygon, Frustrum_Plane.Near)
    clip_polygon_against_plane(polygon, Frustrum_Plane.Far)
}

create_polygon_from_triangle :: proc(v0: Vec3, v1: Vec3, v2: Vec3) -> Polygon {
    p: Polygon
    p.vertices[0] = v0
    p.vertices[1] = v1
    p.vertices[2] = v2
    p.num_vertices = 3
    return p
}

triangles_from_polygon :: proc(polygon: Polygon) -> ([MAX_NUM_POLY_TRIANGLES]Triangle, int) {
    triangles: [MAX_NUM_POLY_TRIANGLES]Triangle
    num_triangles_after_clipping: int
    index0 := 0
    for i := 0; i < polygon.num_vertices - 2; i += 1 {
        index1 := i + 1
        index2 := i + 2

        triangles[i].points[0] = vec4_from_vec3(polygon.vertices[index0])
        triangles[i].points[1] = vec4_from_vec3(polygon.vertices[index1])
        triangles[i].points[2] = vec4_from_vec3(polygon.vertices[index2])
    }
    num_triangles_after_clipping = polygon.num_vertices - 2
    return triangles, num_triangles_after_clipping
}
