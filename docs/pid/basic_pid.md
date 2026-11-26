# Basic PID

In this tutorial we will make a basic hover platform to understand the usage of PIDs.

## Setup
For this setup we will use a simple platform with a computer, 4 thrusters and a gimbal.

<figure markdown="span">
![Hover platfom](https://propulsion-team.github.io/cc-propulsion-tutorials/assets/basic_pid/hover_platform.png){ width="600" }
<figcaption>Used Computer Greencraft resource pack</figcaption>
</figure>

## Code
Now here is the hard part. We have to make it hover and keep balance using PIDs.

### Imports and peripherals setup
For this you can add usage for PID module from Advanced Math. For this you can use mod [CC: Sable](https://modrinth.com/mod/cc-sable)
or standalone [Advanced Math](https://modrinth.com/datapack/advanced_math) datapack.
```lua
local pid = require("advanced_math/pid")
```
It will allow us to create PIDs later in the tutorial.

Now add peripherals for our thrusters. For it, we will use IDs that modems give use when we add thrusters to the network.
<figure markdown="span">
![Hover platfom](https://propulsion-team.github.io/cc-propulsion-tutorials/assets/basic_pid/modem_connection.gif){ width="600" }
<figcaption>Connecting thruster via modem</figcaption>
</figure>

And then use our IDs to get thruster peripherals. With those peripherals, we will set thrust for our thrusters.
```lua
local fl_th = peripheral.wrap("creative_thruster_0")
local fr_th = peripheral.wrap("creative_thruster_1")
local bl_th = peripheral.wrap("creative_thruster_2")
local br_th = peripheral.wrap("creative_thruster_3")
```
!!! node
Good practice is to name your thrusters as something easy and short.
In this example I use fl_th, fr_th, bl_th and br_th, it stands for:
Front left thruster, front right thruster, back left thruster and back right thruster.
It makes it easier to write and understand code.

Finally, get a peripheral for our gimbal. Since it is on top of the computer, we don't need to activate any modems, just use `top` id.
```lua
local gimbal = peripheral.wrap("top")
```

### Some useful functions
To not overwhelm yourself and make code more readable, we could do some useful functions. Like for getting angles from a gimbal or getting altitude.

For angles, we will pack angles from a gimbal onto a nice table.
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
    Change code accordingly.

For altitude, we will use [CC: Sable's](https://modrinth.com/mod/cc-sable) `sublevel` api to get sublevel's altitude.

```lua
function getAltitude()
return sublevel.getLogicalPose().position.y
end
```
### Making PIDs
PIDs is backbone of our script and we need 3 of them, for pitch, roll and altitude.

To create PIDs we have to use our imported PID library that we saved in `pid` variable.
```lua
pid.new(Sp, Pv, Iv, Dv)
```
> Sp is set point; Pv, Iv and Dv are our tuning parameters.

Our PIDs.
```lua
local pitch_pid = pid.new(0, 0.01, 0.0005, 0.05)
local roll_pid = pid.new(0, 0.01, 0.0005, 0.05)
local alt_pid = pid.new(100, 0.05, 0.0001, 0.5)
```
Those parameters are for my platform and will be different across different builds.

### Main loop
Time for an interesting part - the main loop. It will run every tick to get the ship's state, process PIDs and set thrusts.

#### Stepping PIDs
The first part of a main loop is to get the ship's state and step PIDs.

```lua
--getting ship state
local angles = getAngles()
local altitude = getAltitude()

-- stepping pids
local pitch_pid_output = pitch_pid:step(angles.z)
local roll_pid_output = roll_pid:step(angles.x)
local alt_pid_output = alt_pid:step(altitude)
```
Also, it's a good idea to limit altitude output, so the ship won't lose control on descent
```lua
local alt_pid_output = math.max(alt_pid:step(altitude), 0)
```


`step()` function in PIDs takes Pv (Process variable) to calculate error from Sp and use tuning parameters
to produce output that we will use for thrust in different thrusters.

#### Composing thruster inputs
Now we have PID outputs, but we can't use them directly for thrust since all thrusters need to react differently for all 3 outputs.
We have to compose outputs into thruster inputs individually for all thrusters.

Let's start with pitch. In order to pitch up our ship, we have to apply positive input for front thrusters and negative input for back thrusters.
```lua
local fl_input, fr_input, bl_input, br_input
fl_input = pitch_output
fr_input = pitch_output
bl_input = -pitch_output
br_input = -pitch_output
```

Then roll. In order to roll our ship right, we have to apply positive input for left thrusters and negative input for back thrusters.
```lua
local fl_input, fr_input, bl_input, br_input
fl_input = pitch_output + roll_output
fr_input = pitch_output + -roll_output
bl_input = -pitch_output + roll_output
br_input = -pitch_output + -roll_output
```
Also, it's a good idea to take an average of inputs to not overthrust when ship needs to pitch and roll at the same time.
```lua
local fl_input, fr_input, bl_input, br_input
fl_input = ( pitch_output + roll_output) / 2
fr_input = ( pitch_output + -roll_output) / 2
bl_input = (-pitch_output + roll_output) / 2
br_input = (-pitch_output + -roll_output) / 2
```

And the last one is altitude. For it just add altitude output for all thrusters, since we need input on all thrusters to go up or down.
```lua
local fl_input, fr_input, bl_input, br_input
fl_input = ( pitch_output + roll_output) / 2 + alt_input
fr_input = ( pitch_output + -roll_output) / 2 + alt_input
bl_input = (-pitch_output + roll_output) / 2 + alt_input
br_input = (-pitch_output + -roll_output) / 2 + alt_input
```

#### Applying thrust
In the last part of our loop, we have to apply thrust. We are going to use the `setThrustPN()` function, but we have an issue with that.
`setThrustPN()` takes one tick to apply thrust, and when we have 4 thrusters our loop will work 5 times a second and it is too slow.
So we have to set thrusts in parallel and for that we have a pretty handy API. `parallel` allows you to call multiple functions in parallel.
And with that we could set thrust for all of our thrusters in one tick. That means our loop will work 20 times a second, which is plenty of speed.
```lua
parallel.waitForAll(
function() fl_th.setThrustPN(fl_input * 600) end,
function() fr_th.setThrustPN(fr_input * 600) end,
function() bl_th.setThrustPN(bl_input * 600) end,
function() br_th.setThrustPN(br_input * 600) end
)
```

#### Full loop
Our loop is done, wrap it in `while true do` so it will run infinitely and we are good to go.
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
fl_input = ( pitch_input + roll_input) / 2 + alt_input
fr_input = ( pitch_input + -roll_input) / 2 + alt_input
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