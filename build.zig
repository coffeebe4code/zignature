const std = @import("std");

//const c_opts = [_][]const u8{"-std=c11"};
const c_opts = [_][]const u8{ "-std=c11", "-Wall", "-Werror", "-Wextra" };

const libs = struct {
    const tcp_server = .{
        .name = "tcp_server",
        .source = .{ .path = "lib/tcp_server.zig" },
        .dependencies = &.{tcp_config},
    };
    const tcp_config = .{
        .name = "tcp_config",
        .source = .{ .path = "lib/tcp_config.zig" },
        .dependencies = &.{},
    };
    const http_config = .{
        .name = "http_config",
        .source = .{ .path = "lib/http_config.zig" },
        .dependencies = &.{},
    };
    const config = .{
        .name = "config",
        .source = .{ .path = "lib/config.zig" },
        .dependencies = &.{},
    };
    const http = .{
        .name = "http",
        .source = .{ .path = "lib/http.zig" },
        .dependencies = &.{},
    };
    const http_parser = .{
        .name = "http_parser",
        .source = .{ .path = "lib/http_parser.zig" },
        .dependencies = &.{ http, config, http_config },
    };
};

pub fn build(b: *std.build.Builder) void {
    buildPlaintext(b);
}

fn buildPlaintext(b: *std.build.Builder) void {
    const m = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});
    const exe = b.addExecutable(.{
        .name = "plaintext",
        .root_source_file = .{ .path = "src/plaintext.zig" },
        .target = target,
        .optimize = m,
    });

    const tests = b.addTest(.{
        .name = "tests",
        .root_source_file = libs.http_parser.source,
        .target = target,
        .optimize = m,
    });
    tests.addModule(libs.tcp_config.name, @as(*std.Build.Module, &libs.tcp_config));
    tests.addModule(libs.http.name, libs.http);
    tests.addModule(libs.http_config.name, libs.http_config);
    //tests.setTarget(target);
    //tests.setBuildMode(m);

    const tests_step = b.step("test", "testing");
    tests_step.dependOn(&tests.step);

    //exe.setTarget(target);
    //exe.setBuildMode(m);
    exe.addLibraryPath("lib");
    exe.addModule(libs.tcp_config);
    exe.addModule(libs.http_config);
    exe.addModule(libs.tcp_server);
    exe.addModule(libs.http);
    exe.addModule(libs.http_parser);

    exe.addIncludePath("c");
    exe.linkLibC();
    exe.addCSourceFile("c/tcp_server.c", &c_opts);

    exe.install();
}
