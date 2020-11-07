
                        Fourmilab Mechanisms

                                User Guide

Objects in the real world are often composed of multiple components
organised in a hierarchy.  Consider, for example, a door on an
automobile.  The door is a component of the automobile and moves with
it.  We'll call the automobile the “parent object” and the door one of
its “child objects”.  The door is able to move relative to its parent
object, as when you open the door, and this motion is independent of
the motion of its parent, the car (although it may be unwise to open
the door while the car is moving).

The door, in turn, is the parent object of components which make it up:
the door handle, window, window crank, etc., and these components move
with the door but are also able to move independently of it: the window
crank turning around and the window going up and down, for example.  It
is natural to organise these parts into a hierarchy, which we'll
illustrate here by indentation:

    Automobile
        Left front door
            Left front door handle
            Left front Window
            Left front Window crank
        Right front door
            ...

Hierarchical organisation makes it easy to manage the motion of complex
objects with multiple components.  When you move an object, all of its
children (and their children) move with it, but its motion does not
affect its parent or other children of the parent (opening the left
front door does not move the automobile or affect the right front door,
but it does move the window and window crank of the left front door:
its children).

Many modeling systems allow building models in a hierarchical fashion
but Second Life is not among them.  Only one level of hierarchy is
supported: objects linked together into a “link set”.  When you link
multiple objects together into a link set, they all move and rotate
together with respect to the global (region) co-ordinate system, but it
isn't possible to include a link set as a component within another link
set.  Instead, all objects in a link set are independent and move
within the link set unrelated to other objects.  If you wish to build
an object with hierarchical components as a Second Life link set, you
have to do all of the housekeeping to maintain the relationships among
them yourself, which leads to large amounts of confusing and
error-prone code, difficult to debug and a nightmare to maintain when
changes are required.

Fourmilab Mechanisms is a Second Life script package written in Linden
Scripting Language which emulates mechanisms with hierarchical
structure.  Mechanisms are built as conventional Second Life link sets,
then the relationships among their components are declared in a
notecard placed in the root prim of the link set.  The Mechanisms
script reads this notecard, constructs a model of the mechanism and its
components, and then allows user scripts to manipulate the mechanism
through straightforward Application Programming Interface (API) calls
from user scripts.

A variety of example mechanisms are included with the product.  Each of
these includes the Fourmilab Mechanisms scripts in an object that
demonstrates their capabilities.  All of these are ready-to-run: just
rez onto your land (or a public sandbox) and follow the instructions
below to run the demonstration.  A YouTube video showing each of these
example mechanisms in action may be viewed at:
    https://www.youtube.com/watch?v=r_mx9vmJli4

If you're more interested in the programming details and wish to skip
discussion of the examples, skip ahead to “The Fourmilab Mechanisms
Application Programming Interface (API)” below.

Example: Nested Gimbals
=================

Fourmilab Mechanisms is supplied with an example object called
“Gimbals” which illustrates its operation.  Rez a copy of the object
from your inventory.  The “Gimbals” object consists of three nested
circular rings, with the outermost mounted in a wooden frame and each
inner ring pivoted so it can move in an axis orthogonal (at a right
angle) to that of its parent.  Each object is named, and their
hierarchy can be written as follows:

    Gimbals
    Frame +X
    Frame -X
    X Ring
        X Pivot A
        X Pivot B
        Y Ring
            Y Pivot A
            Y Pivot B
            Z Ring
                Z Pivot A
                Z Pivot B

The leftmost four objects have no parents: “Gimbals”, “Frame +X”, and
“Frame -X” are the static frame, with “Gimbals” the root prim
containing all of the scripts.  The outermost ring is “X Ring”
(red/cyan), with inner rings “Y ring” (green/magenta) and “Z ring”
(blue/yellow).  Each ring has two pivots on the axis in which it moves,
coloured according to the faces of the ring.

Rotating the X Ring rotates the Y and Z Rings along with it; rotating
the Y ring rotates the Z ring with it, and rotating any ring rotates
its pivots with it.  This hierarchy is declared in the “Mechanism
Configuration” notecard in the root prim as follows:

    Set parent "X Ring"   "X Pivot A" "X Pivot B" "Y Ring"
        Set parent "Y Ring"   "Y Pivot A" "Y Pivot B" "Z Ring"
            Set parent "Z Ring"   "Z Pivot A" "Z Pivot B"

Components which have no parents or children, such as the frame, need
not be declared.  The “Set parent” statements are checked to verify
that no component depends on more than one other component and that
there are no loops in the dependency relationships (for example, A
having a child B, which has A as a child).

(The designation of the rings as “X”, “Y”, and “Z” is arbitrary: they
are named for the region axes with which their pivots align when the
object is initially rezzed.  These axes will change orientation as the
rings rotate with respect to one another.)

Clicking anywhere on the mechanism will run a scripted demonstration
which illustrates how components move in the hierarchical manner
declared.

Rotations

Now let's try rotating the rings and see how they behave.  The “RX”,
“RY”, and “RZ” commands perform relative rotations of the respecting
rings, moving child components with them.  (These commands are part of
the Gimbal model, not the basic Fourmilab Mechanisms facility: they are
examples of how you can manipulate components of your own model.)
These commands are entered in local chat, preceded by the chat command
channel, which by default is /1872 (the birth year of Heath Robinson).
I omit the “/1872” prefix in the commands below in the interest of
concision,  Start with:

    RX 30
        This rotates the outermost X Ring 30 degrees from its original
        orientation in the axis defined by its pivots.  Note how the
        pivots rotate with the ring (the red and cyan parts stay
        aligned with the like-coloured ring faces), and the inner rings
        and their pivots move rigidly with the X Ring.

    RX -30
        Rotates the X Ring and child components back to their original
        orientation.

    RY 30
        The intermediate Y Ring (green/magenta) rotates 30 degrees,
        with its pivots and the inner Z Ring and pivots moving with it.
        Its parent, the X Ring, in unaffected by its motion.

    RZ 30
        The innermost Z Ring (blue/yellow) and its pivots rotate with
        respect to the Y Ring, leaving the X Ring and Y ring
        unaffected.

    RX -45
        Rotates the X Ring and all its children (the rotated Y and Z
        rings) by -45 degrees.

Try experimenting with a variety of RX, RY, and RZ commands to see how
they operate on the components of the mechanism.  You can always get
back to the original position of the mechanism with the command:

    Panic
        Restore model to original orientation.

Translations (Moves)

Translations (moves) of components work similarly to orientations.
Let's start by rotating the Y and Z rings:

    RY 45
        Rotates Y and Z rings 45 degrees.

    Trans Z <0.25, 0, 0>
        Moves the innermost Z Ring 0.25 metres in the X direction
        relative to its parent, the Y Ring.  Note that since the Y Ring
        has been rotated, its X axis is rotated with respect to the
        region co-ordinate system and its parent, the X ring.

    RX 20
        Rotate the outer X Ring 20 degrees.  The Z ring, which we moved
        in the last step, moves with the rest of the components.

    Trans Z <-0.25, 0, 0>
        The Z Ring moves back into attachment to the Y ring.  Since the
        move is within the co-ordinate system of the parent Y Ring, the
        rotation of that ring when we rotated its parent does not
        affect the move of the Z Ring.

    Status extended
        Displays the link numbers, names, positions, and rotations of
        all components and, for components which have dependent
        children, all of the ultimate dependencies (including children
        of children) for each component.  Rotations are shown both
        relative to the link set (root prim) and, for child components,
        to their parent.  Rotations are displayed in “Euler angle” form
        in degrees (recall than in Second Life Euler angles, the
        rotation order is Z, Y, X.

    Panic
        Restore the model to its initial state.

Spins (Omega Rotation)

Second Life provides a rudimentary facility to allow objects to rotate
(more or less) smoothly without the need for a script to repeatedly
move them.  In some cases, this rotation may be performed entirely by
the viewer on the client side, reducing the network traffic between the
server and the viewer and providing smoother motion.  Unfortunately,
there are no options other than rotating an entire link set as a unit
or links within the set individually: it is not possible to have a
subassembly within a link set rotate as a unit.

Fourmilab Mechanisms provides an automatic rotation mechanism which
fully supports hierarchical assemblies of components.  Due to
limitations of Second Life, the animation must be done on the server,
which means it may experience jerkiness and lag when the server is
heavily loaded or the network is congested, but in many cases,
especially for simple mechanisms, it works well and, since there's no
alternative, is better than nothing.  Let's crank in three levels of
automatic rotation in our model, starting from the initial state which
we reset with the Panic command above, working from the outside in.
Start by rotating the outermost X ring about the axis of its pivots.

    Spin X <0, 0, 1> 1 1
        Starts the X ring spinning around its local Z axis (since it
        has no parent, this is the Z axis of the root prim of the link
        set).  The last two numbers specify the spin rate in radians
        per second and a gain which is multiplied by this to determine
        the actual spin rate.  The selected spin rate of one radian per
        second is around 9.6 revolutions per minute.  A spin rate of 0
        stops the spin.

    Spin Y <0, 1, 0> 0.5 1
        Starts the Y Ring spinning around the Y axis of its parent (the
        X Ring) at 0.5 radians per second (half the angular speed of
        the X Ring).  The inner Z ring moves rigidly with the Y ring.

    Spin Z <0, 1, 0> 0.25 1
        Finally, starts the Z ring spinning around the Y axis of its
        parent (the Y ring) at half the angular speed of the Y ring.
        At this point, depending upon the performance of the region in
        which you're running the simulation and your network
        connection, movement may become a bit jerky.  But consider that
        there's a lot going on here: for every animation step, a total
        of 18 objects within the link set must be updated in position
        and rotation and their new orientation displayed by the viewer.

    Spin Y <0, 1, 0> 0 0
        The intermediate Y ring stops spinning and is frozen in its
        orientation with respect to its parent, the outer X ring, which
        continues to spin, along with the inner Z ring.

    Spin X <0, 1, 0> 0 0
        The X ring ceases to spin, leaving the Z ring still spinning.

    Spin Z <0, 1, 0> 0 0
        The Z ring stops spinning.

    Panic
        The model is restored to initial conditions.

Example: Swinging Door
================

The Swinging Door model is a realistic model of an object that takes
advantage of the hierarchical structure provided by Fourmilab
Mechanisms.  The model is a door, located on a rotating turntable,
which has a handle that, when rotated, opens the door to swing open or
closed.  To get started, rez the model from your inventory.  You'll see
the door standing on its turntable.  Click anywhere on the door to run
a scripted demonstration of the door opening and closing in various
orientations.  The hierarchical structure of the model is given in the
Mechanism Configuration notecard as follows:
    Set parent "Turntable" "Door 1"
        Set parent "Door 1" "Frame L" "Frame R" "Hinge top"
            Set parent "Hinge top" "Hinge middle" "Hinge bottom" "Panel"
                Set parent "Panel" "Door handle shaft"
                    Set parent "Door handle shaft" "Door handle inside" "Door handle outside"
This is a structure with five levels of hierarchy and 11 moving parts.
Moving any object moves its child objects with it.  To illustrate this,
rotate the Turntable 45 degrees around the global Z axis.  The link
number of the Turntable is 5, which you can confirm with the:
    Status
command.  Rotate it with:
    RL Turntable <0, 0, 1> 45
and see how the turntable, door, and all of its components rotate
together.  Now open and close the door with the commands:
    Door open
    Door close
Everything works perfectly: Fourmilab Mechanisms takes care of all of
the messy bookkeeping.

Now let's make things even more complicated.  Start the turntable
spinning around its Z axis with:
    Spin Turntable <0, 0, 1> 0.5 1
While the turntable is spinning the door, open and close it again.  It
still works.
    Door open
    Door close
Ain't math grand?  Put everything back to the starting point with:
    Panic

Now, let's do a real Twilight Zone door with:
    Spin Turntable <0, 0.1, 1> 0.25 1
    Spin Door <0.25, 0.1, 0.3> 0.33 1
    Door open
    Door close
It still opens and closes as you'd expect regardless of its
orientation.

Put everything back to normal with:
    Panic

Examples: Marble Machines
===================

Two “Marble Machines” are included to demonstrate multi-axis mechanisms
and the interaction of physical objects with non-physical models. Each
machine consists of a tilting platform upon which a number of coloured
spherical “marbles” can roll.  The marbles are physical objects which
respond to gravity, have momentum, and can collide with one another and
parts of the mechanism.

The first machine is named “Marble Madness”, in homage to the classic
Atari arcade video game.  It has a tilt table consisting of two
intersecting channels in the form of an “X”, initially populated with
two differently coloured marbles.  You can start the table tilting by
touching the mechanism or entering the command “/1984 Tilt” (the chat
command channel to which the object responds, 1984, is the year Atari
introduced “Marble Madness”).  Every five seconds, the table will tilt
and rotate to a new, randomly-chosen, orientation and the marbles,
under the influence of gravity and friction, will move, collide with
one another, bounce off the mechanism, and sort themselves into the
arms of the machine.  To stop the tilting and restore everything to the
initial position, touch the machine again or enter another Tilt
command.

You can add more marbles to the mechanism with the command (preceded,
as always, by a slash and the channel number):
    Populate n
where n is the number of marbles to add.  These marbles may initially
overlap existing marbles, but as soon as the table starts to tilt,
they'll sort themselves out.  Marbles should be added only when the
machine is not running.  If you try to add more than 20 marbles in one
Populate command, they'll “fall off” the edges of the machine.  If you
wish to add more marbles, use multiple commands.  These marbles behave
like physical objects: if you clog up the machinery with too many, you
may “lose your marbles” and have some fall out onto the ground.  You
can restore things with the command:
    Panic
To delete all existing marbles and start over, enter:
    Population extinction

The second machine is named, imaginatively, “Tilt Table”, and responds
to chat channel /1931 (the year in which the first coin-operated
pinball machine was introduced by David Gottlieb).  As with Marble
Madness, rez it and start the demonstration either by touching the
machine or entering the “Tilt” command.  This machine has a square
table with six randomly-positioned “bumpers” which, when hit by a ball,
briefly flash red and kick the ball back in its direction of travel.
The bumpers are child components of the table floor and move with it as
it tilts and rotates: all of this is handled automatically by Fourmilab
Mechanisms.  Tilt Table responds to the Tilt, Populate, and Panic
commands in the same way as Marble Madness.  The Tilt Table is
particularly interesting when you populate with more marbles: say, 16
to 25.

The marble machines are provided as examples of how mechanisms can
interact with physical objects.  (The following discussion veers into
details of Second Life objects and scripting which many builders may
never encounter and is prone to make one's eyes glaze over.  Read on
only if you're an advanced developer interested in building similar
objects and using the scripts for these examples as a “code mine” for
your own projects.  Otherwise, skip ahead to discussion of the Blobby
Man example.)

BEGIN GNARLY DISCUSSION FOR ADVANCED DEVELOPERS.

Objects in Second Life are of three principal types, set by the Linden
Scripting Language llSetStatus() API call or equivalent: normal,
physical, or phantom.  A phantom object is visible in the world but has
no physical presence: avatars and other objects can pass through it as
if it wasn't there.  Phantom objects are often used for scenery or
other applications where they need not interact with other objects in
the world.  A normal object (the default when you create a new object:
one which is neither phantom nor physical) is solid: other objects can
bounce off it, but it does not respond to gravity and doesn't react
when another object collides with it.  It may be thought of as the
“immovable object” of legend. Normal objects are used for building most
largely stationary structures in Second Life, such as buildings,
furniture, and landscaping.  Such objects are typically moved only
explicitly by a user with the Edit facility and do not move on their
own.  Physical objects respond to gravity and wind, have inertia, exert
force when they collide with other physical objects, and interact with
one another regardless of whether they are stationary or in motion.  In
the Marble Machines, all of the components of the machines are normal
(non-physical) objects, while the marbles (which are independent
objects, not part of the machine, and not managed by Fourmilab
Mechanisms) are physical objects.

Combining normal and physical objects can produce interesting and
satisfying simulations, of which these Marble Machines provide only a
simple taste, but getting everything to work can be challenging and a
programming chore.  The reason is this fundamental fact (which I'd
write in bold and italics, if Second Life notecards permitted me to):
*physical objects don't expect normal objects to move*.  Consider the
marbles on the tilt table.  When the table shifts position, the marbles
(physical objects) do not detect this and are not affected by the
motion of the table's surface on which they are supposed to be resting.
If the table should happen to move upward with respect to a marble and
leave it now below the table, it will just fall to the ground as if the
table were made of smoke (or was a phantom object) as it moved.  This
means that many clever ideas for machines interacting with physical
objects quickly run afoul of this detail of Second Life's physics
engine.

You might be tempted to just make your entire mechanism physical, but
in most cases this is a cure worse than the disease.  The problem is
that a link set (object composed of multiple primitive objects) must be
entirely physical or normal: you can't set this status
component-by-component.  As a result, making a mechanism with moving
parts physical means that motion of one part, as Professor Newton
observed some years ago, causes an “equal and opposite reaction” upon
the others, which usually results in a mechanism that jumps around
wildly, as there's no means to anchor it to the ground or floor.  Also,
a physical object cannot have a “physics cost” greater than 32, which
limits the complexity of mechanisms you can build.

The Marble Machines work around these limitations via a communication
channel between the mechanism and the marbles rolling around within its
confines.  Every time the table is about to move, the mechanism's main
script broadcasts a TILTING message on a private region channel,
informing the marbles of the table's old and new rotations.  The
marbles, upon receiving this message, disable their own physics (so
they don't fall to the ground), then adjust their positions with
respect to the mechanism to compensate for the motion of the table.
When the table's motion is complete, it sends a TILTED message which
informs the marbles it's done moving, at which point they re-enable
physics and allow gravity and inertia to come into play once again.
You can think of this as if the table surface incorporated an
electromagnet which freezes the marbles into place while it is moving,
then releases them when done.  This is messy (and note that it has
nothing at all to do with Fourmilab Mechanisms, which is involved only
in managing the motion of the table and its components), but it gets
the job done and may be suitable should similar challenges arise in
machines you develop where physical objects need to interact with
moving parts which are normal objects.

END GNARLY DISCUSSION FOR ADVANCED DEVELOPERS.


Example: Blobby Man
==============

The Blobby Man is a humanoid mannequin largely compatible with the
structure of Second Life avatars, but built entirely from basic prims
(in fact, only spheres, scaled in various ways), and articulated with
Fourmilab Mechanisms.  It has seven levels of hierarchy and 43 moving
parts.  Please see the separate “Fourmilab Blobby Man User Guide”
included with this product (or available by typing “/1721 Help” in
local chat when the Blobby Man has been rezzed) for complete details.

The Fourmilab Mechanisms Application Programming Interface (API)
=============================================

To integrate Fourmilab Mechanisms into your model, add the Mechanisms
and Mechanisms Auxiliary scripts to the root prim of the link set, then
copy the Linden Scripting Language (LSL) code from the supplied script
file “Mechanisms API” into your main script, somewhere before you
define its states and event handlers.  Most of the complexity is
handled in the Mechanisms scripts, with the API invoking them using
link messages.  This isolates the Mechanisms scripts from your code and
reduces its memory impact on your script to a minimum.  You interact
with the API using the following function calls.

    flMechInit(key owner)
        Initialise the Fourmilab Mechanisms scripts.  The mechanism
        configuration is read from the “"Mechanism Configuration”
        notecard (if any) in the root prim of the link set.  Any error
        messages from this and subsequent API calls are sent to the
        user with key owner, which is usually specified as
        llGetOwner(). This is normally called in the state_entry()
        event of your script.

    flMechStatus(integer which, key towhom)
        Send the mechanism configuration to user towhom in local chat.
        If which is TRUE, an extended status is shown, including
        position and rotation of all components.

    flMechPanic(integer save)
        If save is FALSE, restore all components to their initial
        position and rotation as given by “Set restore” commands in the
        configuration file.  If save is TRUE, print commands in local
        chat suitable for specifying the configuration in the file.

    vector flGetCompPos(integer linkno)
        Return the position of the component with link number linkno in
        the co-ordinate system of its parent component.  If the link
        has no parent, its co-ordinates in the link set are returned.

    rotation flGetCompRot(integer linkno)
        Return the rotation of the component with link number linkno in
        the co-ordinate system of its parent component.  If the link
        has no parent, its rotation relative to the root prim of the
        link set is returned.

    integer flSetCompPos(integer linkno, vector newpos)
        Set the position of component linkno to position newpos
        relative to the co-ordinate system of its parent or, if it has
        no parent, the root prim of the link set.  All child components
        dependent upon this component are moved with it.  A “handle”
        is returned for the in-progress motion, which will identify it
        when the LM_ME_COMPLETE message (see below) is returned upon
        its completion.

    integer flSetCompRot(integer linkno, rotation newrot)
        Set the rotation of component linkno to rotation newrot
        relative to the co-ordinate system of its parent or, if it has
        no parent, the root prim of the link set.  All child components
        dependent upon this component are moved with it.  A “handle” is
        returned for the in-progress rotation, which will identify it
        when the LM_ME_COMPLETE message (see below) is returned upon
        its completion.

    integer flSetCompOmega(integer linkno, vector axis,
            float spinrate, float gain, float limit)
        Spin component linkno around the specified axis, relative to
        the component's parent or, if it has no parent, the root prim
        of the link set.  The spin rate is the product of spinrate and
        gain, in radians per second.  If the spin rate is zero, any
        existing spin is cancelled.  You may have any number of
        components spinning at the same time, but each component may
        have only a single spin active at once.  There is no problem
        having components and their children spinning simultaneously.
        If you set limit to a positive nonzero value, the rotation will
        automatically stop after limit radians; if limit is zero or
        negative, rotation will continue until cancelled or changed by
        a subsequent flSetCompOmega() call.  When rotation is stopped
        by reaching the limit, an LM_ME_OMEGALIMIT message is sent to
        the client to inform it of the completion of the rotation with
        the component's link number in the string field of the link
        message.  A “handle” is returned for the in-progress spin,
        which identifies it when the LM_ME_OMEGALIMIT message (see
        below) is returned upon its completion and in LM_ME_COMPLETE
        (see below) messages sent for each incremental step in the
        rotation.

    list flGetCompOmega(integer linkno)
        Return a list containing the [ axis, spinrate, gain, handle ]
        of the current spin of component linkno.  If no spin is active
        for that component, the null list is returned.

    integer flSetCompMotion(integer linkno, vector direction,
            float speed, float distance)
        Smoothly move component linkno in the direction specified by
        the vector for the specified distance in metres at the given
        speed in metres per second.  When the specified distance is
        reached, an LM_ME_MOVELIMIT message is sent to the client
        informing it of the completion of the operation with the
        component's link number in the string field.  Specifying a
        speed of zero cancels any motion in progress for the component.
        A “handle” is returned for the in-progress motion, which will
        identify it when the LM_ME_MOVELIMIT message (see below) is
        returned upon its completion and in LM_ME_COMPLETE (see below)
        messages sent for each incremental step in the motion.

    list flGetCompMotion(integer linkno)
        Return a list containing the [ direction, speed, distance,
        handle ] of the current motion of linkno.  If no motion is
        active, the null list is returned.

    string flGetCompName(integer linkno)
        Return the name of the component linkno.  This is the name of
        the object from the link set.

    integer flGetCompLink(string compname)
        Return the link number for the component with compname.  The
        component name must be specified exactly as in its object
        within the link set, and the component name must be unique.  If
        no component with that name is found, -1 is returned.

    integer flGetCompParent(integer linkno)
        Return the link number of the parent of component linkno, or -1
        if the component has no parent or the linkno is invalid.

    list flGetCompChildren(integer linkno)
        Return a list of the link numbers of components which are
        children of component linkno (including children of children,
        etc.).  If the component has no children or the linkno is
        invalid, the null list is returned.

When including the API definitions in your script, if you don't need
some of the functions, feel free to delete their code or comment them
out to save script memory.  If your build contains multiple scripts
which manipulate the mechanism, each should include the API functions
its code requires.

Link Messages
==========

Many of the operations performed by Fourmilab Mechanisms are
asynchronous: after a request is made by your script, for example to
rotate a component, the actual rotation of the mechanism component and
its child components is handled by the separate Mechanism scripts while
your script is free to continue its own processing.  This allows your
script to remain responsive to the user and external events while the
mechanism is being updated, but requires care so you don't accidentally
access the mechanism while it is in the process of being updated.

Updating is usually sufficiently fast so that if you're updating in
response to user commands you don't need to worry about conflicts, but
ignoring potential timing problems is sloppy and can lead to confusing
problems which are difficult to reproduce, so it's always wise to be
careful and confirm completion of the last operation before commencing
the next.

The following link messages are of interest to clients using Fourmilab
Mechanisms.  Each is identified by the “num” argument in the
link_message() event and passes its data in the “str” argument.

    LM_ME_CONFIG (127)
        This message is sent when the Mechanisms script has completed
        loading and processing the “Mechanism Configuration” notecard
        in the root prim of the link set.  Upon receiving this message,
        you must call:
            flMechConfig(str);
        to initialise the client-side interface to Fourmilab
        Mechanisms. You may also want to disable operations which query
        and manipulate the mechanisms until this message is received,
        as they won't work until initialisation is complete.  If your
        build has two or more scripts which manipulate the mechanism
        with Fourmilab Mechanisms API calls, each must independently
        process the LM_ME_CONFIG message and call flMechConfig() to
        obtain its own local copy of the mechanism structure.

    LM_ME_COMPLETE (131)
        This message is sent when the updating of the mechanism after a
        call which moves a component is complete.  When you move or
        rotate a component with flSetCompRot() or flSetCompPos(), the
        Mechanisms script updates that and any child components
        asynchronously to the execution of your script.  When all
        components have been updated, an LM_ME_COMPLETE message is sent
        with the string argument providing a comma-separated list
        containing the numeric operation code for the just-completed
        function (123 [LM_ME_TRANSLATE] for flSetCompPos, 124
        [LM_ME_ROTATE] for flSetCompRot) and the integer “handle”
        returned by the function when the operation was submitted.
        Once you have received the LM_ME_COMPLETE message, your script
        is free to inquire the configuration of the mechanism with
        flGetCompPos() or flGetCompRot() or submit another movement
        command.

        While a smooth rotation [flSetCompOmega()] or move
        [flSetCompMotion()] operation is in progress, each incremental
        adjustment to the mechanisms is announced by an LM_ME_COMPLETE
        message containing a function code of LM_ME_ROTSTEP (for
        rotation) or LM_ME_TRANSTEP (for move), the handle returned by
        the original smooth rotation or motion function, and  the link
        number of the component in motion.  These messages will
        continue to be received as long as the component remains in
        motion.

    LM_ME_OMEGALIMIT (129)
        When a smooth rotation operation started with a call on
        flSetCompOmega() reaches its angular limit, an LM_ME_OMEGALIMIT
        message is sent specifying, as a comma-separated list in the
        string argument, the handle number from the flSetCompOmega()
        call and the link number of the component rotated.  When a
        smooth rotation without a limit is terminated by a subsequent
        call on flSetCompOmega() with a zero or other rotation, or a
        rotation is terminated before the limit is reached, an
        LM_ME_OMEGALIMIT message is sent to report completion of the
        rotation.

    LM_ME_MOVELIMIT (132)
        When a smooth motion started with a call on flSetCompMotion()
        reaches its distance limit, an LM_ME_MOVELIMIT message is sent
        specifying, as a comma-separated list in the string argument,
        the handle number from the flSetCompMotion() call and the link
        number of the component moved.  When a motion is terminated by
        a subsequent flSetCompMotion() call before the limit is
        reached, an LM_ME_MOVELIMIT message is sent to report
        completion of the motion.

Details and Gotchas
=============

Due to the asynchronous operation of Second Life, there are several
potential sources of confusion in using Fourmilab Mechanisms.  Here are
some things to approach warily.

In order for the mechanism configuration to be communicated to the API
in your script, your script must receive the LM_ME_CONFIG link message
and pass it to the API.  This may be accomplished with the following
code in your script's event handler:
    link_message(integer sender, integer num, string str, key id) {

        //  LM_ME_CONFIG (127): Mechanism configuration

        if (num == LM_ME_CONFIG) {
            flMechConfig(str);
        }
    }
See the code in the example Gimbals script to see how this is
implemented.  If more than one script in your build uses the Mechanisms
API, each must contain this code to process the configuration.

When you initialise a mechanism with flMechInit(), several seconds are
required to read the mechanism definition from the configuration
notecard.  If you make API calls which require the mechanism definition
before it is loaded, these calls will fail.  You can test whether the
configuration loading is complete by inquiring
llGetListLength(linkNames).  If it is zero, the configuration has not
yet completed loading.  You can be certain the Mechanisms configuration
process is complete when the flMechConfig() call in the LM_ME_CONFIG
handler returns.

When you rotate or move a component with flSetCompRot() or
flSetCompPos(), the API function within your script sends a link
message to the Mechanism script which adjusts the component and its
child components.  Because scripts run asynchronously, if you
immediately call flGetCompRot() or flGetCompPos() in your main script,
or inquire the component's orientation with llGetLinkPrimitiveParams(),
you will probably receive the component's old position because the
Mechanism script hasn't yet had a chance to actually move the
components.  To avoid such problems, these functions send a
LM_ME_COMPLETE (131) link message when all component updates have been
completed.  The string parameter of the message consists of two
integers separated by a comma, with the first the operation code just
completed (LM_ME_ROTATE or LM_ME_TRANSLATE) and the second the handle
of the operation (returned by the API call which initiated it).  Your
script should wait until it receives this confirmation message before
performing any further operations on that link or any of its parent or
child components.

If you start an object rotating with flSetCompOmega() and specify a
limited rotation with the limit argument, when the specified rotation
is complete a link message with the code LM_ME_OMEGALIMIT (129) will be
sent to scripts in the link.  You can receive this message in the
link_message() handler of your client script and perform whatever
operations you wish when the rotation completes.  The link message will
have a string parameter containing the number of the link which has
just completed its rotation and the handle for the operation; this
allows you to distinguish completions of rotations if multiple links
are rotating simultaneously.  Due to lag in Second Life's responding to
script events, an object rotated by flSetCompOmega() with an angular
limit may not stop at the precise point specified.  If you need the
component to be exactly aligned at the end of its rotation (for
example, a door closing in its frame), call flSetCompRot() to set its
rotation exactly after you receive the LM_ME_OMEGALIMIT message
indicating the automatic rotation has completed.  As the component
rotates, LM_ME_COMPLETE messages with an operation code of
LM_ME_ROTSTEP (134) are sent for each incremental rotation, specifying
the handle returned by the flSetCompOmega() call which started the
rotation.  You may receive a single LM_ME_ROTSTEP message indicating
completion of the last step after receiving an LM_ME_OMEGALIMIT
message.

If you start an object moving with flSetCompMotion(), when the
specified distance has been reached a link message with the code
LM_ME_MOVELIMIT (132) will be sent to scripts in the link.  You can
receive this message in the link_message() handler of your client
script and perform whatever operations you wish when the movement
completes.  The link message will have a string parameter containing
the number of the link which has just completed its motion and the
handle for the operation; this allows you to distinguish completions if
multiple links are moving simultaneously.  Due to lag in Second Life's
responding to script events, an object moved by flSetCompMotion() may
not stop at the precise distance specified.  If you need the component
to be exactly positioned at the end of its motion, call flSetCompPos()
to set its position exactly after you receive the LM_ME_MOVELIMIT
message indicating the automatic movement has completed.  As the
component moves, LM_ME_COMPLETE messages with an operation code of
LM_ME_TRANSTEP (135) are sent for each incremental move, specifying the
handle returned by the flSetCompMotion() call which started the motion.
You may receive a single LM_ME_TRANSTEP message indicating completion
of the last step after receiving an LM_ME_MOVELIMIT message.

Conclusion: Fear Not, or Not Too Much
=========================

Fourmilab Mechanisms is a large and relatively complicated software
subsystem, implemented in more than 2000 lines of Linden Scripting
Language code and three separate script components (not counting the
included examples and optional facilities).  As such, it may seem
intimidating when you first encounter it, but have heart: it was
created to make your life as a model builder simpler, not more
difficult.  Many applications of Fourmilab Mechanisms will only need to
use a fraction of its facilities (for example, you may not need the
smooth rotation and motion features at all, which are the most
complicated parts), and you can simply ignore everything you don't
need.

The included examples are intended to illustrate applications of
Fourmilab Mechanisms and serve as a “code mine” upon which you can
model your own builds and re-use code as you wish.  If you're puzzled
about how something works, examining code which uses it in the examples
is an excellent starting point in understanding it.

Building complex hierarchical mechanisms in Second Life has always been
a challenge.  Fourmilab Mechanisms attempts to encapsulate much of this
complexity in a black box which you can use to simplify the
construction of your builds.  Once you master the learning curve, we
hope you'll find it easier to build interesting objects in Second Life
which realistically model the real world.
