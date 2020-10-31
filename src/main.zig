//A quick graphics initialization
const psp = @import("Zig-PSP/src/psp/pspsdk.zig");
pub const panic = psp.debug.panic;

//STD Overrides!
pub const os = @import("Zig-PSP/src/psp/pspos.zig");
const powerscale = @import("powerscale.zig");

pub const std = @import("std");

comptime {
    asm(psp.module_info("Zig PSP App", 0, 1, 0));
}
pub var blkA: [4096]u8 = undefined;
pub var blkB: [4096]u8 = undefined;

extern fn scePowerSetClockFrequency(pllfreq: c_int, cpufreq: c_int, busfreq: c_int) c_int;
pub fn main() !void {
    psp.utils.enableHBCB();
    psp.debug.screenInit();
    
    powerscale.init();
    defer powerscale.deinit();

    var f = try std.fs.cwd().createFile("./test.csv", .{.truncate = true});

    var i : u32 = 2;
    while(true) : (i += 1) {
        powerscale.startRecord();

        var z : usize = 0;
        var times: usize = if(i < 100) 20 * (100/2 % 100) else if(i < 150) 20 * (i/2 % 100) else 20 * (20/2 % 100);
        while(z < times) : (z += 1){
            @setRuntimeSafety(false);   
            var x = std.math.cos(@intToFloat(f64, z));

            
        }  
        if(20 * (i/2 % 100) == 0){
            psp.sceKernelExitGame();
        }

        powerscale.endRecord();

        try f.writer().print("{d},{}\n", .{powerscale.getUsage() * 100, psp.scePowerGetCpuClockFrequency()});
        //_ = psp.sceDisplayWaitVblankStart();
    }
}
