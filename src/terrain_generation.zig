const std = @import("std");
const zigimg = @import("zigimg");
const nooice = @import("nooice");
usingnamespace @import("global.zig");

const height_max: f32 = 2000;
const height_max_normalized = 1;
const height_water: f32 = 200;
const height_water_normalized = height_water / height_max;
const height_mountain_base: f32 = 1000;
const height_mountain_base_normalized = height_mountain_base / height_max;

pub fn make_heightmap(allocator: *std.mem.Allocator, width: usize, height: usize) !void {
    println("make_heightmap begin");
    defer println("make_heightmap end");

    var heightmap_normalized = try allocator.alloc(f32, width * height);
    defer allocator.free(heightmap_normalized);

    {
        println("  fbm begin");
        defer println("  fbm end");
        const seed = 0;
        var y: usize = 0;
        while (y < height) : (y += 1) {
            var x: usize = 0;
            while (x < width) : (x += 1) {
                var xf = @intToFloat(f32, x);
                var yf = @intToFloat(f32, y);
                var fbm = nooice.fbm.noise_fbm_2d(xf, yf, seed, 5, 0.5, 300);
                var i = x + y * width;
                heightmap_normalized[i] = fbm;
            }
        }
    }

    {
        println("  scale begin");
        defer println("  scale end");
        const span = nooice.transform.get_span(f32, heightmap_normalized);
        nooice.transform.normalize(f32, heightmap_normalized, span.min, span.max);

        const curve: nooice.transform.Curve(f32, 8) = .{
            .points_x = [_]f32{ 0, height_water_normalized, 0.7, 1, 0, 0, 0, 0 },
            .points_y = [_]f32{ 0, height_water_normalized, height_mountain_base_normalized, 1, 0, 0, 0, 0 },
        };

        nooice.transform.scale_with_curve_linear(f32, heightmap_normalized, curve);
    }

    {
        println("  image begin");
        defer println("  image end");
        var img = try zigimg.Image.create(allocator, width, height, .Grayscale16, .Pgm);
        const seed = 0;
        var y: usize = 0;
        while (y < height) : (y += 1) {
            var x: usize = 0;
            while (x < width) : (x += 1) {
                const i = x + y * width;
                const value = @floatToInt(u16, heightmap_normalized[i] * @intToFloat(f32, std.math.maxInt(u16)));
                img.pixels.?.Grayscale16[i].value = value;
            }
        }

        var pgm_opt: zigimg.AllFormats.PGM.EncoderOptions = .{ .binary = true };
        const encoder_options = zigimg.AllFormats.ImageEncoderOptions{ .pgm = pgm_opt };
        try img.writeToFilePath("data/gen/heightmap.pgm", img.image_format, encoder_options);
    }

    {
        println("  splatmap begin");
        defer println("  splatmap end");
        var img = try zigimg.Image.create(allocator, width, height, .Grayscale8, .Pgm);
        const seed = 0;
        var y: usize = 0;
        while (y < height) : (y += 1) {
            var x: usize = 0;
            while (x < width) : (x += 1) {
                const i = x + y * width;
                const value = heightmap_normalized[i];
                if (value < height_water_normalized) {
                    img.pixels.?.Grayscale8[i].value = 0;
                } else if (value < height_mountain_base_normalized) {
                    img.pixels.?.Grayscale8[i].value = 64;
                } else {
                    img.pixels.?.Grayscale8[i].value = 128;
                }
            }
        }

        var pgm_opt: zigimg.AllFormats.PGM.EncoderOptions = .{ .binary = true };
        const encoder_options = zigimg.AllFormats.ImageEncoderOptions{ .pgm = pgm_opt };
        try img.writeToFilePath("data/gen/splatmap.pgm", img.image_format, encoder_options);
    }
}
