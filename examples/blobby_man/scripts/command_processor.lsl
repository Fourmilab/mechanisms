    /*

                        Fourmilab Blobby Man

                      Auxiliary Command Processor

        This script implements commands which have been removed from
        the main script to avoid memory exhaustion crises.

    */

    key owner;                      // Owner UUID
    key whoDat = NULL_KEY;          // Avatar who sent command

    float angleScale = DEG_TO_RAD;  // Scale factor for angles
    list calcResult;                // Last result from calculator

    list jointUndo = [ ];           // Joint command undo stack

    //  Link messages

    //  Command processor messages
    integer LM_CP_COMMAND = 223;    // Process command

    //  Calculator messages
    integer LM_CA_RESULT = 214;     // Report calculator result

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
//string ef(string s) { return s; }

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
//  integer LM_ME_INIT = 120;       // Initialise mechanisms
//  integer LM_ME_RESET = 121;      // Reset mechanisms script
//  integer LM_ME_STAT = 122;       // Print status
    integer LM_ME_TRANSLATE = 123;  // Translate component
    integer LM_ME_ROTATE = 124;     // Rotate component
    integer LM_ME_SPIN = 125;       // Spin (omega rotate) component
    integer LM_ME_PANIC = 126;      // Reset components to initial state
    integer LM_ME_CONFIG = 127;     // Return configuration to client script
//  integer LM_ME_SETTINGS = 128;   // Set parameters in mechanisms module
//  integer LM_ME_OMEGALIMIT = 129; // Omega rotation reached limit
//  integer LM_ME_CHANGED = 130;    // Position/rotation change report to compiler
//  integer LM_ME_COMPLETE = 131;   // Confirm component update complete
//  integer LM_ME_MOVELIMIT = 132;  // Move limit reached
    integer LM_ME_MOVE = 133;       // Move component
//  integer LM_ME_ROTSTEP = 134;    // Rotation step by spin command
//  integer LM_ME_TRANSTEP = 135;   // Translation step by move command

    integer flMechHandle = -982449724;  // Request handle base

/*
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
*/

    //  flMechConfig  --  Process configuration message

    flMechConfig(string msg) {
        list ml = llJson2List(msg);
        integer ncomps = llList2Integer(ml, 0);
        linkNames = llList2List(ml, 1, (1 + ncomps) - 1);
        dependencyList = llList2List(ml, ncomps + 1, -1);
    }

/*
    //  flMechSettings  --  Set mechanisms module modes

    flMechSettings(integer traceMode, integer compile) {
        llMessageLinked(LINK_THIS, LM_ME_SETTINGS,
            llList2CSV([ traceMode, compile ]), NULL_KEY);
    }
*/

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

/*
    //  flGetCompLink  --  Get link number of component from name, -1 if not found

    integer flGetCompLink(string cname) {
        integer l = llListFindList(linkNames, [ cname ]);
        if (l >= 0) {
            l++;
        }
        return l;
    }
*/

    //  flGetCompName  --  Get component name from link number

    string flGetCompName(integer linkno) {
        if (flMechCheckLink(linkno)) {
            return llList2String(linkNames, linkno - 1);
        }
        return "";
    }

/*
    //  flGetCompParent  --  Return link number of component's parent

    integer flGetCompParent(integer linkno) {
        if (flMechCheckLink(linkno)) {
            return llList2Integer(dependencyList, linkno - 1);
        }
        return -1;
    }
*/

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

    //  jLink  --  Look up joint link number by informal name

    integer jLink(string jname) {
        string j = "joint: " + jname;

        integer i;
        integer n = llGetListLength(linkNames);
        //  Try name with Joint: prefix
        for (i = 0; i < n; i++) {
            if (j == llToLower(llList2String(linkNames, i))) {
                return i + 1;
            }
        }
        //  Try name directly
        for (i = 0; i < n; i++) {
            if (jname == llToLower(llList2String(linkNames, i))) {
                return i + 1;
            }
        }
        return -1;
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
            /*  Perform substitution for "$", specifying last result from
                calculator.  Notice that we must re-scan the result to
                elide spaces within vectors and quaternions.  */
            if ((c == "$") && (llGetListLength(calcResult) > 0)) {
                string ncmd = "";
                if (i > 0) {
                    ncmd = llGetSubString(cmd, 0, i - 1);
                }
                ncmd += llList2String(calcResult, 1);
                if (i < (l - 1)) {
                    ncmd += llGetSubString(cmd, i + 1, -1);
                }
                cmd = ncmd;
                c = llGetSubString(cmd, i, i);
                l = llStringLength(cmd);
            }
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

    //  processAuxCommand  --  Process a command

    integer processAuxCommand(key id, list args) {

        whoDat = id;            // Direct chat output to sender of command

        string message = llList2String(args, 0);
        string lmessage = fixArgs(llToLower(message));
        args = llParseString2List(lmessage, [ " " ], []);   // Command and arguments
        integer argn = llGetListLength(args);       // Number of arguments
        string command = llList2String(args, 0);    // The command
        string sparam = llList2String(args, 1);     // First argument, for convenience

        //  Clear                   Clear chat for debugging

        if (abbrP(command, "cl")) {
            tawk("\n\n\n\n\n\n\n\n\n\n\n\n\n");

        //  Help [ blobby/calculator/mechanisms ]    Request help notecard

        } else if (abbrP(command, "he")) {
            integer holped = TRUE;
            if (argn >= 2) {
                string fl = "Fourmilab ";
                string ug = " User Guide";
                if (abbrP(sparam, "bl")) {
                    llGiveInventory(id, fl + "Blobby Man" + ug);
                } else if (abbrP(sparam, "ca")) {
                    llGiveInventory(id, fl + "Calculator" + ug);
                } else if (abbrP(sparam, "me")) {
                    llGiveInventory(id, fl + "Mechanisms" + ug);
                } else {
                    tawk("No help on that available.");
                    holped = FALSE;
                }
            } else {
                holped = FALSE;
            }
            if (!holped) {
                tawk("Available help (please specify which you require):\n" +
                     "  blobby        Blobby Man\n" +
                     "  calculator    Calculator\n" +
                     "  mechanisms    Mechanisms");
            }

        //  Joint                   Joint manipulation commands

        } else if (abbrP(command, "jo")) {

                //  Joint list [ name ]

                if (abbrP(sparam, "li")) {
                    if (argn < 3) {
                        //  List joint names and positions
                        tawk("Joint names:\n" +
                             "                 head\n" +
                             "                 neck\n" +
                             "        lCollar      rCollar\n" +
                             "   lShldr    chest           rShldr\n" +
                             "lForeArm  abdomen   rForeArm\n" +
                             "  lHand       Hips           rHand\n" +
                             "        lThigh         rThigh\n" +
                             "        lShin          rShin\n" +
                             "        lFoot          rFoot");
                    } else {
                        //  List all joints and orientations
                        string which = llList2String(args, 2);
                        if (which == "*") {
                            //  Sort joints in alphabetic order
                            list joints = llListSort(linkNames, 1, TRUE);
                            integer i;
                            integer n = llGetListLength(joints);

                            for (i = 0; i < n; i++) {
                                integer l = llListFindList(linkNames, [ llList2String(joints, i) ]);
                                if (l >= 0) {
                                    l++;
                                    //  It's only a joint is something is dependent upon it
                                    if (llListFindList(dependencyList, [ l ]) >= 0) {
                                        tawk(flGetCompName(l) + ": Pos " + efv(flGetCompPos(l)) +
                                            " Rot " + efr(flGetCompRot(l)));
                                    }
                                }
else { tawk("Huh?  Bogus joint name " + llList2String(joints, i)); }
                            }
                        } else {
                            //  List a single joint
                            integer jlink = jLink(llList2String(args, 2));
                            if (jlink > 0) {
                                tawk(flGetCompName(jlink) + ": Pos " + efv(flGetCompPos(jlink)) +
                                    " Rot " + efr(flGetCompRot(jlink)));
                            } else {
                                tawk("Unknown joint.  Use \"Joint list\" for names.");
                            }
                        }
                    }

                //  Joint move name <x,y,z> speed distance

                } else if (abbrP(sparam, "mo")) {
                    integer linkno = jLink(llList2String(args, 2));
                    if (linkno > 0) {
                        vector direction = (vector) llList2String(args, 3);
                        float speed = (float) llList2String(args, 4);   // Speed (metres/second)
                        float distance = 0;
                        if (argn >= 5) {
                            distance = (float) llList2String(args, 5);
                        }

                        if (argn == 3) {
                            //  Query motion
                            tawk("Motion " + (string) linkno + "  " +
                                 ef(llList2CSV(flGetCompMotion(linkno))));
                        } else {
                            jointUndo = [ "move", linkno, flGetCompPos(linkno) ] + jointUndo;
                            if ((argn < 5) || (speed == 0)) {
                                flSetCompMotion(linkno, ZERO_VECTOR, 0, 0);
                            } else {
                                flSetCompMotion(linkno, direction, speed, distance);
                            }
                        }
                    } else {
                        tawk("Unknown joint.  Use \"Joint list\" for names.");
                    }

                //  Joint rotate name <x,y,z>

                } else if (abbrP(sparam, "ro")) {
                    integer jlink = jLink(llList2String(args, 2));
                    if (jlink > 0) {
                        if (argn > 3) {
                            rotation orot = flGetCompRot(jlink);
                            jointUndo = [ "rot", jlink, orot ] + jointUndo;
                            flSetCompRot(jlink,
                                llEuler2Rot(((vector) llList2String(args, 3)) * DEG_TO_RAD) *
                                    orot);
                        } else {
                            jointUndo = [ "rot", jlink, flGetCompRot(jlink) ] + jointUndo;
                            flSetCompRot(jlink, ZERO_ROTATION);
                        }
                    } else {
                        tawk("Unknown joint.  Use \"Joint list\" for names.");
                    }

                //  Joint spin name <x,y,z> spinrate gain [ limit ]

                } else if (abbrP(sparam, "sp")) {
                    integer linkno = jLink(llList2String(args, 2));
                    if (linkno > 0) {
                        vector axis = (vector) llList2String(args, 3);
                        float spinrate = (float) llList2String(args, 4);    // Spinrate radians/second
                        float gain = (float) llList2String(args, 5);
                        float limit = 0;
                        if (argn >= 6) {
                            limit = ((float) llList2String(args, 6)) * angleScale;
                        }

                        if (argn == 3) {
                            //  Query spin
                            tawk("Spin " + (string) linkno + "  " + ef(llList2CSV(flGetCompOmega(linkno))));
                        } else {
                            jointUndo = [ "spin", linkno, flGetCompRot(linkno) ] + jointUndo;
                            if ((argn < 6) || (spinrate == 0)) {
                                flSetCompOmega(linkno, ZERO_VECTOR, 0, 0, 0);
                            } else {
                                flSetCompOmega(linkno, axis, spinrate, gain, limit);
                            }
                        }
                    } else {
                        tawk("Unknown joint.  Use \"Joint list\" for names.");
                    }

                //  Joint translate name <x,y,z>

                } else if (abbrP(sparam, "tr")) {
                    integer jlink = jLink(llList2String(args, 2));
                    if (jlink > 0) {
                        if (argn > 3) {
                            vector opos = flGetCompPos(jlink);
                            jointUndo = [ "trans", jlink, opos ] + jointUndo;
                            flSetCompPos(jlink, opos + ((vector) llList2String(args, 3)));
                        }
                    } else {
                        tawk("Unknown joint.  Use \"Joint list\" for names.");
                    }

                //  Joint undo

                } else if (abbrP(sparam, "un")) {
                    if (jointUndo != [ ]) {
                        string what = llList2String(jointUndo, 0);
                        if (what == "rot") {
                            flSetCompRot(llList2Integer(jointUndo, 1),
                                llList2Rot(jointUndo, 2));
                            jointUndo = llDeleteSubList(jointUndo, 0, 2);
                        } else if (what == "move") {
                            flSetCompMotion(llList2Integer(jointUndo, 1),   // Stop any motion in progress
                                ZERO_VECTOR, 0, 0);
llSleep(0.25);  // Dirty trick to wait for motion to halt.  Should use message
                            flSetCompPos(llList2Integer(jointUndo, 1),      // Restore previous position
                                llList2Vector(jointUndo, 2));
                            jointUndo = llDeleteSubList(jointUndo, 0, 2);
                        } else if (what == "spin") {
                            flSetCompOmega(llList2Integer(jointUndo, 1),    // Stop any spin in progress
                                 ZERO_VECTOR, 0, 0, 0);
llSleep(0.25);  // Dirty trick to wait for spin to halt.  Should use message
                            flSetCompRot(llList2Integer(jointUndo, 1),      // Restore previous rotation
                                llList2Rot(jointUndo, 2));
                            jointUndo = llDeleteSubList(jointUndo, 0, 2);
                        } else if (what == "trans") {
                            flSetCompPos(llList2Integer(jointUndo, 1),
                                llList2Vector(jointUndo, 2));
                            jointUndo = llDeleteSubList(jointUndo, 0, 2);
                        }
                    } else {
                        tawk("Nothing to undo.");
                    }

                } else {
                    tawk("Unknown joint command.  Valid: list/rotate/spin/undo.");
                }

        //  Status

        } else if (abbrP(command, "st")) {
            tawk(llGetScriptName() + " status:");

            integer mFree = llGetFreeMemory();
            integer mUsed = llGetUsedMemory();
            tawk("  Script memory.  Free: " + (string) mFree +
                    "  Used: " + (string) mUsed + " (" +
                    (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
            );
        }
        return TRUE;
    }

    default {

        on_rez(integer n) {
            llResetScript();
        }

        state_entry() {
            whoDat = owner = llGetOwner();
        }

        /*  The link_message() event receives commands from other scripts
            script and passes them on to the script processing functions
            within this script.  */

        link_message(integer sender, integer num, string str, key id) {
//tawk("Mechanism link message sender " + (string) sender + "  num " + (string) num + "  str " + str + "  id " + (string) id);

            //  LM_ME_CONFIG (127): Mechanism configuration

            if (num == LM_ME_CONFIG) {
                flMechConfig(str);

            //  LM_ME_PANIC (126): Save or restore initial condition

            } else if (num == LM_ME_PANIC) {
                if (((integer) str) == 0) {
                    //  Clear Joint undo stack on Panic
                    jointUndo = [ ];
                }

            //  LM_CA_RESULT (214): Calculator result report

            } else if (num == LM_CA_RESULT) {
                calcResult = llJson2List(str);

            //  LM_CP_COMMAND (223): Process auxiliary command

            } else if (num == LM_CP_COMMAND) {
                processAuxCommand(id, llJson2List(str));
            }
        }
    }
