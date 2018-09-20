//
//  shader.metal
//  MetalDemo
//
//  Created by Hobi on 2018/9/19.
//  Copyright © 2018年 Hobi. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

typedef struct
{
    float4 position;
    float2 texturePos;
} VertexIn;


typedef struct
{
    float4 position [[position]];
    float2 texturePos;
}VertexOut;



vertex VertexOut myVertexShader(const device VertexIn* vertexArray [[buffer(0)]],
                                unsigned int vid  [[vertex_id]]){
    
    VertexOut verOut;
    verOut.position = vertexArray[vid].position;
    verOut.texturePos = vertexArray[vid].texturePos;
    return verOut;
    
}


fragment half4 myFragmentShader(
                                 VertexOut input [[ stage_in ]],
                                 texture2d<half> colorTexture [[ texture(0) ]]
                                 )
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear); // sampler是采样器
    half4 colorSample = colorTexture.sample(textureSampler, input.texturePos); // 得到纹理对应位置的颜色
    return colorSample;
//    return float4(0, 0, 1, 1);
}

