const random = @import("Random.zig");
const SEED = 113;
pub fn numFlops(NumSamples:i32)f64{
  return @intToFloat(f64,NumSamples) * 4.0;
}
pub fn integrate(NumSamples:i32)f64 {
  var R = random.new_seed(SEED);
  var under_curve:i32 = 0;

  var i:i32 = 0;
  while (i<NumSamples):(i+=1){
    const x = R.nextDouble();
    const y = R.nextDouble();

    if(x*x+y*y < 1.0){
      under_curve += 1;
    }
  }
  return @intToFloat(f64,under_curve) / @intToFloat(f64,NumSamples) * 4.0;
}
