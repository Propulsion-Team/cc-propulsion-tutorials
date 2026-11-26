-- PID import from advanced math
local pid = require("advanced_math/pid")

-- getting thrusters
local fl_th = peripheral.wrap("creative_thruster_0")
local fr_th = peripheral.wrap("creative_thruster_1")
local bl_th = peripheral.wrap("creative_thruster_2")
local br_th = peripheral.wrap("creative_thruster_3")

-- getting other moduels
local gimball = peripheral.wrap("top")

-- defining helper functions
function getAngles()
    local angs = gimball.getAngles()
    return {
        x = angs[1],
        z = -angs[2]
    }
end

function getAltitude()
    return sublevel.getLogicalPose().position.y
end

-- PIDs that we gonna use
local pitch_pid = pid.new(0, 0.01, 0.0005, 0.05)
local roll_pid = pid.new(0, 0.01, 0.0005, 0.05)
local alt_pid = pid.new(100, 0.05, 0.0001, 0.5)

-- main loop
while true do
    --getting ship state variables
    local angles = getAngles()
    local altitude = getAltitude()
    
    -- stepping pids 
    local pitch_pid_input = pitch_pid:step(angles.z)
    local roll_pid_input = roll_pid:step(angles.x)
    local alt_pid_output = math.max(alt_pid:step(altitude), 0)
    
    -- composing thruster inputs
    local fl_input, fr_input, bl_input, br_input
    fl_input = (pitch_input + roll_input) / 2 + alt_input
    fr_input = (pitch_input + -roll_input) / 2 + alt_input
    bl_input = (-pitch_input + roll_input) / 2 + alt_input
    br_input = (-pitch_input + -roll_input) / 2 + alt_input
    
    -- applying thrust
    parallel.waitForAll(
        function() fl_th.setThrustPN(fl_input * 600) end,
        function() fr_th.setThrustPN(fr_input * 600) end,
        function() bl_th.setThrustPN(bl_input * 600) end,
        function() br_th.setThrustPN(br_input * 600) end
    )
    
    -- our loop is done
end