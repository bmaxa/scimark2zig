const std = @import("std");
const array2D = @import("array.zig");
const kernel =  @import("kernel.zig");
const random = @import("Random.zig");
const allocator = @import("allocator.zig").allocator;
const RESOLUTION_DEFAULT = 2.0;
const RANDOM_SEED = 101010;

const FFT_SIZE = 1024;
const SOR_SIZE = 100;
const SPARSE_SIZE_M = 1000;
const SPARSE_SIZE_nz = 5000;
const LU_SIZE = 100;

const LG_FFT_SIZE  = 1048576;
const LG_SOR_SIZE = 1000;
const LG_SPARSE_SIZE_M = 10000;
const LG_SPARSE_SIZE_nz = 1000000;
const LG_LU_SIZE = 1000;

const TINY_FFT_SIZE = 16;
const TINY_SOR_SIZE = 10;
const TINY_SPARSE_SIZE_M = 10;
const TINY_SPARSE_SIZE_nz = 50;
const TINY_LU_SIZE = 10;

const stdout = std.io.getStdOut().writer();
pub fn main() !void {
    const args = try std.process.argsAlloc(allocator());
    defer std.process.argsFree(allocator(), args);
    var min_time:f64 = 2.0;

    var FFT_size:i32 = FFT_SIZE;
    var SOR_size:i32 = SOR_SIZE;
    var Sparse_size_M:i32 = SPARSE_SIZE_M;
    var Sparse_size_nz:i32 = SPARSE_SIZE_nz;
    var LU_size:i32 = LU_SIZE;
    if (find(args,"-l"))|_|{
      FFT_size = LG_FFT_SIZE;
      SOR_size = LG_SOR_SIZE;
      Sparse_size_M = LG_SPARSE_SIZE_M;
      Sparse_size_nz = LG_SPARSE_SIZE_nz;
      LU_size = LG_LU_SIZE;
    }
    if (find(args,"-t"))|val|{
      if (args.len > val+1){
        min_time = try std.fmt.parseFloat(f64,args[val+1]);
      }
      else {
          try print_usage();
          return;
        }
    }
    if (find(args,"-h"))|_|{
      try print_usage();
      return;
    }
    var R = random.new_seed(RANDOM_SEED);
    try print_banner();
    try stdout.print("Using {d:10.2} seconds min time per kernel\n",.{min_time});
    var res = [_]f64{0}**6;
    res[1] = try kernel.measureFFT(FFT_size,min_time,&R);
    res[2] = try kernel.measureSOR(SOR_size,min_time,&R);
    res[3] = kernel.measureMonteCarlo(min_time,&R);
    res[4] = try kernel.measureSparseMatMult(Sparse_size_M,Sparse_size_nz,min_time,&R);
    res[5] = try kernel.measureLU(LU_size,min_time,&R);
    res[0] = (res[1]+res[2]+res[3]+res[4]+res[5])/5.0;
    try stdout.print("Composite Score:        {d:8.2}\n",.{res[0]});
    try stdout.print("FFT             Mflops: {d:8.2}     (N={})\n",.{res[1],FFT_size});
    try stdout.print("SOR             Mflops: {d:8.2}     ({} x {})\n",.{res[2],SOR_size,SOR_size});
    try stdout.print("MonteCarlo      Mflops: {d:8.2}\n",.{res[3]});
    try stdout.print("Sparse matmult  Mflops: {d:8.2}     (N={}, nz={})\n",.{res[4],Sparse_size_M,Sparse_size_nz});
    try stdout.print("LU              Nflops: {d:8.2}     (M={}, N={})\n",.{res[5],LU_size,LU_size});
}
fn print_banner()!void{
     try stdout.print("**                                                              **\n",.{});
     try stdout.print("** SciMark2 Numeric Benchmark, see http://math.nist.gov/scimark **\n",.{});
     try stdout.print("** for details. (Results can be submitted to pozo@nist.gov)     **\n",.{});
     try stdout.print("**                                                              **\n",.{});
}
fn print_usage()!void{
     try stdout.print("scimark2 -l -h -t min_time\n",.{});
}
fn find(args:[][]u8,needle:[]const u8)?usize{
  for (args)|val,i| {
    if(std.mem.startsWith(u8,val,needle))return i;
  }
  return null;
}
