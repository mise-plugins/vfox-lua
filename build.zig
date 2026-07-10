const std = @import("std");

fn addExe(b: *std.Build, name: []const u8, src: []const u8, flags: []const []const u8, lib: *std.Build.Step.Compile, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    mod.addIncludePath(b.path("src"));
    mod.addCSourceFile(.{ .file = b.path(src), .flags = flags });
    mod.linkLibrary(lib);

    if (target.result.os.tag == .linux) {
        mod.linkSystemLibrary("dl", .{});
    }

    const exe = b.addExecutable(.{ .name = name, .root_module = mod });
    return exe;
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const readline = b.option(bool, "readline", "Link readline for REPL") orelse false;

    const src_dir = b.build_root.handle.openDir(b.graph.io, "src", .{ .iterate = true }) catch
        @panic("src/ directory not found — run zig build from extracted Lua source root");
    defer src_dir.close(b.graph.io);

    var lib_srcs = std.ArrayListUnmanaged([]const u8).empty;
    defer lib_srcs.deinit(b.allocator);

    var iter = src_dir.iterate();
    while (iter.next(b.graph.io) catch @panic("failed to read src/")) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.name, ".c")) continue;
        if (std.mem.eql(u8, entry.name, "lua.c") or std.mem.eql(u8, entry.name, "luac.c")) continue;
        try lib_srcs.append(b.allocator, b.dupe(entry.name));
    }

    const src_root = b.path("src");
    const os_tag = target.result.os.tag;

    var flags = std.ArrayListUnmanaged([]const u8).empty;
    defer flags.deinit(b.allocator);

    try flags.append(b.allocator, "-std=gnu99");

    if (os_tag == .linux or os_tag == .windows) {
        try flags.append(b.allocator, "-fvisibility=hidden");
    }

    switch (os_tag) {
        .linux => try flags.append(b.allocator, "-DLUA_USE_LINUX"),
        .macos => try flags.append(b.allocator, "-DLUA_USE_MACOSX"),
        .windows => {},
        else => try flags.append(b.allocator, "-DLUA_USE_POSIX"),
    }

    if (readline) {
        try flags.append(b.allocator, "-DLUA_USE_READLINE");
    }

    if (optimize == .Debug) {
        try flags.append(b.allocator, "-DLUA_USE_APICHECK");
        try flags.append(b.allocator, "-fno-sanitize=undefined");
    }

    const lib_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    lib_module.addIncludePath(src_root);
    lib_module.addCSourceFiles(.{
        .root = src_root,
        .files = lib_srcs.items,
        .flags = flags.items,
        .language = .c,
    });

    const lib = b.addLibrary(.{
        .name = "lua",
        .linkage = .static,
        .root_module = lib_module,
    });

    const lua_exe = addExe(b, "lua", "src/lua.c", flags.items, lib, target, optimize);
    const luac_exe = addExe(b, "luac", "src/luac.c", flags.items, lib, target, optimize);

    if (readline) {
        const linenoize = b.dependency("linenoize", .{
            .target = target,
            .optimize = optimize,
        });
        lua_exe.root_module.addIncludePath(linenoize.path("include"));
        lua_exe.root_module.addIncludePath(b.path("."));
        lua_exe.root_module.addCSourceFile(.{ .file = b.path("readline_shim.c") });
        lua_exe.root_module.linkLibrary(linenoize.artifact("linenoise"));
    }

    b.installArtifact(lib);
    b.installArtifact(lua_exe);
    b.installArtifact(luac_exe);

    const include_install = b.addInstallDirectory(.{
        .source_dir = src_root,
        .install_dir = .{ .custom = "include" },
        .install_subdir = "",
        .include_extensions = &.{ "lua.h", "luaconf.h", "lualib.h", "lauxlib.h" },
    });
    b.getInstallStep().dependOn(&include_install.step);
}
