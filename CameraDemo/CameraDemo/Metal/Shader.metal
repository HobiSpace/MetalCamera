//
//  Shader.metal
//  CameraDemo
//
//  Created by Hobi on 2018/9/20.
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



vertex VertexOut vertexShader(const device VertexIn* vertexArray [[buffer(0)]],
                                unsigned int vid  [[vertex_id]]){
    
    VertexOut verOut;
    verOut.position = vertexArray[vid].position;
    verOut.texturePos = vertexArray[vid].texturePos;
    return verOut;
    
}


fragment half4 fragmentShader(
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

kernel void kernel_function(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            uint2 gid [[thread_position_in_grid]]) {
    
    float4 inColor = inTexture.read(gid);
    
    const float4 outColor = float4(inColor.x * 0.5, inColor.y * 0.5, inColor.z * 0.5, inColor.w * 0.5);
//    const float4 outColor = float4(pow(inColor.rgb, float3(0.4/* gamma校正参数 */)), inColor.a);
    
    outTexture.write(outColor, gid);
}
