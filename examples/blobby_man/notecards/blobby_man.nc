
                        Fourmilab Blobby Man

                               User Guide

Fourmilab Blobby Man is hierarchical model built on the foundation of
Fourmilab Mechanisms:
    https://marketplace.secondlife.com/p/Fourmilab-Mechanisms/20515612
which implements a humanoid mannequin compatible with the structure of
the Second Life standard avatars.  All joints in the mannequin are
articulated as a Fourmilab Mechanisms model and move like the “bones”
in Second Life avatars.

Blobby Man was inspired by the original Blobby Man created by computer
graphics pioneer Jim Blinn, first published in:
    “Jim Blinn's Corner”, IEEE Computer Graphics and Applications,
        October 1987, Page 59.
and subsequently included in chapter 3 of:
    Blinn, Jim.  Jim Blinn's Corner: A Trip Down the Graphics
    Pipeline.  San Francisco: Morgan Kauffmann, 1996.
    ISBN 978-1-55860-387-5.
An implementation of the Blobby Man was included in my Simple Graphics
Library, developed at Autodesk, Inc. in March, 1988 to test and
demonstrate the 3DMESH facilities in AutoCAD and subsequently used in
demonstrations of other products such as AutoShade and AutoFlix.

Fourmilab Blobby Man for Second Life is inspired by, but not completely
compatible with Jim Blinn's original creation.  It has some additional
joints in its skeleton and default orientations to be compatible with
the Second Life standard avatars, allowing it to be used with poses and
animations developed for those avatars.

Applications

Fourmilab Blobby Man was originally developed as a tour de force
example of Fourmilab Mechanisms: a demonstration that hierarchical
structures as complex as a fully-articulated avatar can be easily
created and manipulated using the its facilities.  As with many
Fourmilab projects, it “just grew” and became capable of illustrating
Second Life animations, poses, and other avatar-related features.  If
you wish to build characters within Second Life based entirely upon
fundamental prims, Blobby Man is an excellent place to start, as you
can replace its rudimentary model with whatever you want without
altering its basic functionality.

Introduction and (Very) Informal Demonstration

When you rez a new copy of Blobby Man, it will inform you that it is
listening for commands on local chat port 1721 (the birth year of
Pierre Jaquet-Droz, creator of the Neuchâtel mechanical androids:
    https://en.wikipedia.org/wiki/Pierre_Jaquet-Droz
).  It initially stands on its light blue translucent platform, at
“attention” for a Second Life avatar: a “T pose” with arms extended.

You can manipulate any of the joints of the Blobby Man with chat
commands, as we'll see below.  In addition, the Blobby Man is able to
play animations in the same format (BVH) used by Second Life avatars
and animesh characters.  You can play a scripted demonstration which
shows a variety of animations simply by touching the Blobby Man.

Let's start sending commands with a salute.  Type into the local chat
box:
    /1721 Animation run Salute
and now, take a bow (on this and subsequent commands, I'll omit the
channel number).
    Animation run Bow
You can abbreviate most commands and parameters to as few as two
characters and use either upper and lower case characters as you wish.
Names of scripts, however, must be entered exactly as specified.  For
the previous command, you could have entered:
    an RU Bow
but “Bow” must be entered exactly as it appears in the inventory of the
Blobby Man object.

The Blobby Man remembers his (or her—up to you!) initial configuration,
and you can always restore it with the command:
    Panic
Try this now.  The Blobby Man returns to attention.

Try running some other animations.  You can get a list by entering:
    Animation run
and then run any of them with a command like:
    Animation run Baseball Pitch
STEE-RIKE!

The Blobby Man can load and perform animations defined in the BioView
Hierarchy (BVH) format accepted by Second Life for animation uploads.
Unfortunately, due to limitations in Second Life's ability to read
files, these animation definitions must be slightly re-formatted before
they can be loaded, but we'll defer discussion of these details for
later.

Let's load one of the standard Second Life avatar animations: “Jump for
Joy”:
    Animation load Jump for Joy
after quite a while (Second Life scripts aren't high-performance
computing platforms!), the load will be confirmed with:
    Animation BVH: Jump for Joy loaded, 32 frames, 24 frames/second.
You can now play this animation with:
    Animation play
Animations played directly from BVH files run much slower because of
the amount of computation which must be done interpreting the file.
Later, we'll show how to compile animations into scripts that run many
times faster.

You can also manipulate the model directly by rotating joints.  To show
a list of joints in the orientation they appear in the body, use the
command:
    Joint list
which produces output:
                    head
                    neck
            lCollar      rCollar
    lShldr    chest           rShldr
    lForeArm  abdomen   rForeArm
    lHand       Hips           rHand
            lThigh         rThigh
            lShin          rShin
            lFoot          rFoot
Start by restoring the standard posture:
    Panic
then move the left arm to the side by rotating it 90 degrees around its
Y axis:
    Joint rotate lShldr <0, 90, 0>
Note that rotating the shoulder joint moves the forearm and hand which
are child objects attached to it.  Now turn the head 30 degrees to its
left by rotating around the Z axis.
    Joint rotate head <0, 0, 30>
Note that the nose and mouth move with the head.  Now nod by moving the
head joint 15 degrees around the X axis.
    Joint rotate head <15, 0, 0>
Note that the head nods around its X axis, after being rotated
previously around its Z axis.

Now raise the right arm into a salute.
    Joint rotate rShldr <0, 25, 0>
    Joint rotate rForeArm <0, 135, 0>
    Joint rotate rHand <90, 0, 0>

Now list the rotation of the right arm we've just positioned:
    Joint list rShldr
         Joint: rShldr: Pos <-0.2244, 0, 0> Rot <0, 25.00005, 0>
    Joint list rForeArm
        Joint: rForeArm: Pos <-0.3009, 0, 0> Rot <180, 44.99998, 180>
    Joint list Rhand
        Joint: rHand: Pos <-0.2655, 0, 0> Rot <90, 0, 0>
You can list the positions of all joints with:
    Joint list *
If you goof, you can undo previous “Joint rotate” commands with “Joint
undo”.
    Joint rotate rThigh <180, 0, 0>
    Joint undo

Once you've set a pose, you can save it as a script to restore it with:
    Export script
which will write a script on local chat like:
    [07:53] Blobby Man: == Import rotate "Hips" <0, 0, 0>
    [07:53] Blobby Man: == Import translate "Hips" <0, 0, 1.02929>
    [07:53] Blobby Man: == Import rotate "Joint: abdomen" <0, 0, 0>
    [07:53] Blobby Man: == Import rotate "Joint: chest" <0, 0, 0>
    [07:53] Blobby Man: == Import rotate "Joint: head" <13.06435, 7.43552, 29.14744>
    [07:53] Blobby Man: == Import rotate "Joint: lCollar" <0, 0, 0>
    [07:53] Blobby Man: == Import rotate "Joint: lFoot" <0, 0, 0>
    [07:53] Blobby Man: == Import rotate "Joint: lForeArm" <0, 0, 0>
    [07:53] Blobby Man: == Import rotate "Joint: lHand" <0, 0, 0>
    [07:53] Blobby Man: == Import rotate "Joint: lShin" <0, 0, 0>
    [07:53] Blobby Man: == Import rotate "Joint: lShldr" <0, 90, 0>
    [07:53] Blobby Man: == Import rotate "Joint: lThigh" <0, 0, 0>
    [07:53] Blobby Man: == Import rotate "Joint: neck" <0, 0, 0>
    [07:53] Blobby Man: == Import rotate "Joint: rCollar" <0, 0, 0>
    [07:53] Blobby Man: == Import rotate "Joint: rFoot" <0, 0, 0>
    [07:53] Blobby Man: == Import rotate "Joint: rForeArm" <180, 44.99998, 180>
    [07:53] Blobby Man: == Import rotate "Joint: rHand" <90, 0, 0>
    [07:53] Blobby Man: == Import rotate "Joint: rShin" <0, 0, 0>
    [07:53] Blobby Man: == Import rotate "Joint: rShldr" <0, 25.00005, 0>
    [07:53] Blobby Man: == Import rotate "Joint: rThigh" <0, 0, 0>
Delete everything from each line before “Import” and paste into a
script in the object's inventory with a name beginning with “Script:”,
for example “Script: My Pose”.  You can now restore the default pose
and run the script to reset the pose:
    Panic
    Script run My Pose

COMMAND REFERENCE

The following commands may be submitted either from local chat via the
Blobby Man command channel (1721 by default) or from a script.

Control Commands

    Boot
        Restart the script and reload the mechanism description from
        the “Mechanism Configuration” notecard.  This takes several
        seconds to load and configure the structure.  The other
        commands will not work and should not be submitted until the
        “End configuration” confirmation message appears.

    Help [ blobby/calculator/mechanisms ]
        Requests the User Guide notecard for Blobby Man, the Geometric
        Calculator, or Fourmilab Mechanisms.  If you omit or enter an
        unknown topic, a list of available help is shown.

    Panic [ gently ]
        Restore all components to their original positions as specified
        in the “Mechanism Configuration” notecard.  Any animation in
        the process of being played, compiled, run, or repeated is
        stopped.  Any running scripts are terminated unless “gently”
        is specified (this allows resetting the configuration within
        scripts without terminating them).

    Status
        Show status information for the main and auxiliary scripts.

    Clear
        Send blank space to local chat to set off subsequent output.

Script Commands
    These commands control the running of scripts stored in notecards
    in the inventory of the Blobby Man object. Commands in scripts are
    identical to those entered in local chat (but, of course, are not
    preceded by a slash and channel number).  Blank lines and those
    beginning with a “#” character are treated as comments and ignored.

    Script list
        Print a list of scripts in the inventory.  Only scripts whose
        names begin with “Script: ” are listed and may be run.

    Script run [ Script Name ]
        Run the specified Script Name.  The name must be specified
        exactly as in the inventory, without the leading “Script: ”.
        Scripts may be nested, so the “Script run” command may
        appear in a script.  Entering “Script run” with no script
        name terminates any running script(s).

        The following commands may be used only within scripts.

        Script loop [ n ]
            Begin a loop within the script which will be executed n
            times, or forever if n is omitted.  Loops may be nested,
            and scripts may run other scripts within loops.  An
            infinite loop can be terminated by “Script run” with no
            script name or the “Boot” command.

        Script end
            Marks the end of a "Script loop".  If the number of
            iterations has been reached, proceeds to the next command.
            Otherwise, resumes at the statement at the start of the
            loop.

        Script pause n
            Pauses execution of the script for n seconds.

Joint Commands
    These commands manipulate the joints of the model.  Most of these
    commands involve names of joints which are shown by “Joint list”
    with no arguments.  Joint names may be specified with either lower
    or upper case letters but may not be abbreviated.

    Joint list [ name/* ]
        With no argument a list of all joint names is shown, with the
        joints approximating their positions in the model.  If a joint
        name is specified, its position and rotation with respect to
        its parent joint are shown.  For the Hips joint, which is the
        root of the Blobby Man mechanism, its position relative to the
        base stand, the root prim of the link set, is shown.  Rotations
        are shown as Euler angles in degrees.

    Joint rotate name <x, y, z>
        Rotate the named joint by the Euler angles x, y, and z
        specified in degrees.  In most cases you'll want to rotate only
        in one axis at a time, with the other two axes zero.  If you
        specify more than one nonzero axis, rotations occur in the
        order z, y, then x.  Rotating a joint rotates all of its child
        components.  This command can be undone.

    Joint translate name <x, y, z>
        Move the joint and its child components by the offset, in
        metres, given by x, y, and z.  Moving the root joint, Hips,
        moves the entire model relative to the stand.  This command can
        be undone.

    Joint spin name <x, y, z> spinrate gain [ limit ]
        Smoothly spin the named joint around the axis defined by the
        vector <x, y, z> at a rate in radians per second given by the
        product of spinrate and gain.  If the rate is zero, any current
        rotation is cancelled.  If limit is specified, the spin will
        stop after the specified number of degrees.  If no limit is
        given, the spin will continue until manually cancelled. Undoing
        the spin command halts the rotation and restores the previous
        orientation of the joint.  The smoothness of the spin depends
        upon the performance of the simulator and viewer, and may be
        jerky under conditions of heavy loads, especially if you have
        several components spinning or moving at the same time.

    Joint move name <x, y, z> speed distance
        Smoothly move the named joint in the direction given by the
        vector <x, y, z> the specified distance (in metres) at the
        specified speed (metres/second).  An in-progress move may be
        halted by specifying another move for the same joint with a
        speed of zero.  Undoing the move command halts the motion and
        restores the previous position of the joint.  The smoothness of
        the motion depends upon the performance of the simulator and
        viewer, and may be jerky under conditions of heavy loads,
        especially if you have several components spinning or moving at
        the same time.

    Joint undo
        Reverses the most recent Joint rotate, translate, spin, move
        command.  You may undo back to the first Joint command issued
        since the script was restarted or the most recent Panic
        command.

Animation Commands

    Animation load [ Animation name ]
        Load the named animation notecard from the inventory. Animation
        notecards must be named starting “BVH: ” and encoded from the
        original BVH animation file by the “bvh_to_bvm.pl” program,
        available from the GitHub source archive, described below.  The
        animation name must be specified exactly as in the inventory.
        If no animation name is given, a list of all BVH: animations in
        the inventory is shown on local chat.

    Animation play [ start [ end ] ]
        Play the currently loaded animation from the start to end
        frame. If no end frame is given, just the start frame is
        played.  If no start or end frame is specified, the entire
        animation is played.  A great deal of computation must be done
        to display an animation from a BVH file, so the animation will
        be shown much slower than it would be played by a Second Life
        avatar.  You can compile the animation into a script file to
        speed up its display.

    Animation stop
        Stop display of the currently playing animation.

    Animation joint [ name / * ]
        List the rotations (plus position, for the root “hip” joint)
        for the most recently played animation frame.  If a joint name
        of “*” is specified, all joints will be listed.  This command
        is normally used after playing a single frame with the
        “Animation play” command.

    Animation run/repeat Animation name
        Play a single time (“run”) or loop (“repeat”) the compiled
        animation script with the specified name from the inventory.
        If no animation name is given all compiled animations (scripts
        whose name must begin with “Animation: ”) will be listed.

    Animation compile [ start [ end ] ]
        Compile the currently loaded animation or just the specified
        range of frames (as for the “Animation play” command, see
        above).  Information needed to compile the animation will be
        written to local chat as a voluminous sequence of output that
        looks like:
            [14:46] Blobby Man: ---------- Compiling animation "BVH: Jumping Jacks": Frames 0-20 of 21 Time 0.066667 Vscale 43.568410 Nodes 19 ----------
            [14:46] Blobby Man: Frame 0
            [14:46] Blobby Man: ---------- Frame 0 ----------
            [14:46] Blobby Man: -- 0.0 -- 585705822,-423027105,537395712,585702494,-423026436,509082121,585106014,-415489117,509082121,584718686,-410966724,520612364,580322142,-399954965,520612364,576325214,-389926398,520612364,561191518,-391040514,520612364,
            [14:46] Blobby Man: -- 0.1 -- 561186654,-391040514,873741137,414656094,-402050634,423927205,394990174,-411292678,423927205,375399774,-420469185,431314426,332206174,-461823365,431314426,289023070,-503308617,526746191,261623390,-531882914,526746191,
            …
            [14:48] Blobby Man: ---------- End frame 20, lines 6 ----------
            [14:48] Blobby Man: ---------- Animation compilation complete ----------
        Copy the entire chat transcript (lines not related to animation
        compilation will be ignored; there is no need to delete them)
        to a file on your computer, then process the file with the
        “compile_animation.pl” program, available from the GitHub
        source archive, described below.  This will create a series of
        files with names like:
            Jumping_Jacks-1_2.lsl
            Jumping_Jacks-2_2.lsl
        Now create new scripts in the inventory of your copy of Blobby
        Man with names:
            Animation: Jumping Jacks 1/2
            Animation: Jumping Jacks 2/2
        and copy the text from the .lsl files into them.  You should
        now be able to play the compiled animations with the "Animation
        run” or “Animation repeat” commands.

Calculator Commands
    The Blobby Man includes a fully-functional copy of the Fourmilab
    Geometric Calculator.  You can send commands to the calculator by
    prefixing them with “Calc”, for example:
        Calc {0, 60, 0} * {0, 0, 90}
    The result of the calculation will be displayed in local chat. For
    complete documentation of the Geometric Calculator, enter:
        Calc help

Import/Export Commands
    These commands allow exporting a pose as a script which can be used
    to restore it.

    Export script
        Export the current pose as a Blobby Man script to re-create it.
        Copy the lines from the local chat window, paste them into a
        text file on your computer, and delete all text before the
        “Import” command on each line.  Save the resulting script file,
        then create a new notecard with a beginning with “Script: ”
        (for example, “Script: My pose”), then install it in the
        inventory of the Blobby Man.  You can then run the script with
        the “Script run” (see above) command to restore the pose you
        exported.

    Export list
        List the joints and their orientations as they will be
        exported.

    Import rotate "joint" <x, y, z>
        Rotate the named joint to the Euler angles specified by <x, y,
        z> in degrees.  The Import rotate command differs from the
        “Joint rotate” command in that it sets the joint's rotation
        regardless of its prior orientation instead of rotating the
        joint relative to it.

    Import translate "joint" <x, y, z>
        Translate the named joint to the position, relative to its
        parent component, given by <x, y, z>.  The Import translate
        command differs from the “Joint rotate” command in that it sets
        the joint's position regardless of its prior location instead
        of moving the joint relative to it.

MECHANISM STRUCTURE DEFINITION

This is the declaration of the mechanism structure as it appears in the
“Mechanism Configuration” notecard.  Joints are arranged in a
tree-structured hierarchy, with “Hips” as the root, and other joints
and the blobs composing body parts as children.  There are seven levels
of hierarchy and 43 moving parts in the model.

    Set parent "Hips"   "Joint: lThigh" "Joint: rThigh" "Joint: abdomen"

        Set parent "Joint: lThigh"   "Left Thigh" "Joint: lShin"
            Set parent "Joint: lShin"   "Left Calf" "Joint: lFoot"
                Set parent "Joint: lFoot"   "Left Foot" "Left Heel"

        Set parent "Joint: rThigh"   "Right Thigh" "Joint: rShin"
            Set parent "Joint: rShin"   "Right Calf" "Joint: rFoot"
                Set parent "Joint: rFoot"   "Right Foot" "Right Heel"

        Set parent "Joint: abdomen"   "Abdomen" "Joint: chest"
            Set parent "Joint: chest"    "Thorax" "Shoulders" "Joint: lCollar"  "Joint: rCollar" "Joint: neck"

            Set parent "Joint: neck"   "Neck" "Joint: head"
                Set parent "Joint: head"   "Head" "Nose" "Mouth"

            Set parent "Joint: lCollar"   "Left Clavicle" "Joint: lShldr"
                Set parent "Joint: lShldr"   "Left Upper arm" "Joint: lForeArm"
                    Set parent "Joint: lForeArm"   "Left Lower arm" "Joint: lHand"
                        Set parent "Joint: lHand" "Left Hand"

            Set parent "Joint: rCollar"   "Right Clavicle" "Joint: rShldr"
                Set parent "Joint: rShldr"   "Right Upper arm" "Joint: rForeArm"
                    Set parent "Joint: rForeArm"  "Right Lower arm" "Joint: rHand"
                        Set parent "Joint: rHand" "Right Hand"

The Second Life standard avatar has two additional components:
“neckDummy” and “figureHair” which are not used in the built-in
animations.  They are not included in the Blobby Man model.
