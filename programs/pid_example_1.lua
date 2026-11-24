-- PID import from advanced math
local pid = require("advanced_math/pid")

-- getting thrusters
-- when you attach modem and activate modem on thruster, it will say what id it is.
local fl_th = peripheral.wrap("creative_thruster_0")
local fr_th = peripheral.wrap("creative_thruster_1")
local bl_th = peripheral.wrap("creative_thruster_2")
local br_th = peripheral.wrap("creative_thruster_3")

-- getting other moduels
local gimball = peripheral.wrap("top")
local redstone_bridge = peripheral.wrap("back")

-- defining helper functions
-- retuns list with X and Z angles, for this ship Z- is pitch up and X+ is roll right
function getAngles()
    return gimball.getAngles()
end

function getAltitude()
    return sublevel.getLogicalPose().position.y
end

function clamp(value, min, max)
    if min > max then error("minimum is greater than maximum value") end
    return math.min(math.max(value, min), max)
end


-- pids that we gonna use

-- first value on each one is setpoint, pid will try to maintain that value

-- second value is proportional value (Pv): 
-- it outputs pid directly based on error between current value and setpoint.

-- third value is integral value (Iv):
-- it remembers past error to correct small and persistant error.
-- example for altitude pid it will hover slightly below target altitude,
-- so Iv will correct it after small amount of time

-- forth value is derivative valie (Dv):
-- it tries to predict future input values and applies brake so it doesnt overshoot setpoint.
-- example for altitude pid it will overshoot target altitude again and again,
-- so Dv will brake near setpoint so it could reach it and mantain it.

local pitch_pid = pid.new(0, 0.01, 0.001, 0.1)
local roll_pid = pid.new(0, 0.01, 0.001, 0.1)
local alt_pid = pid.new(100, 0.05, 0.001, 0.5)

-- main loop
while true do
    --getting ship state variables
    local angles = getAngles()
    local pitch = -angles[2]
    local roll = angles[1]
    local altitude = getAltitude()
    
    -- stepping pids and clamping outputs
    -- if not clamp outputs one signal could overwhelm others and ship can destabilize
    local pitch_input = clamp(pitch_pid:step(pitch), -0.5, 0.5)
    local roll_input = clamp(roll_pid:step(roll), -0.5, 0.5)
    local alt_input = clamp(alt_pid:step(altitude), 0, 1)
    
    term.clear()
    print("pitch: "..pitch_input)
    print("roll: "..roll_input)
    print("altitude: "..alt_input)
    
    -- since pitch up is positive number and pitch down is negative.
    -- we should have positive pitch input for forward thrusters
    -- and negative input for backward thrusters.
    -- same thing is for roll.
    -- we have positive number for roll right and vise versa.
    -- so to roll right we need add positive number to left thrusters 
    -- and negative number to right thrusters.
    
    -- compositng inputs for thrusters
    -- for this one i use avrage value from pitch and roll and separate altitude input
    local fl_input, fr_input, bl_input, br_input
    fl_input = (pitch_input + roll_input) / 2 + alt_input
    fr_input = (pitch_input + -roll_input) / 2 + alt_input
    bl_input = (-pitch_input + roll_input) / 2 + alt_input
    br_input = (-pitch_input + -roll_input) / 2 + alt_input
    
    -- and last step in our loop is setting thrust for thrusters.
    -- but there an issue, every setPower() will take one tick tWo set thrust
    -- so we need "parallel" module to set power to all thrusters in one tick
    parallel.waitForAll(
        function() fl_th.setPowerNormalized(fl_input) end,
        function() fr_th.setPowerNormalized(fr_input) end,
        function() bl_th.setPowerNormalized(bl_input) end,
        function() br_th.setPowerNormalized(br_input) end
    )
    
    -- our loop is done
end