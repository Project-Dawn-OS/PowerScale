const psp = @import("Zig-PSP/src/psp/pspsdk.zig");

//STD Overrides!
pub const std = @import("std");
pub const os = @import("Zig-PSP/src/psp/pspos.zig");

const powerscale = @import("powerscale.zig");

comptime {
    asm(psp.module_info("Zig PSP App", 0, 1, 0));
}

extern fn scePowerSetClockFrequency(pllfreq: c_int, cpufreq: c_int, busfreq: c_int) c_int;
pub fn main() !void {
    psp.utils.enableHBCB();
    psp.debug.screenInit();
    
    powerscale.init();
    defer powerscale.deinit();

    // Create a database
    var f = try std.fs.cwd().createFile("./test.csv", .{.truncate = true});
    defer f.close();


    var i : u32 = 2;
    while(true) : (i += 1) {
        // Start recording
        powerscale.startRecord();

        // Use this expression to control the stress curve
        var times: usize = if(i < 100) 20 * (100/2 % 100) else if(i < 150) 20 * (i/2 % 100) else 20 * (20/2 % 100);

        // Artificial benchmark
        // Run Cosine `times` number of times on iterator `z`.
        var z : usize = 0;
        while(z < times) : (z += 1){
            @setRuntimeSafety(false);
            var x = std.math.cos(@intToFloat(f64, z));            
        }

        // End of recording
        if(20 * (i/2 % 100) == 0){
            psp.sceKernelExitGame();
        }

        // Set frequency
        powerscale.endRecord();

        // Give us ze data!
        try f.writer().print("{d},{}\n", .{powerscale.getUsage() * 100, psp.scePowerGetCpuClockFrequency()});

        // Not necessarily important here - it's not a factor in this application.
        //_ = psp.sceDisplayWaitVblankStart();
    }
}
