//
//  Normals.metal
//  Planets
//
//  Created by Paul Delestrac on 19/04/2025.
//

#include <metal_stdlib>
using namespace metal;

float atomic_add_float(device atomic_int* address, float value) {
    int oldval, newval;
    do {
        oldval = atomic_load_explicit(address, memory_order_relaxed);
        newval = as_type<int>(as_type<float>(oldval) + value);
    } while (!atomic_compare_exchange_weak_explicit(address, &oldval, newval, memory_order_relaxed, memory_order_relaxed));
    return as_type<float>(oldval);
}

kernel void computeFaceNormals(
    device float3 *vertices [[buffer(0)]],
    device uint *indices [[buffer(1)]],
    device float3 *faceNormals [[buffer(2)]],
    constant uint &triangleCount [[buffer(3)]],
    uint tid [[thread_position_in_grid]]) {
    if (tid < triangleCount) {
        uint i = tid * 3;
        uint i0 = indices[i];
        uint i1 = indices[i + 1];
        uint i2 = indices[i + 2];

        if (i0 < triangleCount && i1 < triangleCount && i2 < triangleCount) {
            float3 p0 = vertices[i0];
            float3 p1 = vertices[i1];
            float3 p2 = vertices[i2];

            float3 v1 = p1 - p0;
            float3 v2 = p2 - p0;
            float3 normal = cross(v1, v2);

            // Normalize the normal vector
            faceNormals[tid] = normalize(normal);
        }
    }
}


kernel void computeVertexNormals(
    device uint *indices [[buffer(0)]],
    device float3 *faceNormals [[buffer(1)]],
    device float3 *vertexNormals [[buffer(2)]],
    constant uint &triangleCount [[buffer(3)]],
    constant uint &vertexCount [[buffer(4)]],
    uint vid [[thread_position_in_grid]]) {
    if (vid < vertexCount) {
        float3 normal = float3(0.0, 0.0, 0.0);
        int faceCount = 0;

        for (uint tid = 0; tid < triangleCount; ++tid) {
            uint i = tid * 3;
            uint i0 = indices[i];
            uint i1 = indices[i + 1];
            uint i2 = indices[i + 2];

            if (i0 == vid || i1 == vid || i2 == vid) {
                normal += faceNormals[tid];
                faceCount++;
            }
        }

        if (faceCount > 0) {
            vertexNormals[vid] = normalize(normal);
        } else {
            vertexNormals[vid] = float3(0.0, 1.0, 0.0); // Default normal
        }
    }
}
