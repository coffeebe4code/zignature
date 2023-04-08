pub const server_port: i64 = 8080;
pub const max_conns: i64 = 4096;
pub const max_header_size: usize = 1024;
pub const max_body_size: usize = 1024;
pub const max_total_size: usize = max_body_size + max_header_size;
