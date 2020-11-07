
                    Fourmilab Geometric Calculator

                                  User Guide

The Fourmilab Geometric Calculator is a Second Life Linden Scripting
Language (LSL) program which can be installed into any Second Life
object.  Accepting commands from local chat on its channel (by default,
1805, the birth date of William Rowan Hamilton, mathematician,
physicist, and inventor of quaternions [mathematical objects which
allow easy manipulation of rotations in three-dimensional space]), it
allows you to evaluate expressions involving numbers, vectors, and
rotations; functions of these quantities; query positions and rotations
of components of the object in which it is installed; and modify these
object properties, with an “undo” facility for correcting errors and
experimenting.

Most operations are performed with the “Calc” command.  For example, to
divide 377 by 120 (a rational approximation of π known to Ptolemy in
the second century B.C.), you would use:
    /1805 calc 377 / 120
    377 / 120 = 3.141667

(In subsequent examples, I will omit the chat channel number, “/1805”
in this case.)  The calculator answers with the result, expressed to
the precision of Second Life's single-precision floating point numbers.
How accurate is this an approximation of π?  Let's subtract it from π,
using one of the calculator's built-in constants (all of the
mathematical constants supported by Linden Scripting Language are
available):
    calc $ - PI
    3.141667 - 3.141593 = 0.000074
Here, we use the calculator's short-cut of “$” to specify the result of
the last calculation—we could have re-typed or cut and pasted it, but
this is easier and faster.  To express this as a fraction of the
correct value, compute:
    calc $ / PI
    0.000074 / 3.141593 = 0.000023
which we can multiply by 100 to express the value as a percentage:
    calc $ * 100
    0.000023 * 100 = 0.002345
thus, accurate within 0.23%.

The calculator ignores the distinction between upper and lower case
letters: you could have typed “Calc”, “CALC”, or “CaLc” if you wished.
You must separate items in the calculation by spaces: “3*3” will not
work: you must use “3 * 3”.  General expressions involving more than
one operator are not supported: only a single operation may be done in
each calculation.

So far, the calculator doesn't do anything you can't accomplish with
the little-known “calc” feature of the Firestorm viewer's chat bar.
The power of the Geometric Calculator comes from its understanding of
the foundations of Second Life's three-dimensional geometry: vectors
and rotations.

Vectors

Vectors are composed of three floating point values and may represent
quantities such as directions, positions in space, or even colours.
Vectors are specified by their three components, separated by commas,
within angle brackets.  Here we multiply a vector by a number to scale
it (multiply each component by the number).
    calc <1, 2, 3> * 10
    <1, 2, 3> * 10 = <10, 20, 30>
Similarly, we can divide by a number (using the “$” short-cut, which
works for all quantities in the calculator).
    calc $  / 5
    <10, 20, 30> / 5 = <2, 4, 6>
To compute the scalar or dot product of two vectors, use:
    calc <1, 1, 0> * <0, 1, 1>
    <1, 1, 0> * <0, 1, 1> = 1
and for the cross (or vector) product, the “%” operator is used:
    calc <1, 1, 0> % <0, 1, 1>
    <1, 1, 0> % <0, 1, 1> = <1, -1, 1>
You can add or subtract the components of vectors as follows:
    calc <8, 9, 11> + <2, 3, -3>
    <8, 9, 11> + <2, 3, -3> = <10, 12, 8>
or:
    calc <8, 9, 11> - <2, 3, -3>
    <8, 9, 11> - <2, 3, -3> = <6, 6, 14>
A variety of functions operate on vectors.  For the magnitude of a
vector, for example, use:
    calc mag <20, 10, 17>
    mag(<20, 10, 17>) = 28.08914
You can also normalise a vector (scale its components so its magnitude
is one) with:
    calc norm <30, 40, 50>
    norm(<30, 40, 50>) = <0.42426, 0.56569, 0.70711>

Rotations

Rotations may be specified in two forms: as quaternions composed of
four components:
    <0.43046, 0.0923, 0.70106, 0.56099>
or triples of Euler angles, giving rotations about the X, Y, and Z
axes in the order Z-Y-Z:
    {30,45,90}
Note that curly brackets are used for Euler angle rotations to
distinguish them from vectors.  The angles in Euler angle rotations are
in degrees by default; if you prefer radians, use the command:
    calc set angles radians
and to change back to degrees:
    calc set angles degrees
This affects both the input and display of Euler angles, and the
arguments and results of functions involving angles.

You can compose two rotations to yield the result of performing the
rotations in sequence with the “*” and “/” operators.  For example, to
rotate 60 degrees around the Y axis, then 90 degrees around the Z axis:
    calc {0, 60, 0} * {0, 0, 90}
    {0, 60, 0} * {0, 0, 90} = {-60, 0.00001, 90}
(Due to the limited precision of numbers in Second Life, you'll often
see small discrepancies from ideal values, such as the Y co-ordinate of
the result here.)  Note that rotations are non-commutative: performing
two rotations in the opposite order will often have an entirely
different result.  For example:
    calc {0, 0, 90} * {0, 60, 0}
    {0, 0, 90} * {0, 60, 0} = {0.00001, 60, 90}
To reverse the direction of a rotation, use the “/” operator:
    calc {-60, 0.00001, 90} / {0, 0, 90}
    {-60, -0.00001, 90.00001} / {0, 0, 90} = {0, 60, 0}
Here we've “backed out” the 90 degree rotation about the Z axis in the
first example above.

You can rotate a vector through a rotation with the “*” and “/”
operators with the vector as the left and rotation as the right
operand.  Here we take a unit vector along the X axis and rotate it 90
degrees around the Z axis.
    calc <1, 0, 0> * {0, 0, 90}
    <1, 0, 0> * {0, 0, 90} = <0, 1, 0>
resulting in a unit vector along the Y axis.  Now we'll rotate it 90
degrees around the X axis:
    calc $ * {90, 0, 0}
    <0, 1, 0> * {90, 0, 0} = <0, 0, 1>
which makes it point along the Z axis.   Finally, rotate it back to
align with the Y axis:
    calc $ / {90, 0, 0}
    <0, 0, 1> / {90, 0, 0} = <0, 1, 0>

To obtain the angle between two rotations, use:
    calc anglebetween {0, 0, 90} {90, 0, 0}
    anglebetween(<0, 0, 90>, <90, 0, 0>) = 120
or, if you speak radians:
    calc set angles radians
    calc anglebetween {0, 0, PI_BY_TWO} {PI_BY_TWO, 0, 0}
    anglebetween(<0, 0, 1.5708>, <1.5708, 0, 0>) = 2.094395
which you can convert to degrees with:
    calc $ * RAD_TO_DEG
    2.094395 * 57.29578 = 120

Functions

We've discussed some functions involving vectors and rotations above.
The following mathematical functions are available.
    sin ang         Sine of angle
    cos ang         Cosine of angle
    tan ang         Tangent of angle
    asin f          Arc (inverse) sine of number
    acos f          Arc (inverse) cosine of number
    atan2 fy fx     Arctangent of quotient of fy / fx
    sqrt f          Square root of number
The sin, cos, and tan functions expect their argument in degrees, or
radians if “set angles radians” is in effect.  The asin, acos, and
atan2 functions similarly return angles in degrees or radians according
to this setting.

Functions involving vectors are:
    norm vec        Normalised vector (magnitude 1)
    mag vec         Magnitude of vector
    dist vec1 vec2  Distance between two points represented as vectors

A function involving rotations is:
    anglebetween rot1 rot2  Angle between two rotations

Rotations and transformations of vectors can be confusing until you
develop an intuition for how they work.  Excellent resources for
understanding rotations are the following Web pages:
    http://wiki.secondlife.com/wiki/Rotation
    http://wiki.secondlife.com/wiki/User:Timmy_Foxclaw/About_Coordinate_Systems_and_Rotations
Fourmilab's free Orientation Cube provides an interactive workshop for
mastering rotations and Linden Scripting Language's facilities for
applying them to objects in Second Life:
    https://marketplace.secondlife.com/p/Fourmilab-Orientation-Cube/19823081
    https://www.youtube.com/watch?v=NdD9MpFfEBg

Constants

The following symbolic constants are recognised.  Constants
representing numbers may be used within vector and rotation
specifications:
    DEG_TO_RAD      π / 180
    PI_BY_TWO       π / 2
    TWO_PI          π * 2
    PI              π
    RAD_TO_DEG      180 / π
    SQRT2           ≈1.414214
In addition, vector and rotation constants are defined:
    ZERO_VECTOR     <0, 0, 0>
    ZERO_ROTATION   <0, 0, 0, 1> = {0, 0, 0}
Constants are case-insensitive but may not be abbreviated.

Positions and Rotations of Objects

When the Calculator is installed in the inventory of an object in
Second Life, you can reference the position and rotation of components
(links) within the object (link set) with the following functions, each
of which takes a link number as its argument.  These functions can be
used wherever a constant of that type may appear in an expression. To
obtain a list of link numbers, object names, positions, and rotations
(in region co-ordinates for the root prim of the link set, relative to
the root prim for child links) use:
    Status
which will produce output in local chat like:
    1*  Mechanism  <104.4387, 151.9681, 1200.542> {0, 90, 0}
    2.  Frame +X  <-0.50232, 0, 0.60727> {0, -90, 0}
    3.  Frame -X  <-0.50232, 0, -0.59274> {0, -90, 0}
    4.  Z Ring  <-0.99231, 0, 0.00726> {0, 0, 90}
    5.  Z Pivot B  <-1.34461, 0, 0.00726> {0, -90, 0}
    6.  Z Pivot A  <-0.64002, 0, 0.00726> {0, -90, 0}
The root prim of the link set is distinguished by an asterisk after its
link number (which will always be 1).  You could then, for example,
query the position and rotation of link 4 (named “Z Ring” in this
model—it's a good idea to give every component of your model a unique
name: if they're all named “Object” you'll have difficulty telling them
apart even with a scorecard):
    calc pos(4)
    <-0.99231, 0, 0.00726>
    calc rot(4)
    {0, 0, 90}  <0, 0, 0.70711, 0.70711>
To compute the distance of the centre of Z Ring from the root prim,
use:
    calc mag pos(4)
    mag(<-0.99231, 0, 0.00726>) = 0.992337
and to compute the orientation of that component rotated 30 degrees
around the X axis:
    calc rot(4) * {30, 0, 0}
    {0, 0, 90} * {30, 0, 0} = {30, 0, 90}
You can obtain the global (or region co-ordinates) position and
rotation of a component with the gpos() and grot() functions.  Here we
query the region co-ordinate position of link 4:
    calc gpos(4)
    <104.446, 151.9681, 1201.534>
We can compute its position relative to the root prim (1) of the link
set and verify that this is the same as given by pos(4) as follows:
    calc gpos(4) - gpos(1)
    <104.446, 151.9681, 1201.534> - <104.4387, 151.9681, 1200.542> = <0.00726, 0, 0.99231>
This value is in region co-ordinates, which we can transform into local
co-ordinates by applying the global rotation of the root prim:
    calc $ / grot(1)
    <0.00726, 0, 0.99231> / {0, 90, 0} = <-0.99231, 0, 0.00726>
which is indeed the local position of link 4:
    calc $ - pos(4)
    <-0.99231, 0, 0.00726> - <-0.99231, 0, 0.00726> = <0, 0, 0>

Setting Positions and Rotations

You can set the position and rotation of links within the object in
which the Calculator script is installed with the “set pos” and “set
rot” commands.  In the previous section, we calculated the result of
rotating link 4 (“X Ring”) by 30 degrees around the Y axis.  Let's now
actually do it.
    calc rot(4) * {30, 0, 0}
    {0, 0, 90} * {30, 0, 0} = {30, 0, 90}
    set rot 4 $
Did it rotate as we wished?
    calc rot(4)
    {30, 0, 90}  <0.18301, -0.18301, 0.68301, 0.68301>
Yes, it did!

Now let's move (translate) link 4 by 0.1 metres along its local Y axis.
Note that since we've just rotated it by 30 degrees, this axis will be
shifted with respect to the Y axis of the link set.
    calc pos(4) + <0, 0.1, 0>
    <-0.99231, 0, 0.00726> + <0, 0.1, 0> = <-0.99231, 0.1, 0.00726>
    set pos 4 $
Eppur si muove!  The effect of “set pos” and “set rot” commands may be
reversed (up to the ten most recent commands) by “undo”.
    undo
Moves back to previous position.
    undo
Rotates back to original position.

Monitoring Link Messages

If you're using multiple scripts within your object which communicate
via link messages [sent via llMessageLinked() and received with the
link_message() event handler], you can use the Calculator to monitor
traffic among your scripts for debugging via the “Set link” commands.
Link messages contain an integer number, a string, and a key parameter
which are sent from one script to others.  Messages are normally
identified by the number parameter, and “Set link” allows you to filter
accordingly.
    Set link num
        Monitors messages with the specified numeric parameter num.
    Set link from to
        Monitors messages with numeric parameters in the inclusive
        range between from and to.
    Set link off
        Cancels all monitoring of link messages.
    Set link
        Shows the range of link message numbers being monitored.
For each link message in the selected range, the link number of the
sender and the numeric, string, and key parameters are displayed in
local chat.

Using the Calculator from Other Scripts

While you can simply “drop” the Calculator script into the inventory
of an object you're debugging and begin to use it immediately via
chat commands on its channel, for some applications you may wish to
integrate it more closely with other scripts, for example, to allow
calculator commands to be submitted programmatically from scripting
facilities in your build.  The Calculator listens for link messages
with the following numeric codes, which may be submitted by other
scripts in the object in which it is installed:
    LM_CA_INIT      210
        Initialise the Calculator.
    LM_CA_RESET     211
        Reset the Calculator script, clearing all mode settings
        and saved information.
    LM_CA_STAT      212
        Show Calculator status on local chat.  The output is the
        same as that from the calculator's “Status” command.
    LM_CA_COMMAND   213
        Execute the string parameter of the link message as a
        Calculator command in the same syntax used for commands
        from local chat.
In addition, whenever the Calculator computes and displays a result to
the user, it sends a:
    LM_CA_RESULT    214
link message, whose string parameter is a Json-encoded list whose first
argument is a string indicating the result type:
    "f"     Floating-point number
    "v"     Vector
    "r"     Rotation (quaternion)
Other scripts can listen for this message to, for example, provide
access to the most-recently-calculated result in the same way the “$”
pseudo-variable does in the Calculator.  To simplify command parsing by
other scripts which use the “Calc” command to send commands to the
Calculator, any of the calculator's other commands may be prefixed with
“Calc”, for example “Calc set angles radians”.

Reference

  Commands
            Commands and their arguments may be abbreviated to two
            characters and are case-insensitive.

    Access owner/group/public
        Controls who may use the calculator.  Default is owner only.

    Boot
        Resets the Calculator.  The geometry of the object is reloaded
        and the last result and undo memory are cleared.  The channel
        on which the calculator listens for commands is reset to 1805.

    Calc expr
        Perform a calculation.

    Channel n
        Listen for chat commands on channel n, default 1805.

    Clear
        White space is sent to local chat.

    Help
        This document is given to the requester.

    Set
        Sets various items.

            Set angles degrees/radians
                Sets whether angles are input and displayed in degrees
                (the default) or radians.

            Set link from to
                Set range of num parameters to monitor.
            Set link from
                Monitor a single num parameter.
            Set link off
                Disable link message monitoring.
            Set link
                Show link message parameter range being monitored.

            Set position linkno vector
                Sets the local position of link linkno to vector.  The
                position is relative to the root prim of the link set
                unless linkno is 1 (the root prim itself), in which
                case the position is in region co-ordinates.

            Set rotation linkno rotation
                Sets the local rotation of link linkno to rotation. The
                rotation is relative to the root prim of the link set
                unless linkno is 1 (the root prim itself), in which
                case the rotation is in region co-ordinates.

    Status
        Show the link numbers, names, position, and rotation of all
        components of the link set, as well as Calculator setting, in
        local chat.

    Undo
        Undo the most recent “Set position” or “Set rotation” command.
        The ten most recent commands may be undone.

  Scalar operators
    f1 + f2                         Sum of numbers
    f1 - f2                         Difference of numbers
    f1 * f2                         Product of numbers
    f1 / f2                         Quotient of numbers
    i1 % i2                         Modulus of i1 by i2 (fractions truncated)

  Vector operators
    <x1, y1, z1> + <x2, y2, z2>     Component-wise sum of vectors
    <x1, y1, z1> - <x2, y2, z2>     Component-wise difference of vectors
    <x1, y1, z1> * <x2, y2, z2>     Dot product of vectors
    <x1, y1, z1> % <x2, y2, z2>     Cross product of vectors
    <x1, y1, z1> * f                Scale vector multiply
    f * <x1, y1, z1>                Scale vector multiply
    <x1, y1, z1> / f                Scale vector divide

  Rotation operators
    {x1, y1, z1} * {x2, y2, z2}     Compose rotation
    {x1, y2, z1} / {x2, y2, z2}     Compose inverse rotation
    <x1, y1, z1> * {x2, y2, z2}     Rotate vector by rotation
    <x1, y1, z1> / {x2, y2, z2}     Rotate vector by inverse rotation

  Constants
    DEG_TO_RAD      π / 180
    PI_BY_TWO       π / 2
    TWO_PI          π * 2
    PI              π
    RAD_TO_DEG      180 / π
    SQRT2           ≈1.414214
    ZERO_VECTOR     <0, 0, 0>
    ZERO_ROTATION   <0, 0, 0, 1> = {0, 0, 0}

  Trigonometric functions (respect angle degree/radian settings)
    sin ang         Sine of angle
    cos ang         Cosine of angle
    tan ang         Tangent of angle
    asin f          Arc (inverse) sine of number
    acos f          Arc (inverse) cosine of number
    atan2 fy fx     Arctangent of quotient of fy / fx

  Mathematical function
    sqrt f          Square root of number

  Vector functions
    sin ang         Sine of angle
    cos ang         Cosine of angle
    tan ang         Tangent of angle
    asin f          Arc (inverse) sine of number
    acos f          Arc (inverse) cosine of number
    atan2 fy fx     Arctangent of quotient of fy / fx
    sqrt f          Square root of number

  Rotation function
    anglebetween rot1 rot2  Angle between two rotations

  Link Messages
      LM_CA_INIT    210   Initialise the calculator.
      LM_CA_RESET   211   Reset the calculator script; restore all
                          original settings.
      LM_CA_STAT    212   Show calculator status on local chat.
      LM_CA_COMMAND 213   Send command to calculator: string parameter
                          is the command to be executed.
      LM_CA_RESULT  214   Return result from calculator.  The string
                          parameter is a JSON-encoded list where the
                          first item is the type ("f": float, "v":
                          vector, "r": rotation) and the second is the
                          value as a string.  This is sent to other
                          scripts in the same prim as the calculator
                          every time the calculator displays the
                          result of a calculation.
