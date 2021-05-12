const math = @import("std").math;
const out = @import("std").fmt;
const PI = 3.1415926535897932;

pub fn int_log2(n: i64) !u64 {
    var log: u64 = 0;
    var k: i32 = 1;
    while (k < n) : (k *= 2) {
        log += 1;
    }
    if (n != (@as(u64, 1) << @intCast(u6,log))) {
        var buf = [_]u8{0} ** 128;
        const pr = try out.bufPrint(buf[0..], "FFT: Data length is not a power of 2!: {} ", .{n});
        @panic(pr);
    }
    return log;
}
pub fn numFlops(N: i64) !f64 {
    var Nd = @intToFloat(f64, N);
    var logN = @intToFloat(f64, try int_log2(N));
    return (5.0 * Nd - 2) * logN + 2.0 * (Nd + 1.0);
}
fn transform_internal(N: i64, data: []f64, direction: i64) !void {
    var n: i64 = @divTrunc(N, 2);
    var bit: i64 = 0;
    var logn: usize = 0;
    var dual: usize = 1;

    if (n == 1) {
        return;
    }
    logn = try int_log2(n);

    if (N == 0) {
        return;
    }

    bitreverse(N, data);

    while (bit < logn) : (bit += 1) {
        var w_real: f64 = 1;
        var w_imag: f64 = 0;
        var a: usize = 0;
        var b: usize = 0;

        const theta = 2.0 * @intToFloat(f64, direction) * PI / (2.0 * @intToFloat(f64, dual));
        const s = math.sin(theta);
        const t = math.sin(theta / 2.0);
        const s2 = 2.0 * t * t;

        while (b < n) : (b += 2 * dual) {
            const i: usize = 2 * b;
            const j: usize = 2 * (b + dual);

            const wd_real = data[j];
            const wd_imag = data[j + 1];

            data[j] = data[i] - wd_real;
            data[j + 1] = data[i + 1] - wd_imag;
            data[i] += wd_real;
            data[i + 1] += wd_imag;
        }
        a = 1;
        while (a < dual) : (a += 1) {
          const tmp_real = w_real - s * w_imag - s2 * w_real;
          const tmp_imag = w_imag + s * w_real - s2 * w_imag;
          w_real = tmp_real;
          w_imag = tmp_imag;
          b = 0;
          while (b < n) : (b += 2 * dual) {
              const i = 2 * (b + a);
              const j = 2 * (b + a + dual);

              const z1_real = data[j];
              const z1_imag = data[j + 1];
              const wd_real = w_real * z1_real - w_imag * z1_imag;
              const wd_imag = w_real * z1_imag + w_imag * z1_real;

              data[j] = data[i] - wd_real;
              data[j + 1] = data[i + 1] - wd_imag;
              data[i] += wd_real;
              data[i + 1] += wd_imag;
          }
       }
       dual *= 2;
    }
}
fn bitreverse(N: i64, data: []f64) void {
    const n: usize = @intCast(usize, N) / 2;
    const nm1 = n - 1;
    var i: usize = 0;
    var j: usize = 0;

    while (i < nm1) : (i += 1) {
        const ii = i << 1;
        const jj = j << 1;

        var k = n >> 1;

        if (i < j) {
            const tmp_real = data[ii];
            const tmp_imag = data[ii + 1];

            data[ii] = data[jj];
            data[ii + 1] = data[jj + 1];

            data[jj] = tmp_real;
            data[jj + 1] = tmp_imag;
        }

        while (k <= j) {
            j -= k;
            k >>= 1;
        }
        j += k;
    }
}
pub fn transform(N: i64, data: []f64) !void {
    try transform_internal(N, data, -1);
}
pub fn inverse(N: i64, data: []f64) !void {
    const n = @divTrunc(N, 2);
    try transform_internal(N, data, 1);
    const norm = 1 / @intToFloat(f64, n);
    var i: usize = 0;
    while (i < N) : (i += 1) {
        data[i] *= norm;
    }
}
test "just to force" {
    var buf = [_]f64{0} ** 10;
    try transform(10, buf[0..]);
    try inverse(10, buf[0..]);
}
