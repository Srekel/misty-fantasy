//------------------------------------------------------------------------------
//  Shader code for heightmap-sapp sample.
//
//  NOTE: This source file also uses the '#pragma sokol' form of the
//  custom tags.
//------------------------------------------------------------------------------
#pragma sokol @ctype mat4 @import("sokol_math.zig").Mat4

#pragma sokol @vs vs
uniform vs_params {
    mat4 vp;
    mat4 mvp;
    vec2 screen_size;
    float time;
};

in float height;
// in vec4 pos;
in vec2 texcoord0;

out vec2 fs_uv;
out float fs_time;
out vec2 fs_screen_size;
out mat4 fs_vp_inv;
out vec3 fs_pos;

void main() {
    vec4 pos = vec4((texcoord0.x - 0.5) * 2, height, (texcoord0.y - 0.5) * 2, 1);
    gl_Position = mvp * pos;
    fs_uv = texcoord0;
    fs_time = time;
    fs_screen_size = screen_size;
    fs_vp_inv = inverse(vp);
    fs_pos = pos.xyz;
}
#pragma sokol @end

#pragma sokol @fs fs
uniform fs_params {
    mat4 mvp;
    float time;
};

uniform sampler2D splatmapTex;
uniform sampler2D rockTex;
uniform sampler2D grassTex;

in vec2 fs_uv;
in float fs_time;
in vec2 fs_screen_size;
in mat4 fs_vp_inv;
in vec3 fs_pos;
out vec4 frag_color;

void main() {
    // Convert screen coordinates to normalized device coordinates (NDC)
//     vec4 ndc = vec4(
//         (gl_FragCoord.x / fs_screen_size.x - 0.5) * 2.0,
//         (gl_FragCoord.y / fs_screen_size.y - 0.5) * 2.0,
//         (gl_FragCoord.z - 0.5) * 2.0,
//         1.0);

//  // Convert NDC throuch inverse clip coordinates to view coordinates
//     vec4 clip = fs_vp_inv * ndc;
//     vec3 vertex = (clip / clip.w).xyz;

    // float water = step(-0.2, vertex.y);
    // float water = step(0, fs_pos.y);
    float water = 1;
    // frag_color = texture(tex, fs_uv).wzyx * water + mix(vec4(0.3,0.3,1,1), vec4(0,0,1,1),fs_pos.y+0.15)*(1-water);
    // frag_color = texture(tex, fs_uv).x * water +  vec4(0,0,1,1)*(1-water);
    int splat = int(textureLod(splatmapTex, fs_uv, 0).xxxx * 255);
    if(splat == 0) {
        // frag_color = texture(text, fs_uv);
        frag_color = vec4(0, 0, 1, 1);
    } else if(splat == 64) {
        // frag_color = vec4(0, 1, 0, 1);
        frag_color = texture(grassTex, fs_uv * 8).wzyx;
    } else {
        // frag_color = vec4(0.25, 0.25, 0.25, 1);
        // float mipmapLevel = textureQueryLod(rockTex, fs_uv * 8).x;
        frag_color = texture(rockTex, fs_uv * 8).wzyx;
        // frag_color = textureLod(rockTex, fs_uv * 32, 4).wzyx;
    }
    // frag_color = texture(tex, uv).wzyx;
    // frag_color = vec4(0,1,1,1);

}
#pragma sokol @end

#pragma sokol @program heightmap vs fs
