    /*

                    Fourmilab Gimbal Mechanism

        This is a demonstration of Fourmilab Mechanisms.  It is a model of
        three nested gimbal rings, which are defined as a hierarchical
        mechanism.  Commands allow positioning the rings independently
        and spinning them using omega rotation.

    */

    key owner;                      // Owner UUID

    integer commandChannel = 1872;  // Command channel in chat (birth year of Heath Robinson)
    integer commandH;               // Handle for command channel
    key whoDat = NULL_KEY;          // Avatar who sent command
    integer restrictAccess = 0;     // Access restriction: 0 none, 1 group, 2 owner
    integer echo = TRUE;            // Echo chat and script commands ?

    float angleScale = DEG_TO_RAD;  // Scale factor for angles
    integer trace = FALSE;          // Trace operation ?
    integer configured = FALSE;     // Is configuration loaded ?

    //  Script processing

    integer scriptActive = FALSE;   // Are we reading from a script ?
    integer scriptSuspend = FALSE;  // Suspend script execution for asynchronous event
    integer scriptMotion = FALSE;   // Script suspended while motion in progress
    integer scriptHandle;           // Handle for which we suspended script

    string helpFileName = "Fourmilab Mechanisms User Guide";

    //  Link messages

    //  Calculator messages

//  integer LM_CA_INIT = 210;       // Initialise script
//  integer LM_CA_RESET = 211;      // Reset script
//  integer LM_CA_STAT = 212;       // Print status
    integer LM_CA_COMMAND = 213;    // Submit calculator command
    integer LM_CA_RESULT = 214;     // Report calculator result

    //  Command processor messages

    integer LM_CP_COMMAND = 223;    // Process command

    //  Script Processor messages
    integer LM_SP_INIT = 50;            // Initialise
    integer LM_SP_RESET = 51;           // Reset script
    integer LM_SP_STAT = 52;            // Print status
    integer LM_SP_RUN = 53;             // Enqueue script as input source
    integer LM_SP_GET = 54;             // Request next line from script
    integer LM_SP_INPUT = 55;           // Input line from script
    integer LM_SP_EOF = 56;             // Script input at end of file
    integer LM_SP_READY = 57;           // Script ready to read
    integer LM_SP_ERROR = 58;           // Requested operation failed

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

    string eff(float f) {
        return ef((string) f);
    }

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
            tawk("Mechanisms: link number " + (string) linkno + " invalid.");
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

    /*  linkNick  --  Translate nicknames of components to link.
                      This is just a hack so users and scripts
                      don't need to remember and specify commonly
                      used links by number.  */

    integer linkNick(string n) {
        string ring = " Ring";

        if ((n == "x") || (n == "y") || (n == "z")) {
            return flGetCompLink(llToUpper(n) + ring);
        } else if (n == "mech") {
            return flGetCompLink("Gimbals");
        }
        return (integer) n;
    }

/*
    //  eOnOff  --  Edit an on/off parameter

    string eOnOff(integer p) {
        if (p) {
            return "on";
        }
        return "off";
    }
*/

    //  genRot  --  Perform general incremental component rotation

    genRot(string compname, vector axis, string angle) {
        integer linkno = flGetCompLink(compname);
        rotation curot = flGetCompRot(linkno);
        if (trace) {
            tawk("Link " + (string) linkno + " current rot " + efr(curot));
        }
        rotation nurot = llEuler2Rot((axis * (((float) angle) * DEG_TO_RAD))) * curot;
        if (trace) {
            tawk("  New rot " + efr(nurot));
        }
        scriptHandle = flSetCompRot(linkno, nurot);
////tawk("flSetCompRot: link " + (string) linkno + "  handle " + (string) scriptHandle);
        scriptSuspend = TRUE;               // Suspend for completion if in script
    }

    /*  scriptResume  --  Resume script execution when asynchronous
                          command completes.  */

    scriptResume() {
//tawk("scriptResume active " + (string) scriptActive + " suspend " + (string) scriptSuspend);
        if (scriptActive) {
            if (scriptSuspend) {
                scriptSuspend = FALSE;
                llMessageLinked(LINK_THIS, LM_SP_GET, "", NULL_KEY);
                if (trace) {
                    tawk("Script resumed.");
                }
            }
        }
    }

    //  processCommand  --  Process a command

    integer processCommand(key id, string message, integer fromScript) {

        if (!checkAccess(id)) {
            llRegionSayTo(id, PUBLIC_CHANNEL,
                "You do not have permission to control this object.");
            return FALSE;
        }

        whoDat = id;            // Direct chat output to sender of command

        if (!configured) {
            tawk("Mechanism configuration not loaded.  Please wait.");
            return FALSE;
        }

        /*  If echo is enabled, echo command to sender unless
            prefixed with "@".  The command is prefixed with ">>"
            if entered from chat or "++" if from a script.  */

        integer echoCmd = TRUE;
        if (llGetSubString(llStringTrim(message, STRING_TRIM_HEAD), 0, 0) == "@") {
            echoCmd = FALSE;
            message = llGetSubString(llStringTrim(message, STRING_TRIM_HEAD), 1, -1);
        }
        if (echo && echoCmd) {
            string prefix = ">> ";
            if (fromScript) {
                prefix = "++ ";
            }
            tawk(prefix + message);                 // Echo command to sender
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

        //  Echo text                   Send text to sender

        } else if (abbrP(command, "ec")) {
            integer dindex = llSubStringIndex(lmessage, command);
            integer doff = llSubStringIndex(llGetSubString(lmessage, dindex, -1), " ");
            string emsg = " ";
            if (doff >= 0) {
                emsg = llStringTrim(llGetSubString(message, dindex + doff + 1, -1), STRING_TRIM_TAIL);
            }
            tawk(emsg);

        //  Help                        Give help information

        } else if (abbrP(command, "he")) {
            llGiveInventory(id, helpFileName);      // Give requester the User Guide notecard

        //  Move linkno <x,y,z> speed dist

        } else if (abbrP(command, "mo")) {
            integer linkno = linkNick(sparam);
            vector offset = (vector) llList2String(args, 2);
            float speed = (float) llList2String(args, 3);
            float dist = (float) llList2String(args, 4);

            if (argn == 2) {
                //  Query motion
                tawk("Motion " + (string) linkno + "  " + ef(llList2CSV(flGetCompMotion(linkno))));
            } else if ((argn < 5) || (speed == 0)) {
                integer hand = flSetCompMotion(linkno, ZERO_VECTOR, 0, 0);
////tawk("flSetCompMotion: Stop link " + (string) linkno + "  handle " + (string) hand);
            } else {
                integer hand = flSetCompMotion(linkno, offset, speed, dist);
////tawk("flSetCompMotion: Start link " + (string) linkno + "  handle " + (string) hand);
                scriptMotion = scriptSuspend = TRUE;
            }

        //  Panic [ gently ]        Restore initial positions and locations

        } else if (abbrP(command, "pa")) {
            flMechPanic(abbrP(sparam, "sa"));
            if ((argn < 2) || (!abbrP(sparam, "ge"))) {
                //  Terminate any running script
                llMessageLinked(LINK_THIS, LM_SP_INIT, "", id);
            }

        /*  The RX, RY, and RZ commands are shortcuts to facilitate testing
            with the gimbal model.  They perform incremental rotations on
            the three axis gimbal rings using the general flGetCompRot() and
            flSetCompRot() functions.  */

        //  RX ang                      Rotate X ring

        } else if (abbrP(command, "rx")) {
            genRot("X Ring", <0, 0, 1>, sparam);

        //  RY ang                      Rotate Y ring

        } else if (abbrP(command, "ry")) {
            genRot("Y Ring", <0, 1, 0>, sparam);

        //  RZ ang                      Rotate Z ring

        } else if (abbrP(command, "rz")) {
            genRot("Z Ring", <0, 1, 0>, sparam);

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

                } else {
                    tawk("Invalid.  Set angles/trace");
                    return FALSE;
                }

        //  Spin linkno <x,y,z> spinrate gain [ limit ]

        } else if (abbrP(command, "sp")) {
            integer linkno = linkNick(sparam);
            vector axis = (vector) llList2String(args, 2);
            float spinrate = (float) llList2String(args, 3);    // Spinrate radians/second
            float gain = (float) llList2String(args, 4);

            if (argn == 2) {
                //  Query spin
                tawk("Spin " + (string) linkno + "  " + ef(llList2CSV(flGetCompOmega(linkno))));
            } else if ((argn < 5) || (spinrate == 0)) {
                integer hand = flSetCompOmega(linkno, ZERO_VECTOR, 0, 0, 0);
////tawk("flSetCompOmega: Stop link " + (string) linkno + "  handle " + (string) hand);
            } else {
                float limit = 0;
                if (argn > 5) {
                    limit = ((float) llList2String(args, 5)) * DEG_TO_RAD;
                }
                integer hand = flSetCompOmega(linkno, axis, spinrate, gain, limit);
////tawk("flSetCompOmega: Start link " + (string) linkno + "  handle " + (string) hand);
                if (limit > 0) {
                    scriptMotion = scriptSuspend = TRUE;
                }
//tawk("Spinning " + (string) linkno + " limit " + (string) limit);
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
            //  Request status of Script Processor
            llMessageLinked(LINK_THIS, LM_SP_STAT, "", id);
            flMechStatus(extended, whoDat);

        //  Trans linkno <x, y, z>      Translate linkno by <x, y, z>

        } else if (abbrP(command, "tr")) {
            integer which = linkNick(sparam);
            vector where = flGetCompPos(which);
            scriptHandle = flSetCompPos(which, where + (vector) llList2String(args, 2));
////tawk("flSetCompPos: link " + (string) which + "  handle " + (string) scriptHandle);
            scriptSuspend = TRUE;

        //     Handled by other scripts
        //  Script                  Script commands

        } else if (abbrP(command, "sc")) {
            llMessageLinked(LINK_THIS, LM_CP_COMMAND,
                llList2Json(JSON_ARRAY, [ message, lmessage ] + args), whoDat);

        } else {
            tawk("Huh?  \"" + message + "\" undefined.  Chat /" +
                (string) commandChannel + " help for instructions.");
            return FALSE;
        }
        return TRUE;
    }

    default {

        on_rez(integer n) {
            llResetScript();
        }

        state_entry() {
//if (FALSE && commandChannel < 1000) {
    //  If special command channel for testing, show as floating text
    llSetText("/" + (string) commandChannel, <0, 1, 0>, 1);
//} else {
//    llSetText("", ZERO_VECTOR, 0);
//}

            whoDat = owner = llGetOwner();

            //  Start listening on the command chat channel
            commandH = llListen(commandChannel, "", NULL_KEY, "");
            llOwnerSay("Listening on /" + (string) commandChannel);

            //  Initialise the mechanisms module
            flMechInit(owner);
        }

        /*  The listen event handler processes messages from
            our chat control channel.  */

        listen(integer channel, string name, key id, string message) {
            processCommand(id, message, FALSE);
        }

        /*  The link_message() event receives commands from other scripts
            script and passes them on to the script processing functions
            within this script.  */

        link_message(integer sender, integer num, string str, key id) {

            //  Script Processor Messages

            //  LM_SP_READY (57): Script ready to read

            if (num == LM_SP_READY) {
                scriptActive = TRUE;
                llMessageLinked(LINK_THIS, LM_SP_GET, "", id);  // Get the first line

            //  LM_SP_INPUT (55): Next executable line from script

            } else if (num == LM_SP_INPUT) {
                if (str != "") {                // Process only if not hard EOF
                    scriptSuspend = FALSE;
                    integer stat = processCommand(id, str, TRUE); // Some commands set scriptSuspend
                    if (stat) {
                        if (!scriptSuspend) {
                            llMessageLinked(LINK_THIS, LM_SP_GET, "", id);
                        }
//else { tawk("Script suspend."); }
                    } else {
                        //  Error in script command.  Abort script input.
                        scriptActive = scriptSuspend = FALSE;
                        llMessageLinked(LINK_THIS, LM_SP_INIT, "", id);
                        tawk("Script terminated.");
                    }
                }

            //  LM_SP_EOF (56): End of file reading from script

            } else if (num == LM_SP_EOF) {
                scriptActive = FALSE;           // Mark script input complete

            //  LM_SP_ERROR (58): Error processing script request

            } else if (num == LM_SP_ERROR) {
                llRegionSayTo(id, PUBLIC_CHANNEL, "Script error: " + str);
                scriptActive = scriptSuspend = FALSE;
                llMessageLinked(LINK_THIS, LM_SP_INIT, "", id);

            //  LM_ME_CONFIG (127): Mechanism configuration

            } else if (num == LM_ME_CONFIG) {
                flMechConfig(str);
                configured = TRUE;

            //  LM_ME_OMEGALIMIT (129): Rotation limit reached

            } else if (num == LM_ME_OMEGALIMIT) {
                if (trace) {
                    tawk(flGetCompName((integer) str) + ": Spin complete.");
                }
////tawk("LM_ME_OMEGALIMIT  " + str);
                scriptMotion = FALSE;
                scriptResume();

            //  LM_ME_COMPLETE (131): Translate/rotate complete

            } else if (num == LM_ME_COMPLETE) {
                if (trace) {
                    integer op = (integer) llList2String(llCSV2List(str), 0);
                    string sop = "Rotation ";
                    if (op == LM_ME_TRANSLATE) {
                        sop = "Translation ";
                    }
                    tawk(sop + " complete.");
                }
////tawk("LM_ME_COMPLETE  " + str);
                if (!scriptMotion) {
                    scriptResume();
                }

            //  LM_ME_MOVELIMIT (132): Motion complete

            } else if (num == LM_ME_MOVELIMIT) {
                if (trace) {
                    tawk(flGetCompName((integer) str) + ": Motion complete.");
                }
////tawk("LM_ME_MOVELIMIT  " + str);
                scriptMotion = FALSE;
                scriptResume();
            }
        }

        //  The touch event is a short-cut to run the Demonstration script

        touch_start(integer howmany) {
            processCommand(llDetectedKey(0), "Script run Demonstration", TRUE);
        }
    }
