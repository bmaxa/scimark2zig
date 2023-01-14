const math = @import("std").math;

pub fn num_flops(n: usize) f64 {
    const nd = @intToFloat(f64, n);

    return 2.0 * nd * nd * nd / 3.0;
}
pub fn factor(m: usize, n: usize, a: [][]f64, pivot: []usize) usize {
    const min_mn = if (m < n) m else n;

    var j: usize = 0;
    while (j < min_mn) : (j += 1) {
        var jp: usize = j;
        var t: f64 = math.fabs(a[j][j]);

        var i: usize = j + 1;
        while (i < m) : (i += 1) {
            const ab = math.fabs(a[i][j]);
            if (ab > t) {
                jp = i;
                t = ab;
            }
        }
        pivot[j] = jp;
        if (a[jp][j] == 0.0) {
            return 1;
        }
        if (jp != j) {
            const ta = a[j];
            a[j] = a[jp];
            a[jp] = ta;
        }
        if (j < m - 1) {
            const recp = 1.0 / a[j][j];
            var k: usize = j + 1;
            while (k < m) : (k += 1) {
                a[k][j] *= recp;
            }
        }

        if (j < min_mn - 1) {
            var ii: usize = j + 1;
            while (ii < m) : (ii += 1) {
                var aii = a[ii];
                const aj = a[j];
                const aiij = aii[j];
                var jj: usize = j + 1;
                while (jj < n) : (jj += 1) {
                    aii[jj] -= aiij * aj[jj];
                }
            }
        }
    }
    return 0;
}
