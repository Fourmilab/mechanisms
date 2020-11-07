
#   Demonstration of the Gimbals mechanism

#   Reset to known state

@panic gently

@script pause 3
@echo Rotate outermost (red/cyan) ring by 30 degrees.

RX 30

@echo Note how this rotates the two inner (child) rings with it.

@script pause 3

@echo Rotate outer ring back to its original position.

RX -30

@script pause 3

@echo Rotate middle (green/magenta) ring by 45 degrees.
@echo Its pivots and the inner (blue/yellow) ring move with
@echo it, but the outer ring is unaffected.

RY 45

@script pause 3

@echo Rotate the inner (blue/cyan) ring by -45 degrees,
@echo affecting only it and its pivots.

RZ -45

@script pause 3

@echo Rotate the outer ring by -25 degrees, with the middle
@echo and inner rings moving with it.

RX -25

@script pause 3

@echo Smoothly spin the entire mechanism 360 degrees around
@echo the vertical axis, showing the rings as rotated.

Spin Mech <1,0,0> 1 1 360

@script pause 3

@echo Start the middle ring rotating smoothly around
@echo its pivots.

Spin Y <0, 1, 0> 0.5 1

@echo The inner ring spins with it, while the outer ring
@echo is unaffected.

@script pause 3

@echo Spin the inner ring in the opposite direction, while
@echo the middle ring continues to spin.

Spin Z <0, -1, 0> 0.25 1

@script pause 3

@echo Spin the outer ring 180 degrees, while the middle and
@echo inner rings spin.

Spin X <0, 0, 1> 0.25 1 180

@echo Motion may be a little jerky when you spin multiple
@echo components at once due to simulator and viewer lag.

@script pause 3

@echo Stop the spin of the inner ring.  The middle ring
@echo continues its spin.

Spin Z <0, -1, 0> 0 0

@script pause 3

@echo Move (translate) the inner ring 0.1 metres along
@echo the X axis of its (spinning) parent, the middle ring.

Translate Z <0.2, 0, 0>

@echo Note how it continues to spin with its parent, the
@echo middle ring.

@script pause 3

@echo Rotate the inner ring by 90 degrees.

RZ 90

@script pause 3

@echo Move it back into alignment with the middle ring.

Translate Z <-0.2, 0, 0>

@script pause 3

@echo Motion is relative to parent, so rotation of the
@echo middle ring doesn't matter.  Stop the rotation of
@echo the middle ring.

Spin Y <0, 1, 0> 0 0

@script pause 3

@echo Smooth motion is also possible.  Send the middle and
@echo child inner rings on a little round trip.

Move Y <0, 0, 1> 0.1 0.25
Move Y <0, 1, 0> 0.1 0.25
Move Y <0,-1,-1> 0.1 0.25

@script pause 3

@echo Here is the definition of the mechanism in the notecard.
@echo Components are specified by their link names.
@echo

@echo Set parent "X Ring"   "X Pivot A" "X Pivot B" "Y Ring"
@echo    Set parent "Y Ring"   "Y Pivot A" "Y Pivot B" "Z Ring"
@echo        Set parent "Z Ring"   "Z Pivot A" "Z Pivot B"

@echo

@script pause 2

@panic gently

@echo See the documentation notecards for complete details.

