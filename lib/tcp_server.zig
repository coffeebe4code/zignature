const server = @cImport({
    @cInclude("tcp_server.h");
});
const std = @import("std");
const config = @import("tcp_config");

const Errno = enum(i64) {
    ECONNABORTED = -1120,
    ECONNRESET = -104,
    EWOULDBLOCK = -1102,
    EAGAIN = -11,
    EINTR = -120,
    EINVAL = -121,
    EMFILE = -124,
    ENFILE = -127,
    ENOBUFS = -1122,
    ENOTCONN = -1124,
    ENOMEM = -132,
    ETIMEDOUT = -1127,
    EPERM = -139,
    EFBIG = -119,
    EDQUOT = -1133,
    EPIPE = -140,
    _,
};

const err = error{
    ECONNABORTED,
    ECONNRESET,
    EWOULDBLOCK,
    EAGAIN,
    EINTR,
    EINVAL,
    EMFILE,
    ENFILE,
    ENOBUFS,
    ENOTCONN,
    ENOMEM,
    ETIMEDOUT,
    EPERM,
    EFBIG,
    EDQUOT,
    EPIPE,
    EUNKNOWN,
};

// we will store the connections ourself to abstract c_int
var conns: [config.max_conns]c_int = std.mem.zeroes([config.max_conns]c_int);

pub const TcpServer = struct {
    pub fn init() TcpServer {
        server.server_init(config.port);
        return TcpServer{};
    }
    pub fn listen(self: TcpServer) TcpServer {
        server.server_listen(config.max_conns);
        return self;
    }
    pub fn client_write(self: *TcpServer, idx: usize, buffer: []const u8) !void {
        var left = buffer.len;
        var buffer_ptr = buffer.ptr;
        while (true) {
            var ret = server.server_client_write(conns[idx], buffer_ptr, left);
            if (ret >= 0) {
                if (ret == buffer.len) {
                    return;
                }
                buffer_ptr += @intCast(usize, ret);
                left -= @intCast(usize, ret);
            } else {
                try map_error(ret);
                errdefer self.client_close(idx);
            }
        }
    }
    pub fn client_read(self: *TcpServer, buffer: []u8, idx: usize) !usize {
        while (true) {
            var ret = server.server_client_read(conns[idx], buffer.ptr, buffer.len);
            if (ret >= 0) {
                return @intCast(usize, ret);
            }
            try map_error(ret);
            errdefer self.client_close(idx);
        }
    }
    pub fn client_accept(self: TcpServer, idx: usize) !void {
        while (true) {
            const ret = server.server_client_read_new();
            if (ret >= 0) {
                conns[idx] = ret;
                std.debug.print("accepted\n", .{});
                return;
            }
            try map_error(ret);
            errdefer self.client_close(idx);
        }
    }
    pub fn client_close(self: TcpServer, idx: usize) !void {
        _ = self;
        const ret = server.server_close(idx);
        if (ret != 0) {
            try map_error(ret);
        }
    }
};

fn map_error(ret: c_int) err!void {
    var enu = @intToEnum(Errno, ret);
    switch (enu) {
        .EAGAIN, .EWOULDBLOCK, .EINTR => {
            return;
        },
        .ECONNABORTED => return error.ECONNABORTED,
        .ECONNRESET => return error.ECONNRESET,
        .EINVAL => return error.EINVAL,
        .EMFILE => return error.EMFILE,
        .ENFILE => return error.ENFILE,
        .ENOBUFS => return error.ENOBUFS,
        .ENOTCONN => return error.ENOTCONN,
        .ENOMEM => return error.ENOMEM,
        .ETIMEDOUT => return error.ETIMEDOUT,
        .EPERM => return error.EPERM,
        .EFBIG => return error.EFBIG,
        .EDQUOT => return error.EDQUOT,
        .EPIPE => return error.EPIPE,
        _ => return error.EUNKNOWN,
    }
}
