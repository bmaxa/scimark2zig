const allocator = @import("allocator.zig").allocator;
pub fn new_double(M: i32, N: i32) ![][]f64 {
    var rc: [][]f64 = try allocator().alloc([]f64, @intCast(usize, M));
    for (rc) |*l| {
        l.* = try allocator().alloc(f64, @intCast(usize, N));
        for (l.*)|*v|{
          v.* = 0;
        }
    }
    return rc;
}
pub fn double_delete(A: [][]f64) void {
    for (A) |l| {
        allocator().free(l);
    }
    allocator().free(A);
}
pub fn double_copy(B: [][]f64, A: [][]f64) void {
    const remainder = B[0].len & 3;
    var i: usize = 0;
    while (i < B.len) : (i += 1) {
        const Bi = B[i];
        const Ai = A[i];
        var j: usize = 0;
        while (j < remainder) : (j += 1) {
            Bi[j] = Ai[j];
        }
        while (j < B[0].len) : (j += 4) {
            Bi[j] = Ai[j];
            Bi[j + 1] = Ai[j + 1];
            Bi[j + 2] = Ai[j + 2];
            Bi[j + 3] = Ai[j + 3];
        }
    }
}
