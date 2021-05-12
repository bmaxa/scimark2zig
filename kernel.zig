const time = @import("std").time;
const random = @import("Random.zig");
const fft = @import("FFT.zig");
const sor = @import("sor.zig");
const montecarlo = @import("MonteCarlo.zig");
const sparse = @import("SparseCompRow.zig");
const lu = @import("lu.zig");
const array = @import("array.zig");
const heap = @import("std").heap;
pub fn measureFFT(N:i32,min_time:f64,R:* random.Random)!f64 {
  const twoN = 2*N;
  const x = try R.vector(twoN);
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
  const y = try heap.c_allocator.alloc(f64,@intCast(usize,N));

  const nr = @divTrunc(nz,N);
  const anz = nr * N;

  const val = try R.vector(anz);
  const col = try heap.c_allocator.alloc(f64,@intCast(usize,nz));
  const row = try heap.c_allocator.alloc(f64,@intCast(usize,N+1));

  var cycles:i32 = 1;

  var r:usize = 0;
  while (r<N):(r+=1){
    const rowr = @floatToInt(usize,row[r]);
    var step =@divTrunc( @intCast(i32,r),nr);

    row[r+1] = @intToFloat(f64,@intCast(i32,rowr) + nr);

    if (step < 1) {
      step = 1;
    }
    var i:usize = 0;
    while (i<nr):(i+=1){
      col[rowr+i] = @intToFloat(f64,@intCast(i32,i) * step);
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
  var cycles:i32 = 1;
  var start:i64 = undefined;

  const A = try R.matrix(N,N);
  const alu = try array.new_Array2D_double(N,N);
  const pivot = try heap.c_allocator.alloc(usize,@intCast(usize,N));
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
