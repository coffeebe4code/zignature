const std = @import("std");
const config = @import("http_config");
const HttpMethod = @import("http").HttpMethod;

const get = "GET ";
const put = "PUT ";
const patch = "PATC";
const post = "POST";
const delete = "DELE";
const options = "OPTI";
const trace = "TRAC";
const head = "HEAD";
const spaces64: []const u8 = "        ";
const crlf64: []const u8 = "\r\n\r\n\r\n\r\n";

const ParserError = error{
    InvalidMethod,
    InvalidHttpVersion,
    InvalidHeadersTooLarge,
    InvalidPreTooLarge,
    InvalidBodyTooLarge,
    InvalidIncomplete,
};

pub const HttpParser = struct {
    buffer: *[config.max_total_size]u8,
    method: HttpMethod,
    route_start: usize,
    route_end: usize,
    header_start: usize,
    header_end: usize,
    body_start: usize,
    body_end: usize,
    current: usize,
    len: usize,
    pub fn init(buffer: *[config.max_total_size]u8, len: usize) HttpParser {
        return .{
            .buffer = buffer,
            .len = len,
            .current = 0,
            .method = undefined,
            .route_start = undefined,
            .route_end = undefined,
            .header_start = undefined,
            .header_end = undefined,
            .body_start = undefined,
            .body_end = undefined,
        };
    }
    pub fn update_len(self: *HttpParser, additional: usize) void {
        self.len += additional;
    }
    //TODO:: review for alignment changes and total parsing on intrinsic boundaries instead.
    pub fn parse_boundary(self: *HttpParser) ParserError!void {
        var result = try self.parse_method();
        self.method = result;
        try self.parse_route();
        try self.parse_http();
    }
    //TODO:: add intrinsics and alignment  changes later.
    pub fn parse_method(self: *HttpParser) ParserError!HttpMethod {
        while (true) {
            if (self.len >= 4) {
                const to_cmp: @Vector(4, u8) = self.buffer[0..4].*;
                var method: @Vector(4, u8) = get[0..4].*;
                if (@reduce(.And, to_cmp == method)) {
                    return HttpMethod.GET;
                }
                method = put[0..4].*;
                if (@reduce(.And, to_cmp == method)) {
                    return HttpMethod.PUT;
                }
                method = patch[0..4].*;
                if (@reduce(.And, to_cmp == method)) {
                    self.current = 6;
                    return HttpMethod.PATCH;
                }
                if (@reduce(.And, to_cmp == method)) {
                    self.current = 5;
                    return HttpMethod.POST;
                }
                method = delete[0..4].*;
                if (@reduce(.And, to_cmp == method)) {
                    self.current = 7;
                    return HttpMethod.DELETE;
                }
                method = options[0..4].*;
                if (@reduce(.And, to_cmp == method)) {
                    self.current = 8;
                    return HttpMethod.OPTIONS;
                }
                method = trace[0..4].*;
                if (@reduce(.And, to_cmp == method)) {
                    self.current = 6;
                    return HttpMethod.TRACE;
                }
                method = head[0..4].*;
                if (@reduce(.And, to_cmp == method)) {
                    self.current = 5;
                    return HttpMethod.HEAD;
                }
                return ParserError.InvalidMethod;
            }
        }
    }
    //TODO:: add intrinsics and alignment changes later.
    pub fn parse_route(self: *HttpParser) ParserError!void {
        var route_idx: usize = 0;
        self.route_start = self.current;
        while (true) {
            const run_len = self.len - self.current;
            if (run_len >= 8) {
                const to_cmp: @Vector(8, u8) = self.buffer[self.current..][0..8].*;
                var mask: @Vector(8, u8) = spaces64[0..8].*;
                const cmp_int = @bitCast(u8, to_cmp == mask);
                const idx = @ctz(cmp_int);
                if (idx < 8) {
                    self.route_end = idx + route_idx - 1;
                    self.current += self.route_end + 2;
                    return;
                }
                self.current += 8;
                route_idx += 8;
            } else if (run_len > 0) {
                const idx = std.mem.indexOf(u8, self.buffer[self.current .. self.current + run_len], spaces64[0..1]);
                if (idx != null) {
                    self.route_end = idx.? + route_idx - 1;
                    self.current += self.route_end + 2;
                    return;
                }
                self.current += run_len;
                route_idx += run_len;
            }
        }
    }
    //TODO:: only support 1.1 for now, possible change in future.
    pub fn parse_http(self: *HttpParser) ParserError!void {
        while (true) {
            // HTTP/1.1\r\n
            if (self.len - self.current >= 9) {
                self.current += 10;
                return;
            }
        }
    }
    //TODO:: add intrinsics and alignment changes later.
    pub fn parse_header_seek_end(self: *HttpParser) ParserError!void {
        var header_idx: usize = 0;
        self.header_start = self.current;
        while (true) {
            const run_len = self.len - self.current;
            if (run_len >= 8) {
                const to_cmp: @Vector(2, u32) = @bitCast([2]u32, self.buffer[self.current..][0..8].*);
                var mask: @Vector(2, u32) = @bitCast([2]u32, crlf64[0..8].*);
                const cmp_int = @bitCast(u32, to_cmp == mask);
                const idx = @ctz(cmp_int);
                if (idx < 2) {
                    self.header_end = self.current + idx + header_idx;
                    self.current += self.header_end + 1;
                    return;
                }
                self.current += 8;
                header_idx += 8;
            } else if (run_len >= 4) {
                const idx = std.mem.indexOf(u8, self.buffer[self.current .. self.current + run_len], crlf64[0..4]);
                if (idx != null) {
                    self.header_end = self.current + idx.? + header_idx;
                    self.current += self.header_end + 1;
                    return;
                }
                self.current += run_len;
                header_idx += run_len;
            }
        }
    }
};

test "test parse route 7" {
    var buf: [config.max_total_size]u8 = undefined;
    std.mem.copy(u8, &buf, "/route ");
    var parser = HttpParser.init(&buf, 7);
    try parser.parse_route();
    try std.testing.expect(parser.route_end == 5);
}

test "test headers" {
    var buf: [config.max_total_size]u8 = undefined;
    std.mem.copy(u8, &buf, "header:");
    var parser = HttpParser.init(&buf, 22);
    try parser.parse_header_seek_end();
    try std.testing.expect(parser.header_start == 0);
    try std.testing.expect(parser.header_end == 22);
}

test "test parse route 20" {
    var buf: [config.max_total_size]u8 = undefined;
    std.mem.copy(u8, &buf, "/route/that/is/long ");
    var parser = HttpParser.init(&buf, 20);
    try parser.parse_route();
    try std.testing.expect(parser.route_end == 18);
}

test "test parse route 8" {
    var buf: [config.max_total_size]u8 = undefined;
    std.mem.copy(u8, &buf, "/route h");
    var parser = HttpParser.init(&buf, 8);
    try parser.parse_route();
    try std.testing.expect(parser.route_end == 5);
}

test "test parse get" {
    var buf: [config.max_total_size]u8 = undefined;
    std.mem.copy(u8, &buf, "GET ");
    var parser = HttpParser.init(&buf, 4);
    var result = try parser.parse_method();
    try std.testing.expect(result == HttpMethod.GET);
}

test "test parse options" {
    var buf: [config.max_total_size]u8 = undefined;
    std.mem.copy(u8, &buf, "OPTIONS");
    var parser = HttpParser.init(&buf, 7);
    var result = try parser.parse_method();
    try std.testing.expect(result == HttpMethod.OPTIONS);
}

test "test parse head" {
    var buf: [config.max_total_size]u8 = undefined;
    std.mem.copy(u8, &buf, "HEAD ");
    var parser = HttpParser.init(&buf, 5);
    var result = try parser.parse_method();
    try std.testing.expect(result == HttpMethod.HEAD);
}
