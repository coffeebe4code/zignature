const std = @import("std");

//const c_opts = [_][]const u8{"-std=c11"};
const c_opts = [_][]const u8{ "-std=c11", "-Wall", "-Werror", "-Wextra" };

const libs = struct {
    const tcp_server = std.build.Pkg{
        .name = "tcp_server",
        .source = .{ .path = "lib/tcp_server.zig" },
        .dependencies = &[_]std.build.Pkg{tcp_config},
    };
    const tcp_config = std.build.Pkg{
        .name = "tcp_config",
        .source = .{ .path = "lib/tcp_config.zig" },
        .dependencies = &[_]std.build.Pkg{},
    };
    const http_config = std.build.Pkg{
        .name = "http_config",
        .source = .{ .path = "lib/http_config.zig" },
        .dependencies = &[_]std.build.Pkg{},
    };
    const config = std.build.Pkg{
        .name = "config",
        .source = .{ .path = "lib/config.zig" },
        .dependencies = &[_]std.build.Pkg{},
    };
    const http = std.build.Pkg{
        .name = "http",
        .source = .{ .path = "lib/http.zig" },
        .dependencies = &[_]std.build.Pkg{},
    };
    const http_parser = std.build.Pkg{
        .name = "http_parser",
        .source = .{ .path = "lib/http_parser.zig" },
        .dependencies = &[_]std.build.Pkg{ http, config, http_config },
    };
};

pub fn build(b: *std.build.Builder) void {
    buildPlaintext(b);
}

fn buildPlaintext(b: *std.build.Builder) void {
    const m = b.standardReleaseOptions();
    const exe = b.addExecutable("plaintext", "src/plaintext.zig");
    const target = b.standardTargetOptions(.{});

    const tests = b.addTest(libs.http_parser.source.path);
    tests.addPackage(libs.tcp_config);
    tests.addPackage(libs.http);
    tests.addPackage(libs.http_config);
    tests.setTarget(target);
    tests.setBuildMode(m);

    const tests_step = b.step("test", "testing");
    tests_step.dependOn(&tests.step);

    exe.setTarget(target);
    exe.setBuildMode(m);
    exe.addLibraryPath("lib");
    exe.addPackage(libs.tcp_config);
    exe.addPackage(libs.http_config);
    exe.addPackage(libs.tcp_server);
    exe.addPackage(libs.http);
    exe.addPackage(libs.http_parser);

    exe.addIncludePath("c");
    exe.linkLibC();
    exe.addCSourceFile("c/tcp_server.c", &c_opts);

    exe.install();
}
