pub fn num_flops(N:i32,nz:i32,num_iterations:i32)f64{
  const actual_nz = @divTrunc(nz,N)*N;
  return @intToFloat(f64,actual_nz) * 2.0 * @intToFloat(f64,num_iterations);
}
pub fn matmult(M:i32,y:[]f64,val:[]f64,row:[]f64,col:[]f64,x:[]f64,NUM_TERATIONS:i32)void{
  var reps:i32=0;
  while(reps<NUM_TERATIONS):(reps+=1){
    var r:usize = 0;
    while (r<M):(r+=1){
      var sum:f64 = 0.0;
      const rowR = @floatToInt(usize,row[r]);
      const rowRp1 = @floatToInt(usize, row[r+1]);
      var i:usize = rowR;
      while (i<rowRp1):(i+=1){
        sum += x[@floatToInt(usize,col[i])]*val[i];
      }
      y[r] = sum;
    }
  }
}
