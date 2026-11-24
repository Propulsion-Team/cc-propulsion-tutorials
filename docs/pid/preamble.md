# What is PID?
PID (Proportion, Integral, Derivative) is a feedback based control loop system.
It works on systems with linear outputs, if a system has non-linear outputs
the outputs must first be linearized. 

!!! note

    It isn't important that you understand everything in this preamble, you could
    skip large sections of it and still have success with the later tutorials.
    However, understanding it will help when you want to design your own
    bespoke system.

## Simplified Explanation
PID corrects error in a system, by looking at how far it is from the target point
(P), how quickly it's approaching the target (D), and the changes it's had to
make in the past to reach that target (I). It can be tuned using three values,
$K_p$, $K_i$ and $K_d$.

## Mathematical Explanation

!!! Warning

    Look at the previous note

Let's imagine we have a function $PV(t)$, Process Variable. It's value is the
result of a process in some physical system. Let's imagine we have another
function called $u(t)$ that we can set the value of, it has a linear effect
on the value of $PV(t)$, where $u(t)$ accumulates in the rate of change of
$PV(t)$. And lastly, let's imagine a variable called $S_p$, or set point that
tells us what the current target for $PV(t)$ is.

A PID system will first determine the error between $PV(t)$ and $S_p$.

$$
e(t) = SP - PV(t)
$$

The first part of the PID controller is Proportional, so let's set our
$u(t)$ to try and correct for this error.

$$
u(t) = K_p e(t)
$$
$K_p$ is a coefficient that we multiply by the error. PID systems have to be
tuned depending on what they control, and these coefficients are the main way
of tuning.

The issue is since $u(t)$ doesn't directly control $SP(t)$, and can only affect
its rate of change, this controller will make no attempt to slow down and will
overshoot the desired $SP$, oscillating forever around that value (in an ideal
system).

PID's solution to this problem is to introduce the D term (derivative). We can
measure the rate of change of e(t) by taking its derivative, and then add that
to our value of $u(t)$

$$
u(t) = K_p e(t) + K_d \frac{ \mathrm{ d } e(t) }{ \mathrm{ d } t }
$$

Again, we introduce a coefficient $K_d$ that allows us to tune how much
of an impact the derivative has. In almost all systems $K_d < 0$, otherwise
it would increase the magnitude of oscillation ("undampen").

This PD controller system is quite robust (It was good enough for NASA to use
on the Saturn V launch vehicle), but in some systems there may still be one
more issue. If there is some constant term in $SP(t)$, even at the setpoint
then $SP(t)$ will slip from the target value before the system corrects for it,
creating another oscillation. This is commmon in unbalanced vehicles.
The I in PID (integration) allows us to give a value to $u(t)$ even when the rate
of change and error from the target hit 0. We add little bits of the error
to a variable over time and then add that to our $u(t)$ term.

$$
u(t) = K_p e(t) + K_i \int e(t) \mathrm{d}t + K_d \frac{\mathrm{d} e(t)}{ \mathrm{d} t}
$$

Again, we introduce a coefficient on this term so it can be reduced later,
typically $K_i < 0$. We have invented the PID controller.

To take derivatives and integrate a function that we don't have, since we're
not aiming for mathematical perfection, we can measure how much $e(t)$ changed
since the last cycle of our program, and divide it by the time difference
$\mathrm{d} t$. This will give us a good approximation of what the difference
really is. To integrate we can just add this value to another variable over
and over again, giving is our integral term.
