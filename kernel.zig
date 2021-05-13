const time = @import("std").time;
const random = @import("Random.zig");
const fft = @import("FFT.zig");
const sor = @import("sor.zig");
const montecarlo = @import("MonteCarlo.zig");
const sparse = @import("SparseCompRow.zig");
const lu = @import("lu.zig");
const array = @import("array.zig");
const allocator = @import("allocator.zig").allocator;
pub fn measureFFT(N:i32,min_time:f64,R:* random.Random)!f64 {
  const twoN = 2*N;
  const x = try R.vector(twoN);
  defer allocator().free(x);
  var cycles:i32 = 1;
  var start:i64 = undefined;
  while(true):(cycles *= 2) {
    start = time.timestamp();
    var i:i32 = 1;
    while (i < cycles):(i += 1) {
      try fft.transform(twoN,x);
      try fft.inverse(twoN,x);
    }
    const end = time.timestamp();
    if (@intToFloat(f64,end-start) >= min_time)break;
  }
  return (try fft.numFlops(N))*@intToFloat(f64,cycles) / @intToFloat(f64,time.timestamp() - start) * 1e-6;
}
pub fn measureSOR(N:i32,min_time:f64,R:* random.Random)!f64{
  const G = try R.matrix(N,N);
  defer array.Array2D_double_delete(G);
  var cycles:i32 = 1;
  var start:i64 = undefined;
  while (true):(cycles*=2) {
    start = time.timestamp();
    sor.execute(N,N,1.25,G,cycles);
    const end = time.timestamp();
    if (@intToFloat(f64,end-start) >= min_time) break;
  }
  return sor.num_flops(N,N,cycles)/@intToFloat(f64,time.timestamp()-start) * 1e-6;
}
pub fn measureMonteCarlo(min_time:f64,R:*random.Random)f64{
  var cycles:i32 =1;
  var sum:f64 = 0;
  var start:i64 = undefined;
  while(true):(cycles*=2) {
    start = time.timestamp();
    sum += montecarlo.integrate(cycles);
    const end = time.timestamp();
    if (@intToFloat(f64,end-start) >= min_time)break;
  }
  if (sum == 5)sum = 0;//to force calc
  return montecarlo.numFlops(cycles)/@intToFloat(f64,time.timestamp()-start)*1e-6;
}
pub fn measureSparseMatMult(N:i32,nz:i32,min_time:f64,R:*random.Random)anyerror!f64{
  const x = try R.vector(N);
  defer allocator().free(x);
  const y = try allocator().alloc(f64,@intCast(usize,N));
  defer allocator().free(y);
  init(y);

  const nr = @divTrunc(nz,N);
  const anz = nr * N;

  const val = try R.vector(anz);
  defer allocator().free(val);
  const col = try allocator().alloc(i32,@intCast(usize,nz));
  defer allocator().free(col);
  init(col);
  const row = try allocator().alloc(i32,@intCast(usize,N+1));
  defer allocator().free(row);
  init(row);

  var cycles:i32 = 1;

  var r:usize = 0;
  while (r<N):(r+=1){
    const rowr = @intCast(usize,row[r]);
    var step =@divTrunc( @intCast(i32,r),nr);

    row[r+1] = @intCast(i32,rowr) + nr;

    if (step < 1) {
      step = 1;
    }
    var i:usize = 0;
    while (i<nr):(i+=1){
      col[rowr+i] = @intCast(i32,i) * step;
    }
  }
  var start:i64 = 0;
  while (true):(cycles*=2){
    start = time.timestamp();
    sparse.matmult(N,y,val,row,col,x,cycles);
    const end = time.timestamp();
    if (@intToFloat(f64,end-start) >= min_time)break;
  }
  return sparse.num_flops(N,nz,cycles)/@intToFloat(f64,time.timestamp()-start) * 1e-6;
}
pub fn measureLU(N:i32,min_time:f64,R:* random.Random)anyerror!f64{
  var cycles:i32= 1;
  var start:i64 = undefined;

  const A = try R.matrix(N,N);
  defer array.Array2D_double_delete(A);
  const alu = try array.new_Array2D_double(N,N);
  defer array.Array2D_double_delete(alu);
  const pivot = try allocator().alloc(usize,@intCast(usize,N));
  defer allocator().free(pivot);
  init(pivot);
  var sum:usize = 0;
  while (true):(cycles*=2){
    start = time.timestamp();
    var i:usize=0;
    while(i<cycles):(i+=1){
      array.Array2D_double_copy(alu,A);
      _ = lu.factor(@intCast(usize,N),@intCast(usize,N),alu,pivot);
    }
    const end = time.timestamp();
    if (@intToFloat(f64,end-start) >= min_time) break;
  }
  return lu.num_flops(@intCast(usize,N)) * @intToFloat(f64,cycles) / @intToFloat(f64,time.timestamp() - start) * 1e-6;
}
fn init(a:anytype)void{
  for(a)|*v| {
    v.* = 0;
  }
}
