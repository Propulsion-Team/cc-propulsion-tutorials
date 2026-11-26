# Basic PID

In this tutorial we gonna make basic hover platform to understand usage of PIDs.

## Setup
For this setup we gonna use simple platform with computer, 4 thrusters and a gimbal.

<figure markdown="span">
![Hover platfom](https://propulsion-team.github.io/cc-propulsion-tutorials/assets/basic_pid/hover_platform.png){ width="600" }
<figcaption>Used Computer Greencraft resource pack</figcaption>
</figure>

## Code
Now hard part. We have to make it hover and keep balance using PIDs.

### Imports and peripherals setup
Add usege for PID module from Advanced Math, for it you can use mod [CC: Sable](https://modrinth.com/mod/cc-sable)
or standalone [Advanced Math](https://modrinth.com/datapack/advanced_math) datapack.
```lua
local pid = require("advanced_math/pid")
```
It will allow us to create PIDs later in the tutorial.

Now add peripherals for our thrusters. In it we gonna use IDs that modems give use when we add thrusters to the network.
<figure markdown="span">
![Hover platfom](https://propulsion-team.github.io/cc-propulsion-tutorials/assets/basic_pid/modem_connection.gif){ width="600" }
<figcaption>Connecting thruster via modem</figcaption>
</figure>

And then use our IDs to get thruster peripherals, with thouse peripherals we gonna set thrust for our thrusters.
```lua
local fl_th = peripheral.wrap("creative_thruster_0")
local fr_th = peripheral.wrap("creative_thruster_1")
local bl_th = peripheral.wrap("creative_thruster_2")
local br_th = peripheral.wrap("creative_thruster_3")
```
!!! node
    Good practise is name your thrusters something easy and short.
    in this example i use fl_th, fr_th, bl_th and br_th, it stands for:
    front left thruster, front right thruster, back left thruster and back right thruster.
    it makes easier to write and understand code.

For the last, get peripheral for our gimbal. Since it on top of the computer, we dont need to activate any modems, just use `top` id.
```lua
local gimbal = peripheral.wrap("top")
```

### Some usefull functions
To not overwhelm yourself and make code more readable we could make some usefull functions. Like for getting angles from gimbal or getting altitude.

For angles we gonna pack angles from gimbal in to nice table.
```lua
function getAngles()
    local angs = gimball.getAngles()
    local angs_table = {}
    angs_table.x = angs[1] -- for setup in guide +X is roll right
    angs_table.z = -angs[2] -- and -Z is pitch up
    return angs_table
end
```
!!! note

    Be careful, depending on how you created your sublevel Z and X rotations could be different.
    Change code Accordingly.

For altitude we gonna use [CC: Sable's](https://modrinth.com/mod/cc-sable) to get sublevel's altitude.

```lua
function getAltitude()
    return sublevel.getLogicalPose().position.y
end
```
### Making PIDs
PIDs is back bone of our script and we need 3 of them, for pitch, roll and altitude.

To create PIDs we have to use our imported PID library that we saved in `pid` variable.
```lua
pid.new(Sp, Pv, Iv, Dv)
```
> Sp is set point; Pv, Iv and Dv are our tunning parameters

Our PIDs.
```lua
local pitch_pid = pid.new(0, 0.01, 0.0005, 0.05)
local roll_pid = pid.new(0, 0.01, 0.0005, 0.05)
local alt_pid = pid.new(100, 0.05, 0.0001, 0.5)
```
Thouse parameters are for my platform and will be between different builds.

### Main loop
Time for interesting part - main loop. it will run every tick to get ship's state, process PIDs and set thrusts.

#### Stepping PIDs
First part of a main loop is get ship's state and step PIDs

```lua
--getting ship state
local angles = getAngles()
local altitude = getAltitude()

-- stepping pids 
local pitch_pid_output = pitch_pid:step(angles.z)
local roll_pid_output = roll_pid:step(angles.x)
local alt_pid_output = alt_pid:step(altitude)
```
Also its a good idea to limit altitude output so ship wont lose control on decent
```lua
local alt_pid_output = math.max(alt_pid:step(altitude), 0)
```


`step()` function in PIDs takes Pv (Process varialble) to calculate error from Sp and use tunning parameters
to produce output that we gonna use for thrust in different thrusters.

#### Composing thruster inputs
Now we have PID outputs but we can't use them directly in for thrust since all thrusters need to react differently for all 3 outputs.
We have to compose outputs in to thruster inputs individual for all thrusters.

Lets start with pitch. In order to pitch up our ship, we have to apply positive input for front thrusters and negative input for back thrusters.
```lua
local fl_input, fr_input, bl_input, br_input
fl_input =  pitch_output
fr_input =  pitch_output
bl_input = -pitch_output
br_input = -pitch_output
```

Then roll. In order to roll right our ship, we have to apply positive input for left thrusters and negative input for back thrustrers.
```lua
local fl_input, fr_input, bl_input, br_input
fl_input =  pitch_output +  roll_output
fr_input =  pitch_output + -roll_output
bl_input = -pitch_output +  roll_output
br_input = -pitch_output + -roll_output
```
Also its a good idea to take avrage of inputs to not overthrust when ship needs to pitch and roll at the same time.
```lua
local fl_input, fr_input, bl_input, br_input
fl_input = ( pitch_output +  roll_output) / 2
fr_input = ( pitch_output + -roll_output) / 2
bl_input = (-pitch_output +  roll_output) / 2
br_input = (-pitch_output + -roll_output) / 2
```

And last one is altitude. For it just add altitude output for all thrusters since we need all input on all thruster to go up or down.
```lua
local fl_input, fr_input, bl_input, br_input
fl_input = ( pitch_output +  roll_output) / 2 + alt_input
fr_input = ( pitch_output + -roll_output) / 2 + alt_input
bl_input = (-pitch_output +  roll_output) / 2 + alt_input
br_input = (-pitch_output + -roll_output) / 2 + alt_input
```

#### Applying thrust
Last part of our loop. we have to apply thrust. We gonna use `setThrustPN()` function, but we have an issue with that.
`setThrustPN()` takes one tick to apply thrust, and when we have 4 thrusters our loop gonna work 5 times as second at it is too slow.
So we have to set thrusts in parallel and for that we have pretty handy API. `parallel` allow you call multiple functions in parallel,
and with that we could set thrust for all of our thrusters in one tick. That means our loop gonna work 20 times a second wich is plenty of speed.
```lua
parallel.waitForAll(
    function() fl_th.setThrustPN(fl_input * 600) end,
    function() fr_th.setThrustPN(fr_input * 600) end,
    function() bl_th.setThrustPN(bl_input * 600) end,
    function() br_th.setThrustPN(br_input * 600) end
)
```

#### Full loop
Our loop is done, wrap it in `while true do` so it will run infinetly and we good to go.
```lua
while true do
    -- getting ship state variables
    local angles = getAngles()
    local altitude = getAltitude()

    -- stepping pids 
    local pitch_pid_input = pitch_pid:step(angles.z)
    local roll_pid_input = roll_pid:step(angles.x)
    local alt_pid_output = math.max(alt_pid:step(altitude), 0)

    -- composing thruster inputs
    local fl_input, fr_input, bl_input, br_input
    fl_input = ( pitch_input +  roll_input) / 2 + alt_input
    fr_input = ( pitch_input + -roll_input) / 2 + alt_input
    bl_input = (-pitch_input +  roll_input) / 2 + alt_input
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
```

<figure markdown="span">
![Hover platfom](https://propulsion-team.github.io/cc-propulsion-tutorials/assets/basic_pid/hover_test.gif){ width="600" }
<figcaption>Platform test</figcaption>
</figure>

## Full Script
Full implementation:

```lua linenums="1"
--8<-- "programs/pid_example_1.lua"
```
