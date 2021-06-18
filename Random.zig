const allocator = @import("allocator.zig").allocator;
const MDIG = 32;
const ONE = 1;
const m1 = (ONE << (MDIG - 2)) + ((ONE << (MDIG - 2)) - ONE);
const m2 = ONE << MDIG / 2;
const heap = @import("std").heap;
var dm1: f64 = 1.0/@intToFloat(f64,m1) ;

pub const Random = struct {
  m: [17]u32,
  seed: u32,
  i:u32,
  j:u32,
  haveRange:bool,
  left:f64,
  right:f64,
  width:f64,
  pub fn vector(self:* Random,N:i32)![]f64{
    var rc:[]f64 = try allocator().alloc(f64,@intCast(usize,N)); //[_]f64{0} ** ;
    for (rc) |*v| {
      v.* = self.nextDouble();
    }
    return rc;
  }
  pub fn matrix(self:*Random,M:i32,N:i32)anyerror![][]f64 {
    var rc:[][]f64 = try allocator().alloc([]f64,@intCast(usize,M));
    for (rc) |*row| {
      row.* = try allocator().alloc(f64,@intCast(usize,N));
      for (row.*) |*v| {
        v.* = self.nextDouble();
      }
    }
    return rc;
  }
  pub fn nextDouble(self:* Random )f64{
    var k:i32 = 0;
    var i:usize = @intCast(usize,self.i);
    var j:usize = @intCast(usize,self.j);
    var m = self.m;
    k = @intCast(i32,if (m[i]>m[j])m[i]-m[j] else m[j]-m[i]);
    if (k<0)k+=m1;
    self.m[j]=@intCast(u32,k);
    if (i==0){i=16;}else i-=1;
    self.i = @intCast(u32,i);
    if (j==0){j=16;} else j-=1;
    self.j = @intCast(u32,j);
    return if (self.haveRange)self.left + dm1 * @intToFloat(f64,k) * self.width
    else dm1 * @intToFloat(f64,k);
  }
  fn initialize(self: *Random, seed: u32) void{
    var lseed:u64= seed;
    var jseed:u64=0;
    var k0:u64=0;
    var k1:u64=0;
    var j0:u64=0;
    var j1:u64=0;
    self.seed = seed;
    if (seed < 0)
      lseed = -seed;
    jseed = if (lseed<m1)lseed else m1;
    if (@rem(jseed,2) == 0) jseed-=1;
    k0 = 9069 % m2;
    k1 = 9069 / m2;
    j0 = @rem(jseed,m2);
    j1 = @divTrunc(jseed,m2);
    var iloop:usize = 0;
    while (iloop<17):(iloop+=1) {
      jseed = j0 * k0;
      j1 = @rem((@divTrunc(jseed,m2) + j0 * k1 + j1 * k0),(m2 / 2));
      j0 = @rem(jseed,m2);
      self.m[iloop] = @intCast(u32,j0 + m2 * j1);
    }
    self.i = 4;
    self.j = 16;
  }
};
pub fn new(seed:i32,left:f64,right:f64)Random {
  var rc = Random{.m = [_]i32{0} ** 17,.seed = seed, .i = 0, .j = 0, .haveRange = true,
  .left = left, .right = right, .width = right - left};
  rc.initialize(seed);
  return rc;
}
pub fn new_seed(seed:u32)Random{
  var rc = Random{.m = [_]u32{0} ** 17,.seed = seed, .i = 0, .j = 0, .haveRange = true,
  .left = 0.0, .right = 1.0, .width = 1.0};
  rc.initialize(seed);
  return rc;
}
