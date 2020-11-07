    /*

                    Fourmilab Marble Madness

        This is a demonstration of Fourmilab Mechanisms.

    */

    key owner;                      // Owner UUID

    integer commandChannel = 1984;  // Command channel in chat (launch year of Atari Marble Madness)
    integer commandH;               // Handle for command channel
    key whoDat = NULL_KEY;          // Avatar who sent command
    integer restrictAccess = 0;     // Access restriction: 0 none, 1 group, 2 owner
    integer echo = TRUE;            // Echo chat commands ?

    float angleScale = DEG_TO_RAD;  // Scale factor for angles
    integer trace = FALSE;          // Trace operation ?
    float volume = 1;               // Volume for sounds

    integer marbleChan = -982449767;    // Channel for communications with marbles
    integer channelUniq = 0;        // Channel uniqueness code

    integer tilting = FALSE;        // Tilt in progress ?
    vector tiltAxis = <1, 0, 0>;    // Axis of tilt
    integer tiltLink;               // Link number to tilt
    float tiltMax = 12;             // Tilt maximum angle, degrees
    float tiltPause = 5;            // Pause between tilt cycles, seconds

    rotation tiltRotOrig;           // Original rotation
    rotation tiltRotFrom;           // Start rotation
    rotation tiltRotTo;             // End rotation
    rotation tiltOrigRot;           // Origin rotation in region co-ordinates

    string helpFileName = "Fourmilab Mechanisms User Guide";

    /*  Table of marbles, with colour index and position relative
        to the link set root, which we rez when created.  */

    list marbles = [
        1, <1.35439, -0.03469, 0.41663>,
        3, <0.06104, 0.91166, 0.41663>
    ];
    integer maxColour = -1;         // Maximum colour index used by marbles

    //  Link messages

    //  Calculator messages

//  integer LM_CA_INIT = 210;       // Initialise script
//  integer LM_CA_RESET = 211;      // Reset script
//  integer LM_CA_STAT = 212;       // Print status
    integer LM_CA_COMMAND = 213;    // Submit calculator command
//  integer LM_CA_RESULT = 214;     // Report calculator result

    //  tawk  --  Send a message to the interacting user in chat

    tawk(string msg) {
        if (whoDat == NULL_KEY) {
            //  No known sender.  Say in nearby chat.
            llSay(PUBLIC_CHANNEL, msg);
        } else {
            /*  While debugging, when speaking to the owner, use llOwnerSay()
                rather than llRegionSayTo() to avoid the risk of a runaway
                blithering loop triggering the gag which can only be removed
                by a region restart.  */
            if (owner == whoDat) {
                llOwnerSay(msg);
            } else {
                llRegionSayTo(whoDat, PUBLIC_CHANNEL, msg);
            }
        }
    }

    //  ef  --  Edit floats in string to parsimonious representation

    string efv(vector v) {
        return ef((string) v);
    }

/*
    string eff(float f) {
        return ef((string) f);
    }
*/

    string efr(rotation r) {
        return efv(llRot2Euler(r) * RAD_TO_DEG);
    }

    //  Static constants to avoid costly allocation
    string efkdig = "0123456789";
    string efkdifdec = "0123456789.";

    string ef(string s) {
        integer p = llStringLength(s) - 1;

        while (p >= 0) {
            //  Ignore non-digits after numbers
            while ((p >= 0) &&
                   (llSubStringIndex(efkdig, llGetSubString(s, p, p)) < 0)) {
                p--;
            }
            //  Verify we have a sequence of digits and one decimal point
            integer o = p - 1;
            integer digits = 1;
            integer decimals = 0;
            string c;
            while ((o >= 0) &&
                   (llSubStringIndex(efkdifdec, (c = llGetSubString(s, o, o))) >= 0)) {
                o--;
                if (c == ".") {
                    decimals++;
                } else {
                    digits++;
                }
            }
            if ((digits > 1) && (decimals == 1)) {
                //  Elide trailing zeroes
                integer b = p;
                while ((b >= 0) && (llGetSubString(s, b, b) == "0")) {
                    b--;
                }
                //  If we've deleted all the way to the decimal point, remove it
                if ((b >= 0) && (llGetSubString(s, b, b) == ".")) {
                    b--;
                }
                //  Remove everything we've trimmed from the number
                if (b < p) {
                    s = llDeleteSubString(s, b + 1, p);
                    p = b;
                }
                //  Done with this number.  Skip to next non digit or decimal
                while ((p >= 0) &&
                       (llSubStringIndex(efkdifdec, llGetSubString(s, p, p)) >= 0)) {
                    p--;
                }
            } else {
                //  This is not a floating point number
                p = o;
            }
        }
        return s;
    }

    //  checkAccess  --  Check if user has permission to send commands

    integer checkAccess(key id) {
        return (restrictAccess == 0) ||
               ((restrictAccess == 1) && llSameGroup(id)) ||
               (id == llGetOwner());
    }

    /*          ************************************************
                *                                              *
                *             Fourmilab Mechanisms             *
                *             Client-Side Interface            *
                *                                              *
                ************************************************  */

    //  Support storage for Mechanisms module
    list dependencyList;            // List of dependency relationships
    list linkNames;                 // List of link names
    /* IF OMEGA */
    list omegaList;                 // List of omega rotations
    /* END OMEGA */
    /* IF MOTION */
    list motionList;                // List of component motions
    /* END MOTION */

    //  Mechanisms link messages
    integer LM_ME_INIT = 120;       // Initialise mechanisms
//  integer LM_ME_RESET = 121;      // Reset mechanisms script
    integer LM_ME_STAT = 122;       // Print status
    integer LM_ME_TRANSLATE = 123;  // Translate component
    integer LM_ME_ROTATE = 124;     // Rotate component
    integer LM_ME_SPIN = 125;       // Spin (omega rotate) component
    integer LM_ME_PANIC = 126;      // Reset components to initial state
    integer LM_ME_CONFIG = 127;     // Return configuration to client script
    integer LM_ME_SETTINGS = 128;   // Set parameters in mechanisms module
    integer LM_ME_OMEGALIMIT = 129; // Omega rotation reached limit
//  integer LM_ME_CHANGED = 130;    // Position/rotation change report to compiler
    integer LM_ME_COMPLETE = 131;   // Confirm component update complete
    integer LM_ME_MOVELIMIT = 132;  // Move limit reached
    integer LM_ME_MOVE = 133;       // Move component
    integer LM_ME_ROTSTEP = 134;    // Rotation step by spin command
    integer LM_ME_TRANSTEP = 135;   // Translation step by move command

    integer flMechHandle = -982449724;  // Request handle base

    //  flMechInit  --  Initialise mechanisms module

    flMechInit(key whom) {
        flMechHandle = flMechHandle ^
            (((integer) ("0x" + ((string) llGetOwner()))) & 0xFFFFF) ^
            (llGetUnixTime() & 0xFFF);
        llMessageLinked(LINK_THIS, LM_ME_INIT, "", whom);
    }

    //  flMechStatus  --  Show status of mechanisms module

    flMechStatus(integer which, key whom) {
        llMessageLinked(LINK_THIS, LM_ME_STAT, (string) which, whom);
    }

    //  flMechPanic  --  Reset mechanism to initial state

    flMechPanic(integer save) {
        llMessageLinked(LINK_THIS, LM_ME_PANIC, (string) save, NULL_KEY);
    }

    //  flMechConfig  --  Process configuration message

    flMechConfig(string msg) {
        list ml = llJson2List(msg);
        integer ncomps = llList2Integer(ml, 0);
        linkNames = llList2List(ml, 1, (1 + ncomps) - 1);
        dependencyList = llList2List(ml, ncomps + 1, -1);
    }

    //  flMechSettings  --  Set mechanisms module modes

    flMechSettings(integer traceMode, integer compile) {
        llMessageLinked(LINK_THIS, LM_ME_SETTINGS,
            llList2CSV([ traceMode, compile ]), NULL_KEY);
    }

    //  flGetCompPos  --  Get position of component relative to parent

    vector flGetCompPos(integer linkno) {
        vector pos = ZERO_VECTOR;

        if (flMechCheckLink(linkno)) {
            list cpr = llGetLinkPrimitiveParams(linkno,
                            [ PRIM_POS_LOCAL, PRIM_ROT_LOCAL ]);
            pos = llList2Vector(cpr, 0);    // This link position, LCS
            //  Parent link number
            integer parent = llList2Integer(dependencyList, linkno - 1);
            if (parent > 0) {
                //  Parent position and rotation, LCS
                list ppr = llGetLinkPrimitiveParams(parent,
                    [ PRIM_POS_LOCAL, PRIM_ROT_LOCAL ]);
                vector parpos = llList2Vector(ppr, 0);
                rotation parrot = llList2Rot(ppr, 1);
                pos = (pos / parrot) - (parpos / parrot);
            }
        }
        return pos;
    }

    //  flGetCompRot  --  Get rotation of component relative to parent

    rotation flGetCompRot(integer linkno) {
        rotation rot = ZERO_ROTATION;

        if (flMechCheckLink(linkno)) {
            rot = llList2Rot(llGetLinkPrimitiveParams(linkno,
                [ PRIM_ROT_LOCAL ]), 0); // This link rotation
            integer parent = llList2Integer(dependencyList, linkno - 1);
            if (parent > 0) {
                rotation parrot = llList2Rot(llGetLinkPrimitiveParams(parent,
                    [ PRIM_ROT_LOCAL ]), 0);
                rot = rot / parrot;
            }
        }
        return rot;
    }

    /* IF OMEGA */
    //  flGetCompOmega  --  Get omega rotation of component

    list flGetCompOmega(integer linkno) {
        integer n = llGetListLength(omegaList);
        integer i;

        for (i = 0; i < n; i += 5) {
            if (llList2Integer(omegaList, i) == linkno) {
                return llList2List(omegaList, i + 1, i + 4);
            }
        }
        return [ ];
    }
    /* END OMEGA */

    /* IF MOTION */
    //  flGetCompMotion  --  Get motion of component

    list flGetCompMotion(integer linkno) {
        integer n = llGetListLength(motionList);
        integer i;

        for (i = 0; i < n; i += 5) {
            if (llList2Integer(motionList, i) == linkno) {
                return llList2List(motionList, i + 1, i + 4);
            }
        }
        return [ ];
    }
    /* END MOTION */

    //  flSetCompRot  --  Set rotation of component

    integer flSetCompRot(integer linkno, rotation newrot) {
        integer handle = flMechHandle;
        if (flMechCheckLink(linkno)) {
            llMessageLinked(LINK_THIS, LM_ME_ROTATE,
                llList2CSV([ linkno, newrot, flMechHandle ]), NULL_KEY);
            flMechHandle += 7;
            return handle;
        }
        return -1;
    }

    //  flSetCompPos  --  Set position of component

    integer flSetCompPos(integer linkno, vector newpos) {
        integer handle = flMechHandle;
        if (flMechCheckLink(linkno)) {
            llMessageLinked(LINK_THIS, LM_ME_TRANSLATE,
                llList2CSV([ linkno, newpos, handle ]), NULL_KEY);
            flMechHandle += 7;
            return handle;
        }
        return -1;
    }

    /* IF OMEGA */
    //  flSetCompOmega  --  Set omega rotation of component

    integer flSetCompOmega(integer linkno, vector axis, float spinrate,
                           float gain, float limit) {
        integer handle = flMechHandle;
        if (flMechCheckLink(linkno)) {
            /*` Because we can't query the omegaList in the
                Mechanisms script synchronously, we keep an
                abbreviated copy of it locally so that
                flGetCompOmega() can return current status.
                If you don't need to use flGetCompOmega, you
                can delete everything through the
                "End flGetCompOmega support" comment.  */
            integer n = llGetListLength(omegaList);
            integer i;

            //  Delete any existing omega entry for this component
            for (i = 0; i < n; i += 5) {
                if (llList2Integer(omegaList, i) == linkno) {
                    omegaList = llDeleteSubList(omegaList, i, i + 4);
                    n = llGetListLength(omegaList);
                }
            }
            if ((spinrate * gain) > 0) {
                omegaList += [ linkno, axis, spinrate, gain, handle ];
            }
            //  End flGetCompOmega support

            llMessageLinked(LINK_THIS, LM_ME_SPIN, llList2CSV(
                [ linkno, axis, spinrate, gain, limit, handle ]), NULL_KEY);

            flMechHandle += 7;
            return handle;
        }
        return -1;
    }
    /* END OMEGA */

    /* IF MOTION */
    //  flSetCompMotion  --  Set motion of component

    integer flSetCompMotion(integer linkno, vector direction,
                            float speed, float distance) {
        integer handle = flMechHandle;
        if (flMechCheckLink(linkno)) {
            /*` Because we can't query the motionList in the
                Mechanisms script synchronously, we keep an
                abbreviated copy of it locally so that
                flGetCompMotion() can return current status.
                If you don't need to use flGetCompMotion, you
                can delete everything through the
                "End flGetCompMotion support" comment.  */
            integer n = llGetListLength(motionList);
            integer i;

            //  Delete any existing motion entry for this component
            for (i = 0; i < n; i += 5) {
                if (llList2Integer(motionList, i) == linkno) {
                    motionList = llDeleteSubList(motionList, i, i + 4);
                    n = llGetListLength(motionList);
                }
            }
            if (speed > 0) {
                motionList += [ linkno, direction, speed, distance, handle ];
            }
            //  End flGetCompMotion support

            llMessageLinked(LINK_THIS, LM_ME_MOVE, llList2CSV(
                [ linkno, direction, speed, distance, handle ]), NULL_KEY);

            flMechHandle += 7;
            return handle;
        }
        return -1;
    }
    /* END MOTION */

    //  flGetCompLink  --  Get link number of component from name, -1 if not found

    integer flGetCompLink(string cname) {
        integer l = llListFindList(linkNames, [ cname ]);
        if (l >= 0) {
            l++;
        }
        return l;
    }

    //  flGetCompName  --  Get component name from link number

    string flGetCompName(integer linkno) {
        if (flMechCheckLink(linkno)) {
            return llList2String(linkNames, linkno - 1);
        }
        return "";
    }

    //  flGetCompParent  --  Return link number of component's parent

    integer flGetCompParent(integer linkno) {
        if (flMechCheckLink(linkno)) {
            return llList2Integer(dependencyList, linkno - 1);
        }
        return -1;
    }

    //  flGetCompChildren  --  Return list of link numbers of component's children

    list flGetCompChildren(integer linkno) {
        list children = [ ];

        if (flMechCheckLink(linkno)) {
            integer n = llGetListLength(dependencyList);
            integer i;

            for (i = 0; i < n; i++) {
                if (llList2Integer(dependencyList, i) == linkno) {
                    //  Add this component as a child
                    children += [ i + 1 ];
                    //  Add its children, and theirs
                    children += flGetCompChildren(i + 1);
                }
            }
        }
        return llListSort(children, 1, TRUE);
    }

    //  flMechCheckLink  --  Validate component link number

    integer flMechCheckLink(integer linkno) {
        if ((linkno < 1) || (linkno > llGetListLength(dependencyList))) {
            llOwnerSay("Mechanisms: link number " + (string) linkno + " invalid.");
            return FALSE;
        }
        return TRUE;
    }

    /*          ************************************************
                *                                              *
                *             Fourmilab Mechanisms             *
                *           End Client-Side Interface          *
                *                                              *
                ************************************************  */

    //  createMarbles  --  Create marbles from inventory.  */

    createMarbles() {
        integer i;
        integer n = llGetListLength(marbles);
        //  No need for llGetRoot... since we're in the root prim
        vector org = llGetPos();
        rotation rot = llGetRot();

        for (i = 0; i < n; i += 2) {
            integer colour =  llList2Integer(marbles, i);
            if (colour > maxColour) {
                maxColour = colour;
            }
            llRezObject("Marble",
                        (llList2Vector(marbles, i + 1) * rot) + org,
                        ZERO_VECTOR, rot,
                        (channelUniq * 10) + colour);
        }
    }

    //  addMarbles  --  Add new marbles from thin air

    addMarbles(integer howMany) {
        integer i;
        vector org = llGetPos();
        rotation rot = llGetRot();
        list tableori = llGetLinkPrimitiveParams(tiltLink,
                            [ PRIM_POSITION, PRIM_ROTATION ]);
        //  Transformation from table to region co-ordinates
        rotation trot = rot * llList2Rot(tableori, 1);
        vector m0 = llList2Vector(marbles, 1);
        float m0z = m0.z;
        float mOffset = 0.25;
        rotation k90deg = llAxisAngle2Rot(<0, 0, 1>, PI_BY_TWO);
        integer rotor = 0;
        vector mwhere = <0, mOffset, m0z>;
        if (maxColour < 0) {
            //  Start with red for first marble
            maxColour = 0;
        }

        for (i = 0; i < howMany; i++) {
            maxColour++;
            integer colour = maxColour % 10;
            vector mpos = (mwhere * trot) + org;
            llRezObject("Marble",
                        mpos,
                        ZERO_VECTOR, trot,
                        (channelUniq * 10) + colour);
            rotor++;
            mwhere *= k90deg;
            if (rotor >= 4) {
                rotor = 0;
                mwhere += <0, mOffset, 0>;
            }
        }
    }

    /*  fixArgs  --  Transform command arguments into canonical form.
                     All white space within vector and rotation brackets
                     is elided so they will be parsed as single arguments.  */

    string fixArgs(string cmd) {
        cmd = llStringTrim(cmd, STRING_TRIM);
        integer l = llStringLength(cmd);
        integer inbrack = FALSE;
        integer i;
        string fcmd = "";

        for (i = 0; i < l; i++) {
            string c = llGetSubString(cmd, i, i);
            if (inbrack && ((c == ">") || (c == "}"))) {
                inbrack = FALSE;
            }
            if ((c == "<") || (c == "{")) {
                inbrack = TRUE;
            }
            if (!((c == " ") && inbrack)) {
                fcmd += c;
            }
        }
        return fcmd;
    }

    //  abbrP  --  Test if string matches abbreviation

    integer abbrP(string str, string abbr) {
        return abbr == llGetSubString(str, 0, llStringLength(abbr) - 1);
    }

    //  onOff  --  Parse an on/off parameter

    integer onOff(string param) {
        if (abbrP(param, "on")) {
            return TRUE;
        } else if (abbrP(param, "of")) {
            return FALSE;
        } else {
            tawk("Error: please specify on or off.");
            return -1;
        }
    }

    //  randVec  --  Generate a random unit vector

    vector randVec() {
        /*  Random unit vector by Marsaglia's method:
            Marsaglia, G. "Choosing a Point from the Surface
            of a Sphere." Ann. Math. Stat. 43, 645-646, 1972.  */
        integer outside = TRUE;

        while (outside) {
            float x1 = 1 - llFrand(2);
            float x2 = 1 - llFrand(2);
            if (((x1 * x1) + (x2 * x2)) < 1) {
                outside = FALSE;
                float x = 2 * x1 * llSqrt(1 - (x1 * x1) - (x2 * x2));
                float y = 2 * x2 * llSqrt(1 - (x1 * x1) - (x2 * x2));
                float z = 1 - 2 * ((x1 * x1) + (x2 * x2));
                return < x, y, z >;
            }
        }
        return ZERO_VECTOR;         // Can't happen, but idiot compiler errors otherwise
    }

    //  processCommand  --  Process a command

    integer processCommand(key id, string message) {

        if (!checkAccess(id)) {
            llRegionSayTo(id, PUBLIC_CHANNEL,
                "You do not have permission to control this object.");
            return FALSE;
        }

        whoDat = id;            // Direct chat output to sender of command

        if (llGetListLength(linkNames) == 0) {
            tawk("Loading mechanism configuration: please wait.");
            return FALSE;
        }

        /*  If echo is enabled, echo command to sender unless
            prefixed with "@".  */

        integer echoCmd = TRUE;
        if (llGetSubString(llStringTrim(message, STRING_TRIM_HEAD), 0, 0) == "@") {
            echoCmd = FALSE;
            message = llGetSubString(llStringTrim(message, STRING_TRIM_HEAD), 1, -1);
        }
        if (echo && echoCmd) {
            string prefix = ">> /" + (string) commandChannel + " ";
            tawk(prefix + message);             // Echo command to sender
        }

        string lmessage = fixArgs(llToLower(message));
        list args = llParseString2List(lmessage, [ " " ], []);    // Command and arguments
        integer argn = llGetListLength(args);       // Number of arguments
        string command = llList2String(args, 0);    // The command
        string sparam = llList2String(args, 1);     // First argument, for convenience

        //  Access who                  Restrict chat command access to public/group/owner

        if (abbrP(command, "ac")) {
            string who = sparam;

            if (abbrP(who, "p")) {          // Public
                restrictAccess = 0;
            } else if (abbrP(who, "g")) {   // Group
                restrictAccess = 1;
            } else if (abbrP(who, "o")) {   // Owner
                restrictAccess = 2;
            } else {
                tawk("Unknown access restriction \"" + who +
                    "\".  Valid: public, group, owner.\n");
                return FALSE;
            }

        //  Boot                    Reset the script to initial settings

        } else if (abbrP(command, "bo")) {
            llResetScript();

        //  Calc                    Submit command to the calculator

        } else if (abbrP(command, "ca")) {
            llMessageLinked(LINK_THIS, LM_CA_COMMAND, message, id);

        /*  Channel n               Change command channel.  Note that
                                    the channel change is lost on a
                                    script reset.  */

        } else if (abbrP(command, "ch")) {
            integer newch = (integer) sparam;
            if ((newch < 2)) {
                tawk("Invalid channel " + (string) newch + ".");
                return FALSE;
            } else {
                llListenRemove(commandH);
                commandChannel = newch;
                commandH = llListen(commandChannel, "", NULL_KEY, "");
                tawk("Listening on /" + (string) commandChannel);
            }

        //  Clear                   Clear chat for debugging

        } else if (abbrP(command, "cl")) {
            tawk("\n\n\n\n\n\n\n\n\n\n\n\n\n");

        //  Help                        Give help information

        } else if (abbrP(command, "he")) {
            llGiveInventory(id, helpFileName);      // Give requester the User Guide notecard

        //  Move linkno <x,y,z> speed dist

        } else if (abbrP(command, "mo")) {
            integer linkno = (integer) sparam;
            vector offset = (vector) llList2String(args, 2);
            float speed = (float) llList2String(args, 3);
            float dist = (float) llList2String(args, 4);

            if (argn == 2) {
                //  Query motion
                tawk("Motion " + (string) linkno + "  " + ef(llList2CSV(flGetCompMotion(linkno))));
            } else if ((argn < 5) || (speed == 0)) {
                flSetCompMotion(linkno, ZERO_VECTOR, 0, 0);
            } else {
                flSetCompMotion(linkno, offset, speed, dist);
            }

        //  Panic [ save ]              Restore initial positions and locations

        } else if (abbrP(command, "pa")) {
            tilting = FALSE;
            llSetTimerEvent(0);
            integer save = abbrP(sparam, "sa");
            flMechPanic(save);
            if (save) {
                llRegionSay(marbleChan, "WHERE," + (string) llGetPos());
            } else {
                llRegionSay(marbleChan, "PANIC");
            }

        //  Populate [ extinction ]     Create/destroy marbles

        } else if (abbrP(command, "po")) {
            integer n;

            if (abbrP(sparam, "ex")) {
                llRegionSay(marbleChan, "Q?+:$$");
            } else if ((n = (integer) sparam) > 0) {
                addMarbles(n);
            } else {
                createMarbles();
            }

        //  RL linkno <axis> angle      Rotate component by angle around axis

        } else if (abbrP(command, "rl")) {
            integer linkno = (integer) sparam;
            if (flMechCheckLink(linkno)) {
                vector axis = llVecNorm((vector) llList2String(args, 2));
                float angle = (float) llList2String(args, 3);
                string lname = flGetCompName(linkno);
                rotation curot = flGetCompRot(linkno);
                tawk("Link " + (string) linkno + " (" + lname + ") current rot " + efr(curot) + " (par)");
                rotation nurot = llEuler2Rot((axis * (((float) angle) * DEG_TO_RAD))) * curot;
                tawk("  New rot " + efr(nurot) + " (par)");
                flSetCompRot(linkno, nurot);
                return TRUE;
            }
            return FALSE;

        //  Set                     Set parameter

        } else if (abbrP(command, "se")) {
            string svalue = llList2String(args, 2);

            //  Set angles degrees/radians  Set angle input to degrees or radians

            if (abbrP(sparam, "an")) {
                if (abbrP(svalue, "d")) {
                    angleScale = DEG_TO_RAD;
                } else if (abbrP(svalue, "r")) {
                    angleScale = 1;
                } else {
                    tawk("Invalid set angle.  Valid: degree, radian.");
                }

            //  Set trace on/off

            } else if (abbrP(sparam, "tr")) {
                trace = onOff(svalue);
                flMechSettings(trace, FALSE);

            //  Set volume n

            } else if (abbrP(sparam, "vo")) {
                volume = (float) svalue;

            } else {
                tawk("Invalid.  Set angles/trace/volume");
                return FALSE;
            }

        //  Spin linkno <x,y,z> spinrate gain [ limit ]

        } else if (abbrP(command, "sp")) {
            integer linkno = (integer) sparam;
            vector axis = (vector) llList2String(args, 2);
            float spinrate = (float) llList2String(args, 3);    // Spinrate radians/second
            float gain = (float) llList2String(args, 4);
            float limit = 0;
            if (argn >= 6) {
                limit = ((float) llList2String(args, 5)) * angleScale;
            }

            if (argn == 2) {
                //  Query spin
                tawk("Spin " + (string) linkno + "  " + ef(llList2CSV(flGetCompOmega(linkno))));
            } else if ((argn < 5) || (spinrate == 0)) {
                flSetCompOmega(linkno, ZERO_VECTOR, 0, 0, 0);
            } else {
                flSetCompOmega(linkno, axis, spinrate, gain, limit);
            }

        //  Status [ extended ]

        } else if (abbrP(command, "st")) {
            integer extended = abbrP(sparam, "ex");

            integer mFree = llGetFreeMemory();
            integer mUsed = llGetUsedMemory();
            tawk(llGetScriptName() + " status:\n" +
                    "  Script memory.  Free: " + (string) mFree +
                    "  Used: " + (string) mUsed + " (" +
                    (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
            );
            flMechStatus(extended, whoDat);

        //  Tilt                            Start/stop table tilting

        } else if (abbrP(command, "ti")) {
            if (!tilting) {
                tiltLink = flGetCompLink("NS Arm base");
                tiltRotOrig = flGetCompRot(tiltLink);  // Save original channel rotation
                tiltRotTo = tiltRotFrom = tiltRotOrig;
                vector mechScale = llGetScale();
                mechScale.z = 0;
                //  mechRad is used to detect marbles falling off the mechanism
                float mechRad = (llVecMag(mechScale) / 2) * 1.1;
                list origloc = llGetLinkPrimitiveParams(tiltLink,
                            [ PRIM_POSITION, PRIM_ROTATION ]) +
                            [ llGetRot(), mechRad ];
                tiltOrigRot = ZERO_ROTATION / llList2Rot(origloc, 1);
                llRegionSay(marbleChan, "ORIGIN," +
                    (string) llList2CSV(origloc));
                tilting = TRUE;
                llSetTimerEvent(0.1);
            } else {
                tilting = FALSE;
                llSetTimerEvent(0);
                processCommand(whoDat, "@Panic");
            }

        //  Trans linkno <x, y, z>      Translate linkno by <x, y, z>

        } else if (abbrP(command, "tr")) {
            integer which = (integer) sparam;
            vector where = flGetCompPos(which);
            flSetCompPos(which, where + (vector) llList2String(args, 2));

        } else {
            tawk("Huh?  \"" + message + "\" undefined.  Chat /" +
                (string) commandChannel + " help for instructions.");
            return FALSE;
        }
        return TRUE;
    }

    default {

        on_rez(integer n) {
            createMarbles();            // Create initial marbles
        }

        state_entry() {
//if (commandChannel < 1000) {
//    //  If special command channel for testing, show as floating text
    llSetText("/" + (string) commandChannel, <0, 1, 0>, 1);
//} else {
//    llSetText("", ZERO_VECTOR, 0);
//}
            whoDat = owner = llGetOwner();

            /*  Generate a "unique" channel for communicating with
                the marbles.  This is intended to ensure that
                messages we send to our own marbles are received
                only by them and not by marbles belonging to
                other mechanisms in the region.  We hack together
                a large negative channel number which incorporates
                hex digits from our UUID and that of our owner.  Note
                that we can't use anything ephemeral such as the
                time, since the channel number must persist across
                script resets.  */

            channelUniq =
                ((((integer) ("0x" + ((string) llGetOwner()))) & 0xFFFFF) ^
                 (((integer) ("0x" + ((string) llGetKey()))) & 0xFFFFF)) % 100000;
            marbleChan = marbleChan ^ (channelUniq << 7);

            //  Start listening on the command chat channel
            commandH = llListen(commandChannel, "", NULL_KEY, "");
            llOwnerSay("Listening on /" + (string) commandChannel);

            //  Initialise the mechanisms module
            flMechInit(owner);
        }

        /*  The listen event handler processes messages from
            our chat control channel.  */

        listen(integer channel, string name, key id, string message) {
            processCommand(id, message);
        }

        /*  The link_message() event receives commands from other scripts
            script and passes them on to the script processing functions
            within this script.  */

        link_message(integer sender, integer num, string str, key id) {
//tawk("Mechanism link message sender " + (string) sender + "  num " + (string) num + "  str " + str + "  id " + (string) id);

            //  LM_ME_CONFIG (127): Mechanism configuration

            if (num == LM_ME_CONFIG) {
                flMechConfig(str);

            //  LM_ME_COMPLETE (131): Translate/rotate complete

            } else if (num == LM_ME_COMPLETE) {
                //  Tilt complete: notify marbles we're done
                llRegionSay(marbleChan, "TILTED");
           }
        }

        //  Timer event

        timer() {
            /*  The timer controls tilting of the table.  When
                the table tilts, a carefully choreographed sequence
                of events must take place to avoid losing our
                marbles.

                First of all, compute the new tilt of the table.
                This allows us to prepare the flSetCompRot() to
                actually move it, but we can't yet do that.

                Next, we need to inform the marbles that we're going
                to move.  We send them a TILTING message with the
                difference between the current and new rotations.
                Upon receiving this message, they turn off physics
                (to avoid falling through the bottom of the table
                as it is in motion, which Second Life's physics engine
                will miss) and move themselves (with physics off, using
                llSetPos()) to their corresponding positions on the
                newly tilted table.  At this point, they leave physics
                off.

                Now we can issue the flSetCompRot() to actually move the
                table.  This is performed in the Mechanism script and
                is not only asynchronous but can take a while, as it must
                move all of the child components of the table.  When this
                is finally complete, we will receive the LM_ME_COMPLETE
                message from Mechanism indicating it's done.

                Only then may we send a TILTED message to the marbles to
                inform them the table is now in position and they're
                free to re-enable physics and start rolling freely.  */

            if (tilting) {
                //  Compute new tilt of table
                tiltRotFrom = tiltRotTo;
                tiltAxis = randVec();
                tiltRotTo = llAxisAngle2Rot(tiltAxis,
                    tiltMax * DEG_TO_RAD) * tiltRotOrig;

                if (volume > 0) {
                    llPlaySound("Crank1", volume);
                }

                //  Notify marbles tilt is underway
                llRegionSay(marbleChan, "TILTING," + (string) tiltRotFrom +
                    "," + (string) tiltRotTo);

                //  Initiate the tilt of the table
                flSetCompRot(tiltLink, tiltRotTo);
            }
            llSetTimerEvent(tiltPause);
        }

        //  Touch event

        touch_start(integer n) {
            processCommand(llDetectedKey(0), "Tilt");
        }
    }
