    /*
                    Fourmilab Marble Madness

                          Marble Object

        A marble is an object independent of whatever machine
        in which it is running.  When initially rezzed, it is
        a non-physical object.  It remembers its initial position
        so that it can be restored there by a PANIC message.  The
        PANIC position is updated on state_entry(), so you can
        manually move the marble to a new position then reset this
        script to update the PANIC position to that location.  The
        marble then begins to listen for commands on marbleChan.

        The marble receives and responds to the following messages
        from the mechanism.  All positions and rotations in these
        messages are in region co-ordinates: marbles never deal
        with mechanism link set or component co-ordinates.

            ORIGIN orgvec
                Set the origin of the moving platform to orgvec.

            PANIC
                Disable physics, restore to the original position, and
                turn off any recovery modes from losing our marbles.

            TILTING fromRot toRot
                Notify the marble the platform has begun to tilt
                from original rotation fromRot to toRot.  This message
                is sent before the platform motion begins, but of
                course may be received by the marble subsequently.

            TILTED
                Notify the marble platform tilt is complete.  At this
                point the platform should be in rotation toRot.

            WHERE orgvec
                Report region position relative to orgvec.

        At this time, marbles send no messages back to the mechanism.

    */

    integer marbleChan = -982449767;    // Channel for communications with marbles
    integer mechHandle;                 // Handle for mechanism listener
    vector panicPos;                    // Position for panic restore
    vector origin;                      // Origin of tilt table (region co-ordinates)
    rotation mechRot;                   // Rotation of mechanism (region co-ordinates)
    float mechRad;                      // Radius of mechanism (to detect loss of marbles)
    integer colourIndex = -1;           // Colour index
    integer offboard = FALSE;           // Have we fallen off the board ?

    /*  Standard colour names and RGB values.  The first 8
        colours have the indices of the classic AutoCAD
        colour palette.  */

    list colours = [
        "black", <0, 0, 0>,         // 0
        "red", <1, 0, 0>,           // 1
        "yellow", <1, 1, 0>,        // 2
        "green", <0, 1, 0>,         // 3
        "cyan", <0, 1, 1>,          // 4
        "blue", <0, 0, 1>,          // 5
        "magenta", <1, 0, 1>,       // 6
        "white", <1, 1, 1>,         // 7

        /*  We fill out 8 and 9, which are also white in the
            AutoCAD palette, with useful colours accessible
            with a single digit index.  These are defined
            as in HTML5.  */

        "orange", <1, 0.647, 0>,    // 8
        "grey", <0.5, 0.5, 0.5>     // 9
    ];

    //  initMarble  --  Initialise marble on script reset

    initMarble() {
        llSetStatus(STATUS_PHYSICS, FALSE);
        string desc = llList2String(llGetPrimitiveParams([ PRIM_DESC ]), 0);
        if (llGetSubString(desc, 0, 0) == "<") {
            llSetRegionPos((vector) desc);
        }
        panicPos = llGetPos();
        offboard = FALSE;

        //  Only listen for commands if rezzed by a mechanism
        if (colourIndex >= 0) {
            mechHandle = llListen(marbleChan, "", NULL_KEY, "");
        }
    }

    //  lostMarble  --  Handle marble being lost from mechanism

    lostMarble() {
        llSetStatus(STATUS_PHYSICS, FALSE);
        offboard = TRUE;
llOwnerSay("Lost our marble: disabled physics.");
    }

    default {
        on_rez(integer sparam) {
            if (sparam > 0) {
                /*  If rezzed by the mechanism, the start parameter
                    is encoded as:
                            UUUUUC
                    where UUUUU is a five digit decimal unique channel
                    code used to communicate with the mechanism and C
                    is a colour index from the colours[] list above.  */

                colourIndex = sparam % 10;
                llSetColor(llList2Vector(colours,
                    (colourIndex * 2) + 1), ALL_SIDES);
                llSetObjectName(llGetObjectName() + " (" +
                    llList2String(colours, colourIndex * 2) + ")");

                //  Set marble channel incorporating UUUUU code
                marbleChan = marbleChan ^ ((sparam / 10) << 7);

                //  Adjust vertical position to sit on table
//                vector size = llGetScale();
//                llSetPos(llGetPos() + <0, 0, size.z / 2>);

                //  Save position in description for restart
                llSetLinkPrimitiveParamsFast(LINK_THIS,
                    [ PRIM_DESC, (string) llGetPos() ]);

                //  Re-initialise
                initMarble();
            }
        }

        state_entry() {
            initMarble();
        }

        listen(integer channel, string name, key id, string message) {
            if (channel == marbleChan) {
                list msg = llCSV2List(message);
                string type = llList2String(msg, 0);

                if (offboard && (type != "PANIC")) {
                    return;
                }

                //  ORIGIN:  Send region co-ordinates of origin

                if (type == "ORIGIN") {
                    origin = (vector) llList2String(msg, 1);    // Tilt table origin
                    mechRot = (rotation) llList2String(msg, 3); // Mechanism rotation
                    mechRad = (float) llList2String(msg, 4);    // Mechanism radius
//llOwnerSay("Origin " + (string) origin + " rot " + (string) (llRot2Euler(mechRot) * RAD_TO_DEG));

                //  TILTING:  Start table tilt operation

                } else if (type == "TILTING") {
                    llSetStatus(STATUS_PHYSICS, FALSE);
                    rotation tiltFrom = ((rotation) llList2String(msg, 1)) * mechRot;
                    rotation tiltTo = ((rotation) llList2String(msg, 2)) * mechRot;
//llOwnerSay("Tilting from " + (string) (llRot2Euler(tiltFrom) * RAD_TO_DEG) +
//    " to " + (string) (llRot2Euler(tiltTo) * RAD_TO_DEG));
                    vector cvec = llGetPos() - origin;      // Current vector from origin
                    vector nvec = (cvec / tiltFrom) * tiltTo;   // Transform from old to new tilt
//llOwnerSay("  cvec " + (string) cvec + "  nvec " + (string) nvec +
//    "  opos " + (string) llGetPos() + "  npos " + (string) (origin + nvec));
                    llSetPos(origin + nvec);                // Jump to position after the tilt

                //  TILTED:  Table tilt operation complete

                } else if (type == "TILTED") {
//llOwnerSay("Tilted pos " + (string) llGetPos());
                    llSetStatus(STATUS_PHYSICS, TRUE);

                //  PANIC:  Restore saved initial position

                } else if (type == "PANIC") {
                    llSetStatus(STATUS_PHYSICS, FALSE);
                    llSetRegionPos(panicPos);
                    offboard = FALSE;
//llOwnerSay("Ook!  " + (string) llGetPos());

                //  Q?+:$$:  Self-destruct

                } else if (type == "Q?+:$$") {
                    llDie();

                //  WHERE:  Report identity and position

                } else if (type == "WHERE") {
                    vector org = (vector) llList2String(msg, 1);
                    llOwnerSay("Marble: " + (string) colourIndex +
                        ", " + (string) (llGetPos() - org));
                }
            }
        }

        /*  The collision handler is a gimmick to recover more
            elegantly from "losing our marbles" accidents.  If the
            marble collides with an object located outside the radius
            of the mechanism, it disables physics and sets the
            offboard flag which causes it to ignore all messages
            except PANIC  This keeps marbles from getting too far
            from the mechanism if something causes them to fall
            out.  This should be able to be disabled in production
            once the problems which motivated its inclusion are
            sorted out.  */

        collision(integer n) {
            //  We ignore collisions if we're already offboard
            if ((!offboard) && (llVecDist(llGetPos(), origin) > mechRad)) {
                lostMarble();
            }
        }

        //  A collision with terrain always means a lost marble

        land_collision(vector where) {
            lostMarble();
        }
    }
