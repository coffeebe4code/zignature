const TcpServer = @import("tcp_server").TcpServer;
const HttpParser = @import("http_parser").HttpParser;
const std = @import("std");

pub fn main() !void {
    var server = TcpServer.init().listen();
    try server.client_accept(0);
    while (true) {
        var buf: [512:0]u8 = undefined;

        var size = try server.client_read(&buf, 0);
        _ = size;
        try server.client_write(0, &buf);
    }
}
