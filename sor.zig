pub fn num_flops(M:i32,N:i32,num_iterations:i32)f64{
  const Md = @intToFloat(f64,M);
  const Nd = @intToFloat(f64,N);
  const num_iterD = @intToFloat(f64,num_iterations);

  return (Md - 1.0) * (Nd - 1.0) * num_iterD*6.0;
}
pub fn execute(M:i32,N:i32,omega:f64,G:[][]f64,num_iterations:i32)void{
  const omega_over_four = omega * 0.25;
  const one_minus_omega = 1.0 - omega;

  const Mm1 = M - 1;
  const Nm1 = N - 1;
  var p:i32 = 0;
  while (p<num_iterations):(p+=1){
    var i:usize = 1;
    while (i<Mm1):(i+=1) {
      const Gi = G[i];
      const Gim1 = G[i-1];
      const Gip1 = G[i+1];
      var j:usize = 1;
      while (j<Nm1):(j+=1){
        Gi[j] = omega_over_four * (Gim1[j] + Gip1[j] + Gi[j-1] +
                                   Gi[j+1]) + one_minus_omega * Gi[j];
      }
    }
  }
}
