extern fn sceRtcGetTickResolution() u32;
extern fn sceRtcGetCurrentTick(tick: *u64) c_int;
pub extern fn scePowerSetClockFrequency(pllfreq: c_int, cpufreq: c_int, busfreq: c_int) c_int;


const std = @import("std");

var cpuFreq: c_int = 333;

pub fn getCpuFreq() c_int{
    return cpuFreq;
}

fn setCpuFreq(newFreq: c_int) void {
    if(newFreq <= 333){
        cpuFreq = newFreq;
        var stat = scePowerSetClockFrequency(newFreq, newFreq, @divFloor(newFreq, 2));
    }else{
        cpuFreq = 333;
        _ = scePowerSetClockFrequency(333, 333, 166);
    }
}

var currentTime: u64 = 0;
var tickRate: u32 = 0;
var cpuTargetUtil: f64 = 0.70;
var lastTick: u64 = 0;
var lastUsage: f64 = 0;

pub fn init() void {
    tickRate = sceRtcGetTickResolution();
    _ = sceRtcGetCurrentTick(&currentTime);
    setCpuFreq(16);
}

pub fn setCPUUsageTarget(target: f64) void {
   cpuTargetUtil = target; 
}

pub fn deinit() void {
    setCpuFreq(333); //Set this up just in case.
}

pub fn startRecord() void {
    _ = sceRtcGetCurrentTick(&lastTick);
}

pub fn getUsage() f64 {
    return lastUsage;
}

pub fn endRecord() void {
    @setRuntimeSafety(false);
    _ = sceRtcGetCurrentTick(&currentTime);
    tickRate = sceRtcGetTickResolution();

    var delta = @intToFloat(f64, @intCast(i64, currentTime) - @intCast(i64, lastTick));
    var timeTaken: f64 = delta / @intToFloat(f64, tickRate); //Time in seconds.

    var timeUtil = timeTaken / (1 / 60.0);
    var utilDiff = timeUtil - cpuTargetUtil;
    lastUsage = timeUtil;

    var newFreqCalc = @floatToInt(c_int, @intToFloat(f64, cpuFreq) + @intToFloat(f64, cpuFreq)/2.0 * utilDiff);

    if(newFreqCalc < 20){
        newFreqCalc = 20;
    }
    if(newFreqCalc > 333){
        newFreqCalc = 333;
    }
    setCpuFreq(newFreqCalc);
}

