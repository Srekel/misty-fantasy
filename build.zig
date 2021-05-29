const bld = @import("std").build;
const mem = @import("std").mem;
const zig = @import("std").zig;

// build sokol into a static library
pub fn buildSokol(b: *bld.Builder, comptime prefix_path: []const u8) *bld.LibExeObjStep {
    const lib = b.addStaticLibrary("sokol", null);
    lib.linkLibC();
    lib.setBuildMode(b.standardReleaseOptions());
    const sokol_path = prefix_path ++ "src/sokol/c/";
    const csources = [_][]const u8{
        "sokol_app.c",
        "sokol_gfx.c",
        "sokol_time.c",
        "sokol_audio.c",
        "sokol_gl.c",
        "sokol_debugtext.c",
        "sokol_shape.c",
    };
    if (lib.target.isDarwin()) {
        b.env_map.set("ZIG_SYSTEM_LINKER_HACK", "1") catch unreachable;
        inline for (csources) |csrc| {
            lib.addCSourceFile(sokol_path ++ csrc, &[_][]const u8{ "-ObjC", "-DIMPL" });
        }
        lib.linkFramework("MetalKit");
        lib.linkFramework("Metal");
        lib.linkFramework("Cocoa");
        lib.linkFramework("QuartzCore");
        lib.linkFramework("AudioToolbox");
    } else {
        inline for (csources) |csrc| {
            lib.addCSourceFile(sokol_path ++ csrc, &[_][]const u8{"-DIMPL"});
        }
        if (lib.target.isLinux()) {
            lib.linkSystemLibrary("X11");
            lib.linkSystemLibrary("Xi");
            lib.linkSystemLibrary("Xcursor");
            lib.linkSystemLibrary("GL");
            lib.linkSystemLibrary("asound");
        } else if (lib.target.isWindows()) {
            lib.linkSystemLibrary("gdi32");
        }
        // exe.linkSystemLibrary("user32");
        // exe.linkSystemLibrary("shell32");
        // exe.linkSystemLibrary("kernel32");
    }
    return lib;
}

// build one of the example exes
fn buildExample(b: *bld.Builder, comptime prefix_path: []const u8, sokol: *bld.LibExeObjStep, comptime name: []const u8) void {
    const e = b.addExecutable(name, prefix_path ++ "src/examples/" ++ name ++ ".zig");
    const sokol_path = prefix_path ++ "src/sokol/";
    e.linkLibrary(sokol);
    e.setBuildMode(b.standardReleaseOptions());
    e.addPackagePath("sokol", sokol_path ++ "sokol.zig");
    e.install();
    b.step("run-" ++ name, "Run " ++ name).dependOn(&e.run().step);
}

fn buildMain(b: *bld.Builder, comptime prefix_path: []const u8, sokol: *bld.LibExeObjStep, comptime name: []const u8) void {
    const e = b.addExecutable(name, "main.zig");
    const sokol_path = prefix_path ++ "src/sokol/";
    e.linkLibrary(sokol);
    e.setBuildMode(b.standardReleaseOptions());
    e.addCSourceFile("external/DDSLoader/src/dds.c", &[_][]const u8{"-std=c99"});
    e.addIncludeDir("external");
    e.addPackagePath("sokol", sokol_path ++ "sokol.zig");
    e.addPackagePath("zigimg", "external/zigimg/zigimg.zig");
    e.addPackagePath("nooice", "external/nooice/src/nooice.zig");
    e.install();
    b.step("run-" ++ name, "Run " ++ name).dependOn(&e.run().step);
}

// fn buildShaders(b: *bld.Builder, comptime prefix_path: []const u8, sokol: *bld.LibExeObjStep, comptime name: []const u8) void {
//     const e = b.add(name, name ++ "lol.zig");
//     const sokol_path = prefix_path ++ "src/sokol/";
//     e.linkLibrary(sokol);
//     e.setBuildMode(b.standardReleaseOptions());
//     e.addPackagePath("sokol", sokol_path ++ "sokol.zig");
//     e.install();
//     b.step("run-" ++ name, "Run " ++ name).dependOn(&e.run().step);
// }

pub fn build(b: *bld.Builder) void {
    const prefix_path = "external/sokol-zig/";
    const sokol = buildSokol(b, prefix_path);
    buildMain(b, prefix_path, sokol, "misty");

    // buildExample(b, prefix_path, sokol, "clear");
    // buildExample(b, prefix_path, sokol, "clear");
    // buildExample(b, prefix_path, sokol, "triangle");
    // buildExample(b, prefix_path, sokol, "quad");
    // buildExample(b, prefix_path, sokol, "bufferoffsets");
    // buildExample(b, prefix_path, sokol, "cube");
    // buildExample(b, prefix_path, sokol, "noninterleaved");
    // buildExample(b, prefix_path, sokol, "texcube");
    // buildExample(b, prefix_path, sokol, "offscreen");
    // buildExample(b, prefix_path, sokol, "instancing");
    // buildExample(b, prefix_path, sokol, "mrt");
    // buildExample(b, prefix_path, sokol, "saudio");
    // buildExample(b, prefix_path, sokol, "sgl");
    // buildExample(b, prefix_path, sokol, "debugtext");
    // buildExample(b, prefix_path, sokol, "debugtext-print");
    // buildExample(b, prefix_path, sokol, "debugtext-userfont");
    // buildExample(b, prefix_path, sokol, "shapes");
}
