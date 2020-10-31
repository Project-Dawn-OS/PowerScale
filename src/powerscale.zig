/// This is just here for making a *.a file
extern fn sceRtcGetTickResolution() u32;
extern fn sceRtcGetCurrentTick(tick: *u64) c_int;
extern fn scePowerSetClockFrequency(pllfreq: c_int, cpufreq: c_int, busfreq: c_int) c_int;

/// Required variables
var currentTime: u64 = 0; // What is the current time
var tickRate: u32 = 0; // RTC tick rate
var lastTick: u64 = 0; // Last tick
var lastUsage: f64 = 0; // Last CPU Usage %
var cpuFreq: c_int = 333; // Current CPU Frequency
var cpuTargetUtil: f64 = 0.70; //Targeted utilization (0.7 = 70%)

/// Returns the CPU frequency
pub fn getCpuFreq() c_int{
    return cpuFreq;
}

/// Returns the CPU Usage
pub fn getUsage() f64 {
    return lastUsage;
}

/// Sets the CPU frequency (internal)
fn setCpuFreq(newFreq: c_int) void {
    if(newFreq <= 333){
        cpuFreq = newFreq;
        var stat = scePowerSetClockFrequency(newFreq, newFreq, @divFloor(newFreq, 2));
    }else{
        cpuFreq = 333;
        _ = scePowerSetClockFrequency(333, 333, 166);
    }
}

/// Sets the targeted utilization
pub fn setUsageTarget(target: f64) void {
   cpuTargetUtil = target; 
}

// Initializes the powerscale module
pub fn init() void {
    tickRate = sceRtcGetTickResolution();
    _ = sceRtcGetCurrentTick(&currentTime);
    setCpuFreq(333);
}

/// Terminates the module and sets frequency to 333 mhz
pub fn deinit() void {
    setCpuFreq(333); //Set this up just in case.
}

/// Starts a recording
pub fn startRecord() void {
    _ = sceRtcGetCurrentTick(&lastTick);
}

/// Ends Recording
pub fn endRecord() void {
    // Get our tick
    _ = sceRtcGetCurrentTick(&currentTime);

    // Calculate delta ticks
    var delta = @intToFloat(f64, @intCast(i64, currentTime) - @intCast(i64, lastTick));

    // Calculate total time taken in seconds
    var timeTaken: f64 = delta / @intToFloat(f64, tickRate);

    // Utilization = timeTaken / fpsTarget
    var timeUtil = timeTaken / (1 / 60.0);

    // Difference from desired CPU utilization
    var utilDiff = timeUtil - cpuTargetUtil;
    lastUsage = timeUtil;

    // Frequency = current frequency + (current frequency / 0.5) * difference in utilization.
    var newFreqCalc = @floatToInt(c_int, @intToFloat(f64, cpuFreq) + @intToFloat(f64, cpuFreq)/2.0 * utilDiff);

    // Limit the end result
    if(newFreqCalc < 20){
        newFreqCalc = 20;
    }
    if(newFreqCalc > 333){
        newFreqCalc = 333;
    }

    // Set the new frequency
    setCpuFreq(newFreqCalc);
}

