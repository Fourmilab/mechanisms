    /*

                    Fourmilab Mechanisms API

        This is the client-side API for Fourmilab Mechanisms.
        Everything between the large block comments is included
        within your script which operates the mechanism.  If
        you have more than one script which interacts with
        Fourmilab Mechanisms, the API should be included in
        each such script.

        If you don't need some of the API calls in this code (for
        example, those related to omega rotation and smooth motion),
        you can comment them out to save memory in your script.

    */

    integer trace = FALSE;          // Trace operation

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

    /*  The following code should be integrated into your script
        to interface with the Fourmilab Mechanisms script.  */

    default {

        state_entry() {
            //  Initialise the mechanisms module
            flMechInit(llGetOwner());
        }

        /*  The link_message() event receives commands from other scripts
            script and passes them on to the script processing functions
            within this script.  */

        link_message(integer sender, integer num, string str, key id) {

            //  LM_ME_CONFIG (127): Mechanism configuration

            if (num == LM_ME_CONFIG) {
                flMechConfig(str);

            //  LM_ME_OMEGALIMIT (129): Rotation limit reached

            } else if (num == LM_ME_OMEGALIMIT) {
                if (trace) {
                    llOwnerSay(flGetCompName((integer) str) + ": Spin complete.");
                }

            //  LM_ME_COMPLETE (131): Translate/rotate complete

            } else if (num == LM_ME_COMPLETE) {
                if (trace) {
                    integer op = (integer) llList2String(llCSV2List(str), 0);
                    string sop = "Rotation ";
                    if (op == LM_ME_TRANSLATE) {
                        sop = "Translation ";
                    }
                    llOwnerSay(sop + " complete.");
                }

            //  LM_ME_MOVELIMIT (132): Motion complete

            } else if (num == LM_ME_MOVELIMIT) {
                if (trace) {
                    llOwnerSay(flGetCompName((integer) str) + ": Motion complete.");
                }
            }
        }
    }
