const std = @import("std");
var gpa = @import("std").heap.GeneralPurposeAllocator(.{}){};
pub fn allocator() *std.mem.Allocator {
    return &gpa.allocator;
}
