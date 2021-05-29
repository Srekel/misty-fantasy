//------------------------------------------------------------------------------
//  texcube.zig
//
//  Texture creation, rendering with texture, packed vertex components.
//------------------------------------------------------------------------------
const std = @import("std");
const sg = @import("sokol").gfx;
const sapp = @import("sokol").app;
const sgapp = @import("sokol").app_gfx_glue;
const vec2 = @import("shaders/sokol_math.zig").Vec2;
const vec3 = @import("shaders/sokol_math.zig").Vec3;
const mat4 = @import("shaders/sokol_math.zig").Mat4;
const shd = @import("shaders/heightmap.glsl.zig");
const zigimg = @import("zigimg");
const nooice = @import("nooice");
const terrain_generation = @import("src/terrain_generation.zig");

const c = @cImport({
    @cInclude("DDSLoader/src/dds.h");
});

const state = struct {
    var rx: f32 = 0.0;
    var ry: f32 = 0.0;
    var pass_action: sg.PassAction = .{};
    var pip: sg.Pipeline = .{};
    var bind: sg.Bindings = .{};
    // const view: mat4 = mat4.lookat(.{ .x = 0, .y = 5.0, .z = 0 }, vec3.zero(), vec3.up());
    const view: mat4 = mat4.lookat(.{ .x = 1, .y = 1, .z = 2 }, .{ .x = 0, .y = 0, .z = 0 }, vec3.up().mul(1));
};

// a vertex struct with position, color and uv-coords
const VertexHeightmap = packed struct { height: f32, u: i16, v: i16 };
const Vertex = packed struct { x: f32, y: f32, z: f32, u: i16, v: i16 };

export fn init() void {
    sg.setup(.{ .context = sgapp.context() });
    var allocator = std.heap.GeneralPurposeAllocator(.{}){};

    // Cube vertex buffer with packed vertex formats for color and texture coords.
    // Note that a vertex format which must be portable across all
    // backends must only use the normalized integer formats
    // (BYTE4N, UBYTE4N, SHORT2N, SHORT4N), which can be converted
    // to floating point formats in the vertex shader inputs.
    // The reason is that D3D11 cannot convert from non-normalized
    // formats to floating point inputs (only to integer inputs),
    // and WebGL2 / GLES2 don't support integer vertex shader inputs.
    // const heightmap = zigimg.image.Image.fromFilePath(&allocator.allocator, "data/heightmap.png") catch unreachable;

    terrain_generation.make_heightmap(&allocator.allocator, 512, 512) catch unreachable;

    // const heightmap_info: zigimg.image.ImageInfo = .{
    //     .width = 1024,
    //     .height = 1024,
    //     .pixel_format = .Grayscale16,
    // };
    // const heightmap = zigimg.image.Image.fromFilePathAsHeaderless(&allocator.allocator, "data/heightmap.raw", heightmap_info) catch unreachable;
    const heightmap = zigimg.image.Image.fromFilePath(&allocator.allocator, "data/gen/heightmap.pgm") catch unreachable;
    // const vertices = [_]Vertex{
    //     // pos                         color              texcoords
    //     .{ .x = -1.0, .y = 0, .z = -1.0, .u = 0, .v = 0 },
    //     .{ .x = -1.0, .y = 0, .z = 1.0, .u = 32767, .v = 0 },
    //     .{ .x = 1.0, .y = 0, .z = 1.0, .u = 32767, .v = 32767 },
    //     .{ .x = 1.0, .y = 0, .z = -1.0, .u = 0, .v = 32767 },
    // };

    // state.bind.vertex_buffers[0] = sg.makeBuffer(.{ .data = sg.asRange(vertices) });

    // const indices = [_]u16{ 0, 1, 2, 0, 2, 3 };
    // state.bind.index_buffer = sg.makeBuffer(.{ .type = .INDEXBUFFER, .data = sg.asRange(indices) });

    // const vertices_hm = [_]VertexHeightmap{
    //     .{ .height = 0, .u = 0, .v = 0 },
    //     .{ .height = 0, .u = 0, .v = 32767 },
    //     .{ .height = 0, .u = 32767, .v = 32767 },
    //     .{ .height = 0.5, .u = 32767, .v = 0 },
    // };
    // const indices_hm = [_]u32{ 0, 1, 2, 0, 2, 3 };

    var vertices_hm = allocator.allocator.alloc(VertexHeightmap, heightmap.height * heightmap.width) catch unreachable;
    defer allocator.allocator.free(vertices_hm);
    {
        const seed = 0;
        var y: usize = 0;
        while (y < heightmap.height) : (y += 1) {
            var x: usize = 0;
            while (x < heightmap.width) : (x += 1) {
                var xf = @intToFloat(f32, x);
                var yf = @intToFloat(f32, y);
                var i = x + y * heightmap.width;
                var v = &vertices_hm[i];
                var gs = heightmap.pixels.?.Grayscale16[i].value;
                var height_f64 = @intToFloat(f64, gs);
                // var height_f64 = (std.math.sin(xf * 0.01) + std.math.cos(yf * 0.02)) * 0.1;
                // v.*.height = (nooice.fbm.noise_fbm_2d(xf, yf, seed, 5, 0.5, 300) * 1 + 0.5) * 0.2;
                // v.*.height = (nooice.fbm.noise_fbm_2d(xf, yf, seed, 1, 0.5, 100) * 0.2) + 0.5;
                // v.*.height = nooice.noise.noise_normalized(nooice.fbm.noise_2d(@intCast(u32, x), @intCast(u32, y), seed), f32) * 0.1;
                // v.*.height = nooice.coherent.noise_coherent_2d(xf * 0.01, yf * 0.01, seed) * 0.2;
                v.*.height = @floatCast(f32, height_f64 / @as(f32, std.math.maxInt(u16))) * 0.3 - 0.15;
                // v.*.height = -@floatCast(f32, height_f64);
                v.*.u = @floatToInt(i16, @as(f32, 32767.0) * xf / @intToFloat(f32, heightmap.width));
                v.*.v = @floatToInt(i16, @as(f32, 32767.0) * yf / @intToFloat(f32, heightmap.height));
                // std.debug.print("i: {any}, v: {any}\n", .{ i, v.* });
            }
        }
    }

    var indices_hm = allocator.allocator.alloc(u32, (heightmap.height - 1) * (heightmap.width - 1) * 6) catch unreachable;
    defer allocator.allocator.free(indices_hm);
    {
        var i: u32 = 0;
        var y: u32 = 0;
        const width = @intCast(u32, heightmap.width);
        const height = @intCast(u32, heightmap.height);
        while (y < height - 1) : (y += 1) {
            var x: u32 = 0;
            while (x < width - 1) : (x += 1) {
                const indices_quad = [_]u32{
                    x + y * width,
                    x + (y + 1) * width,
                    x + 1 + y * width,
                    x + 1 + (y + 1) * width,
                };

                indices_hm[i + 0] = indices_quad[0];
                indices_hm[i + 1] = indices_quad[1];
                indices_hm[i + 2] = indices_quad[2];

                indices_hm[i + 3] = indices_quad[2];
                indices_hm[i + 4] = indices_quad[1];
                indices_hm[i + 5] = indices_quad[3];
                // std.debug.print("quad: {any}\n", .{indices_quad});
                // std.debug.print("indices: {any}\n", .{indices_hm[i .. i + 6]});
                // std.debug.print("tri: {any} {any} {any}\n", .{
                //     vertices_hm[indices_hm[i + 0]],
                //     vertices_hm[indices_hm[i + 1]],
                //     vertices_hm[indices_hm[i + 2]],
                // });
                // std.debug.print("tri: {any} {any} {any}\n", .{
                //     vertices_hm[indices_hm[i + 3]],
                //     vertices_hm[indices_hm[i + 4]],
                //     vertices_hm[indices_hm[i + 5]],
                // });
                i += 6;
            }
        }
    }

    state.bind.vertex_buffers[0] = sg.makeBuffer(.{ .data = sg.asRange(vertices_hm) });
    state.bind.index_buffer = sg.makeBuffer(.{ .type = .INDEXBUFFER, .data = sg.asRange(indices_hm) });

    // Splatmat Texture
    const splatmap = zigimg.image.Image.fromFilePath(&allocator.allocator, "data/gen/splatmap.pgm") catch unreachable;
    defer splatmap.deinit();
    std.debug.print("pixel format: {s}\n", .{splatmap.pixel_format});
    // std.debug.assert(splatmap.pixel_format == zigimg.PixelFormat.Rgba32);

    const pixels_splatmap = splatmap.pixels.?.Grayscale8;
    var img_desc_splatmap: sg.ImageDesc = .{
        .width = @intCast(i32, splatmap.width),
        .height = @intCast(i32, splatmap.height),
        .pixel_format = .R8,
    };
    img_desc_splatmap.data.subimage[0][0] = sg.asRange(pixels_splatmap);
    state.bind.fs_images[shd.SLOT_splatmapTex] = sg.makeImage(img_desc_splatmap);

    // Grass Texture
    // const grassdds = c.dds_load("data/terrain/Rock007_1K_Color_bc7.dds");
    // defer c.dds_free(grassdds);
    // std.debug.print("dds: {any}\n", .{grassdds.*});
    const grass = zigimg.image.Image.fromFilePath(&allocator.allocator, "data/terrain/Grass004_1K_Color_8.png") catch unreachable;
    defer grass.deinit();
    std.debug.print("pixel format: {s}\n", .{grass.pixel_format});
    // const grassdata = grassdds.*.blBuffer[0 .. grassdds.*.dwWidth * grassdds.*.dwHeight * 4];
    // const grassdata = grassdds.*.blBuffer[0..grassdds.*.dwBufferSize];
    std.debug.assert(grass.pixel_format == zigimg.PixelFormat.Rgba32);

    const pixels_grass = grass.pixels.?.Rgba32;
    var img_desc_grass: sg.ImageDesc = .{
        .width = @intCast(i32, grass.width),
        .height = @intCast(i32, grass.height),
        .pixel_format = .RGBA8,
        // .pixel_format = .R8,
    };
    img_desc_grass.data.subimage[0][0] = sg.asRange(pixels_grass);
    state.bind.fs_images[shd.SLOT_grassTex] = sg.makeImageWithMipmaps(img_desc_grass);

    // Rock Texture
    // var rockdds = c.dds_load("data/terrain/Rock007_1K_Color_bc7.dds").*;
    // defer c.dds_free(&rockdds);
    // std.debug.print("dds: {any}\n", .{rockdds});
    // const grassdata = grassdds.*.blBuffer[0 .. grassdds.*.dwWidth * grassdds.*.dwHeight * 4];
    // const rockdata = rockdds.blBuffer[0..rockdds.dwBufferSize];

    const rock = zigimg.image.Image.fromFilePath(&allocator.allocator, "data/terrain/Rock007_1K_Color_8.png") catch unreachable;
    defer rock.deinit();
    std.debug.print("pixel format: {s}\n", .{rock.pixel_format});
    std.debug.assert(rock.pixel_format == zigimg.PixelFormat.Rgba32);

    const pixels_rock = rock.pixels.?.Rgba32;
    var img_desc_rock: sg.ImageDesc = .{
        .width = @intCast(i32, rock.width),
        .height = @intCast(i32, rock.height),
        .pixel_format = .RGBA8,
        // .pixel_format = .BC7_RGBA,
        // .num_mipmaps = 11,
    };
    img_desc_rock.data.subimage[0][0] = sg.asRange(pixels_rock);
    state.bind.fs_images[shd.SLOT_rockTex] = sg.makeImageWithMipmaps(img_desc_rock);

    // shader and pipeline object
    var pip_desc_hm: sg.PipelineDesc = .{
        .shader = sg.makeShader(shd.heightmapShaderDesc(sg.queryBackend())),
        .index_type = .UINT32,
        .depth = .{
            .compare = .LESS_EQUAL,
            .write_enabled = true,
        },
        .cull_mode = .BACK,
        // .cull_mode = .NONE,
        .face_winding = .CCW,
    };
    pip_desc_hm.layout.attrs[shd.ATTR_vs_height].format = .FLOAT;
    pip_desc_hm.layout.attrs[shd.ATTR_vs_texcoord0].format = .SHORT2N;
    state.pip = sg.makePipeline(pip_desc_hm);

    // pass action for clearing the frame buffer
    state.pass_action.colors[0] = .{ .action = .CLEAR, .value = .{ .r = 0.25, .g = 0.5, .b = 0.75, .a = 1 } };
}

export fn frame() void {
    // state.rx += 1.0;
    state.ry += 0.25;
    const vs_params = computeVsParams(state.rx, state.ry);

    sg.beginDefaultPass(state.pass_action, sapp.width(), sapp.height());
    sg.applyPipeline(state.pip);
    sg.applyBindings(state.bind);
    sg.applyUniforms(.VS, shd.SLOT_vs_params, sg.asRange(vs_params));
    sg.draw(0, 6 * 1023 * 1023, 1);
    sg.endPass();
    sg.commit();
}

export fn cleanup() void {
    sg.shutdown();
}

pub fn main() void {
    sapp.run(
        .{
            .init_cb = init,
            .frame_cb = frame,
            .cleanup_cb = cleanup,
            .width = 800,
            .height = 600,
            .sample_count = 4,
            .window_title = "Misty Fantasy",
        },
    );
}

var time: f32 = 0;
fn computeVsParams(rx: f32, ry: f32) shd.VsParams {
    time += 0.01;
    const rxm = mat4.rotate(rx, .{ .x = 1.0, .y = 0.0, .z = 0.0 });
    const rym = mat4.rotate(ry, .{ .x = 0.0, .y = 1.0, .z = 0.0 });
    const model = mat4.mul(rxm, rym);
    // const model = mat4.identity();
    const aspect = sapp.widthf() / sapp.heightf();
    const proj = mat4.persp(60.0, aspect, 0.01, 10.0);
    return shd.VsParams{
        // .vp = mat4.mul(proj, state.view),
        .vp = proj,
        .mvp = mat4.mul(mat4.mul(proj, state.view), model),
        .time = time,
        .screen_size = [2]f32{ sapp.widthf(), sapp.heightf() },
        // .screen_size = vec2.new(sapp.widthf(), sapp.heightf()),
    };
}
