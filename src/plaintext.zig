const TcpServer = @import("tcp_server").TcpServer;
const HttpParser = @import("http_parser").HttpParser;
const std = @import("std");

pub fn main() !void {
    var server = TcpServer.init().listen();
    try server.client_accept(0);
    while (true) {
        var buf: [768:0]u8 = std.mem.zeroes([768:0]u8);
        var parser = HttpParser.init(&buf, 768);
        _ = try server.client_read(&buf, 0);
        _ = try parser.parse_method();
        _ = try server.client_write(0, &buf);
    }
}
