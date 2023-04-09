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

const ParserError = error{
    InvalidMethod,
    InvalidHttpVersion,
    InvalidIncomplete,
};

pub const HttpParser = struct {
    buffer: *[config.max_total_size]u8,
    current: usize,
    len: usize,
    pub fn init(buffer: *[config.max_total_size]u8, len: usize) HttpParser {
        return .{
            .buffer = buffer,
            .len = len,
            .current = 0,
        };
    }
    pub fn update_len(self: *HttpParser, additional: usize) void {
        self.len += additional;
    }
    pub fn parse_method(self: *HttpParser) ParserError!HttpMethod {
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
        return ParserError.InvalidIncomplete;
    }
};

//test "test parse method" {
//    var buf: [512]u8 = undefined;
//    std.mem.copy(u8, &buf, "GET ");
//    var parser = HttpParser.init(&buf, 4);
//    var result = parser.parse_method();
//    try std.testing.expect(try result == HttpMethod.GET);
//}
