const std = @import("std");

//const c_opts = [_][]const u8{"-std=c11"};
const c_opts = [_][]const u8{ "-std=c11", "-Wall", "-Werror", "-Wextra" };

const libs = struct {
    const tcp_server = .{
        .source_file = .{ .path = "lib/tcp_server.zig" },
        .dependencies = undefined,
    };
    const tcp_config = .{
        .source_file = .{ .path = "lib/tcp_config.zig" },
        .dependencies = undefined,
    };
    const http_config = .{
        .source_file = .{ .path = "lib/http_config.zig" },
        .dependencies = undefined,
    };
    const http = .{
        .source_file = .{ .path = "lib/http.zig" },
        .dependencies = undefined,
    };
    const http_parser = .{
        .source_file = .{ .path = "lib/http_parser.zig" },
        .dependencies = undefined,
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
        .root_source_file = .{ .path = "src/lib" },
        .target = target,
        .optimize = m,
    });

    // libs
    const tcp_config = b.createModule(.{
        .source_file = .{ .path = "lib/tcp_config.zig" },
        .dependencies = &.{},
    });
    const tcp_dep = b.dependency("tcp_dep", .{});
    _ = tcp_dep;

    const tcp_server = .{
        .source_file = .{ .path = "lib/tcp_server.zig" },
        .dependencies = &.{
            tcp_config,
        },
    };
    const http_config = b.createModule(.{
        .source_file = .{ .path = "lib/http_config.zig" },
        .dependencies = undefined,
    });
    const http = b.createModule(.{
        .source_file = .{ .path = "lib/http.zig" },
        .dependencies = &.{},
    });
    const http_parser = b.createModule(.{
        .source_file = .{ .path = "lib/http_parser.zig" },
        .dependencies = &.{
            .{ .name = "http_config", .module = http_config },
            .{ .name = "http", .module = http },
        },
    });

    // tests
    tests.addModule("tcp_config", tcp_config);
    tests.addModule("http", http);
    tests.addModule("http_config", http_config);
    tests.addModule("tcp_server", tcp_server);
    tests.addModule("httpparser", http_parser);
    //tests.setTarget(target);
    //tests.setBuildMode(m);

    const tests_step = b.step("test", "testing");
    tests_step.dependOn(&tests.step);

    //exe.setTarget(target);
    //exe.setBuildMode(m);
    exe.addLibraryPath("lib");
    exe.addModule("tcp_config", tcp_config);
    exe.addModule("http", http);
    exe.addModule("http_config", http_config);
    exe.addModule("tcp_server", tcp_server);
    exe.addModule("httpparser", http_parser);

    exe.addIncludePath("c");
    exe.linkLibC();
    exe.addCSourceFile("c/tcp_server.c", &c_opts);

    exe.install();
}
