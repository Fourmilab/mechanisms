    /*
                        Fourmilab Mechanisms

                         Auxiliary Functions
    */

    key owner;                      // Owner UUID

    key whoDat = NULL_KEY;          // Avatar who sent command
    integer echo = FALSE;           // Echo chat and script commands ?

    string confNotecard = "Mechanism Configuration";    // Configuration notecard name
    string ncSource = "";           // Current notecard being read
    key ncQuery;                    // Handle for notecard query
    integer ncLine = 0;             // Current line in notecard

    integer updatePending = 0;      // Mechanism updates in progress
    list pendingHandles = [ ];      // Handles of updates in progress
    integer panicPending = FALSE;   // Panic reset when all updates complete ?

    /* IF TRACE */
    integer trace = FALSE;          // Trace operation ?
    /* END TRACE */

    /*  Omega rotations in progress are managed through the omegaList
        whose entries are as follows:
            0   Time [llGetTime()] of next incremental rotation
            1   Link number of component
            2   Time this rotation step began
            3   Axis about which component rotates
            4   Rotation rate, radians / second
            5   Gain (multiplied by rotation rate)
            6   Rotation limit, radians
            7   Handle for operation  */
    /* IF OMEGA */
    list omegaList;
    float omegaAngstep = 0.017453;          // Smallest omega rotation step (1 degree)
    integer omegaTimerPending = FALSE;      // Omega timer update pending ?
    /* END OMEGA */


    /*  Motion in progress are managed through the motionList
        whose entries are as follows:
            0   Time [llGetTime()] of next incremental motion
            1   Link number of component
            2   Time of last motion step
            3   Direction of motion
            4   Speed (metres per second)
            5   Starting position (parent co-ordinates)
            6   Distance moved so far
            7   Limit distance, metres
            8   Handle for operation  */
    /* IF MOTION */
    list motionList;                        // List of pending motions
    float motionStep = 0.1;                 // Motion time step
    integer motionTimerPending = FALSE;     // Motion timer update pending ?
    /* END MOTION */

    //  These are used to associate link names and numbers
    list linkNames;                 // Names of links in object

    /*  The dependencyList is indexed by the link number
        and contains the number of the link upon which
        that link is dependent (in other words, it moves
        rigidly along with that link).  If the link is not
        dependent upon any other prim (such as the top level
        moving part in a mechanism or a static component of
        the link set), then its dependencyList entry will be
        -1.  Any number of links may be dependent upon a single
        other link, but no link may be dependent on more than
        one parent link.  Dependencies may be chained as deeply
        as the maximum number of links permits.  */

    list dependencyList;            // Dependencies for links in object

    //  Link messages

    //  Mechanisms messages
    integer LM_ME_INIT = 120;       // Initialise mechanisms
    integer LM_ME_RESET = 121;      // Reset mechanisms script
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

    /*  Component positions and rotations for panic restore,
        saved by "Panic save".  */
    list panicRestore = [ ];

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

    /*  fixQuotes  --   Adjacent arguments bounded by those
                        beginning and ending with quotes (") are
                        concatenated into single arguments with
                        the quotes elided.  */

    list fixQuotes(list args) {
        integer i;
        integer n = llGetListLength(args);

        for (i = 0; i < n; i++) {
            string arg = llList2String(args, i);
            if (llGetSubString(arg, 0, 0) == "\"") {
                /*  Argument begins with a quote.  If it ends with one,
                    strip them and we're done.  */
                if (llGetSubString(arg, -1, -1) == "\"") {
                    args = llListReplaceList(args,
                        [ llGetSubString(arg, 1, -2) ], i, i);
                } else {
                    /*  Concatenate arguments until we find one that ends
                        with a quote, then replace the multiple arguments
                        with the concatenation.  */
                    string rarg = llGetSubString(arg, 1, -1);
                    integer looking = TRUE;
                    integer j;

                    for (j = i + 1; looking && (j < n); j++) {
                        string narg = llList2String(args, j);
                        if (llGetSubString(narg, -1, -1) == "\"") {
                            rarg += " " + llGetSubString(narg, 0, -2);
                            looking = FALSE;
                        } else {
                            rarg += " " + narg;
                        }
                    }
                    if (!looking) {
                        args = llListReplaceList(args, [ rarg ], i, j - 1);
                    }
                }
            }
        }
        return args;
    }

    integer flMechHandle = -982449724;  // Request handle base

    //  flMechInit  --  Initialise mechanisms module

    flMechInit(key whom) {
        flMechHandle = flMechHandle ^
            (((integer) ("0x" + ((string) llGetOwner()))) & 0xFFFFF) ^
            0xB3AF075 ^
            (llGetUnixTime() & 0xFFF);

        pendingHandles = [ ];               // No updates pending

        /*  Walk through the links and build a table of names
            of linked objects and their link numbers.  There
            is no check for duplicate or blank names.  We trust
            the builder to uniquely name all mechanism components.

            While we're at it, we initialise all entries in the
            dependencyList to -1, indicating no dependency.  */

        integer n = llGetObjectPrimCount(llGetKey());
        integer l;

        linkNames = [ ];
        dependencyList = [ ];
        for (l = 1; l <= n; l++) {
            string name = llList2String(llGetLinkPrimitiveParams(l,
                [ PRIM_NAME ]), 0);

            dependencyList += [ -1 ];
            linkNames += [ name ];
        }

        /* IF OMEGA */
        //  Clear omega rotation list
        omegaList = [ ];
        /* END OMEGA */

        //  If a configuration notecard exists, run it now

        if (llGetInventoryKey(confNotecard) != NULL_KEY) {
            processNotecardCommands(confNotecard);
        } else {
            //  No configuration.  Send void configuration to client
            llMessageLinked(LINK_THIS, LM_ME_CONFIG,
                llList2Json(JSON_ARRAY, [ 0 ]), whom);
        }
    }

    //  flMechStatus  --  Show status of mechanisms module

    flMechStatus(integer which, key whom) {
        whoDat = whom;
        integer mFree = llGetFreeMemory();
        integer mUsed = llGetUsedMemory();
        tawk("Mechanism auxiliary status:\n" +
             "  Script memory.  Free: " + (string) mFree +
                "  Used: " + (string) mUsed + " (" +
                (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
        );

        integer i;
        integer n = llGetListLength(linkNames);
        integer extended = which & 1;

        for (i = 0; i < n; i++) {
            integer ln = i + 1;
            integer dln = flGetCompParent(ln);
            string dep = "";
            if (dln > 0) {
                string dname = llList2String(linkNames, dln - 1);
                dep = "  (" + (string) dln + ": " + dname + ")";
            }
            string ext = "";
            //  Append extended status if requested
            if (extended) {
                list lp = llGetLinkPrimitiveParams(ln, [ PRIM_ROT_LOCAL, PRIM_POS_LOCAL ]);
                ext = "  " + efv(llList2Vector(lp, 1)) + " " + efr(llList2Rot(lp, 0));
                if (dln > 0) {
                    ext += " Par " + efv(flGetCompPos(ln)) + " " + efr(flGetCompRot(ln));
                }
                list chl = flGetCompChildren(ln);
                if (llGetListLength(chl) > 0) {
                    ext += " Ch " + llList2CSV(chl);
                }
            }
            tawk("  " + (string) ln +
                 ". " + llList2String(linkNames, i) + dep + ext);
        }
        tawk("Dependency list: " + llList2CSV(dependencyList));
        /* IF OMEGA */
        tawk("Omega list: " + ef(llList2CSV(omegaList)));
        /* END OMEGA */
        /* IF MOTION */
        tawk("Motion list: " + ef(llList2CSV(motionList)));
        /* END MOTION */
    }

    //  flMechPanic [ save ]  --  Reset mechanism to initial state / save state

    flMechPanic(integer save) {
        if (save) {
            //  Capture link position and rotation for panic restore
            integer n = llGetObjectPrimCount(llGetKey());
            integer l;

            for (l = 1; l <= n; l++) {
                list ps = llGetLinkPrimitiveParams(l,
                    [ PRIM_NAME, PRIM_POS_LOCAL, PRIM_ROT_LOCAL ]);
                tawk("\nSet restore \"" + llList2String(ps, 0) + "\" " +
                     ef((string) llList2Vector(ps, 1)) + " " +
                     ef((string) llList2Rot(ps, 2)));
            }
        } else {
            /* IF OMEGA */
            //  Unconditionally cancel all omega rotation
            omegaList = [ ];
            llSetTimerEvent(0);
            /* END OMEGA */
            /* IF MOTION */
            //  Unconditionally cancel all component motion
            motionList = [ ];
            llSetTimerEvent(0);
            /* END MOTION */
            if (updatePending) {
                panicPending = TRUE;
            } else {
                //  Restore mechanism to initial saved state
                if (llGetListLength(panicRestore) > 0) {
                    integer n = llGetObjectPrimCount(llGetKey());
                    integer l;

                    for (l = 2; l <= n; l++) {
                        integer x = (l - 1) * 2;
                        list pr = llList2List(panicRestore, x, x + 1);

                        llSetLinkPrimitiveParamsFast(l,
                            [ PRIM_POS_LOCAL, llList2Vector(pr, 0),
                              PRIM_ROT_LOCAL, llList2Rot(pr, 1) ]);
                    }
                } else {
                    tawk("No panic restore configured for this object.");
                }
            }
        }
    }

    //  flGetCompName  --  Get component name from link number

    string flGetCompName(integer linkno) {
        if (flMechCheckLink(linkno)) {
            return llList2String(linkNames, linkno - 1);
        }
        return "";
    }

    //  flGetCompLink  --  Get link number of component from name, -1 if not found

    integer flGetCompLink(string cname) {
        integer l = llListFindList(linkNames, [ cname ]);
        if (l >= 0) {
            l++;
        }
        return l;
    }

    //  flGetCompPos  --  Get position of component in parent's co-ordinates

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

    //  flSetCompRotHandle  --  Set rotation step of component

    integer flSetCompRotHandle(integer linkno, rotation newrot, integer handle) {
        if (flMechCheckLink(linkno)) {
            llMessageLinked(LINK_THIS, LM_ME_ROTSTEP,
                llList2CSV([ linkno, newrot, handle ]), NULL_KEY);
            return handle;
        }
        return -1;
    }

    /* IF MOTION */
    //  flSetCompPosHandle  --  Set position step of component

    integer flSetCompPosHandle(integer linkno, vector newpos, integer handle) {
        if (flMechCheckLink(linkno)) {
            llMessageLinked(LINK_THIS, LM_ME_TRANSTEP,
                llList2CSV([ linkno, newpos, handle ]), NULL_KEY);
            return handle;
        }
        return -1;
    }
    /* END MOTION */

    /* IF OMEGA */

    //  flSetCompOmega  --  Set omega rotation of component

    flSetCompOmega(integer linkno, vector axis, float spinrate,
                   float gain, float limit, integer handle) {
        float t = llGetTime();
        float espin = spinrate * gain;      // Effective spin rate
        integer n = llGetListLength(omegaList);
        integer i;

        //  Delete any existing omega entry for this component
        for (i = 0; i < n; i += 8) {
            if (llList2Integer(omegaList, i + 1) == linkno) {
                /*  Send termination link message notification to client,
                    identified by link number and handle.  */
                llMessageLinked(LINK_THIS, LM_ME_OMEGALIMIT,
                    ((string) llList2Integer(omegaList, i + 7)) + "," +
                    ((string) linkno), owner);
                omegaList = llDeleteSubList(omegaList, i, i + 7);
                n = llGetListLength(omegaList);
            }
        }

        //  If effective spin is nonzero, add omegaList entry
        if (espin > 0) {
            float tnext = t + (omegaAngstep / espin);
            omegaList += [ tnext, linkno, t, axis, spinrate, gain, limit, handle ];
        }

        integer oml = llGetListLength(omegaList);
        if (oml > 0) {
            //  Sort omegaList in order of time of next event
            if (oml > 8) {
                omegaList = llListSort(omegaList, 8, TRUE);
            }
            //  Wind timer to fire at next omegaList event
            float tevent = llList2Float(omegaList, 0) - t;
            //  If next event time is in the past, set to one frame in the future
            if (tevent <= 0) {
                tevent = 0.025;
            }
            llSetTimerEvent(tevent);
        } else {
            //  Omega list is empty: cancel timer event if motion list also void
            /* IF MOTION */
            if (motionList == [ ]) {
            /* END MOTION */
                llSetTimerEvent(0);
            /* IF MOTION */
            }
            /* END MOTION */
        }
    }

    //  omegaTimer  --  Perform omega update upon timer events

    omegaTimer() {
        float t = llGetTime();
        integer changes = FALSE;
        integer n = llGetListLength(omegaList);
        integer i;

        //  Examine all entries in omega list
        for (i = 0; i < n; i += 8) {
            if (llList2Float(omegaList, i) <= t) {
                integer linkno = llList2Integer(omegaList, i + 1);
                float lapse = t - llList2Float(omegaList, i + 2);
                float espin = llList2Float(omegaList, i + 4) *
                    llList2Float(omegaList, i + 5);
                float rotdelta = espin * lapse;
                //  Angular rotation on this step
                float limit = llList2Float(omegaList, i + 6);   // Angular rotation limit
                if ((limit > 0) && (rotdelta > limit)) {
                    rotdelta = limit;
                }
                rotation incrot = llAxisAngle2Rot(llList2Vector(omegaList, i + 3), rotdelta);
                rotation newrot = incrot * flGetCompRot(linkno);
                integer handle = llList2Integer(omegaList, i + 7);
                pendingHandles += flSetCompRotHandle(linkno, newrot, handle);
                updatePending++;                // Increment update in progress

                integer turning = TRUE;
                if (limit > 0) {
                    limit -= rotdelta;
                    if (limit <= 0) {
                        //  Reached preset limit of rotation
                        omegaList = llDeleteSubList(omegaList, i, i + 7);
                        n -= 8;
                        if (omegaList == [ ]) {
                            //  Omega list is empty: cancel timer event if motion list also void
                            /* IF MOTION */
                            if (motionList == [ ]) {
                            /* END MOTION */
                                llSetTimerEvent(0);
                            /* IF MOTION */
                            }
                            /* END MOTION */
                        }
                        turning = FALSE;
                        changes = TRUE;
                        /*  Send link message notification to client, identified
                            with link number and handle.  */
                        llMessageLinked(LINK_THIS, LM_ME_OMEGALIMIT,
                            ((string) handle) + "," + ((string) linkno), owner);
                    } else {
                        //  Update limit in omegaList entry
                        omegaList = llListReplaceList(omegaList, [ limit ], i + 6, i + 6);
                    }
                }

                if (turning) {
                    //  Update time of next incremental rotation event
                    float tnext = t + (omegaAngstep / espin);
                    omegaList = llListReplaceList(omegaList, [ tnext, linkno, t ], i, i + 2);
                    changes = TRUE;
                }
            }
        }
    }
    /* END OMEGA */

    /* IF MOTION */

    //  flSetCompMotion  --  Set motion of component

    flSetCompMotion(integer linkno, vector direction,
                    float speed, float distance, integer handle) {
        float t = llGetTime();
        integer n = llGetListLength(motionList);
        integer i;

        //  Delete any existing motion entry for this component
        for (i = 0; i < n; i += 9) {
            if (llList2Integer(motionList, i + 1) == linkno) {
                /*  Send termination link message notification to client,
                    identified by link number and handle.  */
                llMessageLinked(LINK_THIS, LM_ME_MOVELIMIT,
                    ((string) llList2Integer(motionList, i + 8)) +
                    "," + ((string) linkno), owner);
                motionList = llDeleteSubList(motionList, i, i + 8);
                n = llGetListLength(motionList);
            }
        }

        //  If speed is nonzero, add motionList entry
        if (speed > 0) {
            float tnext = t + motionStep;
            motionList += [ tnext, linkno, t, direction, speed,
                            flGetCompPos(linkno), 0, distance, handle ];
        }

        integer mll = llGetListLength(motionList);
        if (mll > 0) {
            //  Sort motionList in order of time of next event
            if (mll > 9) {
                motionList = llListSort(motionList, 9, TRUE);
            }
            //  Wind timer to fire at next motionList or omegaList event
            float tevent = llList2Float(motionList, 0) - t;
            /* IF OMEGA */
            float oevent = llList2Float(omegaList, 0) - t;
            if (oevent < tevent) {
                tevent = oevent;
            }
            /* END OMEGA */
            //  If next event time is in the past, set to one frame in the future
            if (tevent <= 0) {
                tevent = 0.025;
            }
            llSetTimerEvent(tevent);
        } else {
            //  Motion list is empty: cancel timer event if omega list also void
            /* IF OMEGA */
            if (omegaList == [ ]) {
            /* END OMEGA */
                llSetTimerEvent(0);
            /* IF OMEGA */
            }
            /* END OMEGA */
        }
    }

    //  motionTimer  --  Perform motion update upon timer events

    motionTimer() {
        float t = llGetTime();
        integer changes = FALSE;
        integer n = llGetListLength(motionList);
        integer i;

        //  Examine all entries in motion list
        for (i = 0; i < n; i += 9) {
            if (llList2Float(motionList, i) <= t) {
                integer linkno = llList2Integer(motionList, i + 1);
                float lapse = t - llList2Float(motionList, i + 2);          // Time elapsed since last update
                float transdist = llList2Float(motionList, i + 4) * lapse;  // Distance to move in this step
                float totaltrans = llList2Float(motionList, i + 6) + transdist; // Total distance moved
                float limit = llList2Float(motionList, i + 7);              // Translation limit
                if ((limit > 0) && (totaltrans > limit)) {
                    transdist = limit - llList2Float(motionList, i + 6);    // Curtail translation at limit
                    totaltrans = limit;
                }
                vector newpos = llList2Vector(motionList, i + 5) +
                    (llList2Vector(motionList, i + 3) * totaltrans);
                integer handle = llList2Integer(motionList, i + 8);
                pendingHandles += flSetCompPosHandle(linkno, newpos, handle);
                updatePending++;                // Increment update in progress

                integer moving = TRUE;
                if ((limit > 0) && (totaltrans >= limit)) {
                    motionList = llDeleteSubList(motionList, i, i + 8);
                    n -= 9;
                    if (motionList == [ ]) {
                        //  Motion list is empty: cancel timer event if omega list also void
                        /* IF OMEGA */
                        if (omegaList == [ ]) {
                        /* END OMEGA */
                            llSetTimerEvent(0);
                        /* IF OMEGA */
                        }
                        /* END OMEGA */
                    }
                    moving = FALSE;
                    llMessageLinked(LINK_THIS, LM_ME_MOVELIMIT,
                        ((string) handle) + "," + ((string) linkno), owner);
                } else {
                    //  Update limit in motionList entry
                    motionList = llListReplaceList(motionList, [ totaltrans ], i + 6, i + 6);
                }

                if (moving) {
                    //  Update time of next incremental motion event
                    float tnext = t + motionStep;
                    motionList = llListReplaceList(motionList, [ tnext, linkno, t ], i, i + 2);
                    changes = TRUE;
                }
            }
        }
    }
    /* END MOTION */

    //  flMechCheckLink  --  Validate component link number

    integer flMechCheckLink(integer linkno) {
        if ((linkno < 1) || (linkno > llGetListLength(dependencyList))) {
            tawk("Mechanisms: link number " + (string) linkno + " invalid.");
            return FALSE;
        }
        return TRUE;
    }

    //  abbrP  --  Test if string matches abbreviation

    integer abbrP(string str, string abbr) {
        return abbr == llGetSubString(str, 0, llStringLength(abbr) - 1);
    }

    //  checkDependencies  --  Check dependencies for loops

    integer checkDependencies() {
        integer n = llGetListLength(dependencyList);
        integer i;
        for (i = 0; i < n; i++) {
            integer d = llList2Integer(dependencyList, i);
            list dstack = [ i + 1 ];
            while (d > 0) {
                //  Test whether this dependency is already on the stack
                integer l = llGetListLength(dstack);
                integer k;
                for (k = 0; k < l; k++) {
                    //  Is this dependency already on the stack ?
                    if (llList2Integer(dstack, k) == d) {
                        tawk("Circular dependency for component \"" +
                            flGetCompName(i + 1) + "\": loop at parent \"" +
                            flGetCompName(d) + "\".");
                        return FALSE;
                    }
                }
                dstack += [ d ];        // Add this dependency to the stack
                d = llList2Integer(dependencyList, d - 1);  // Follow next dependency
            }
        }
        return TRUE;
    }

    //  processNotecardCommands  --  Read and execute commands from a notecard

    processNotecardCommands(string ncname) {
            ncSource = ncname;
            ncLine = 0;
            tawk("Reading configuration: " + ncSource);
            ncQuery = llGetNotecardLine(ncSource, ncLine);
            ncLine++;
    }

    //  processCommand  --  Process a command from the configuration notecard

    integer processCommand(key id, string message, integer fromScript) {

        whoDat = id;            // Direct chat output to sender of command

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

        //  Set                     Set parameter

        if (abbrP(command, "se")) {

            //  Set parent "Component1" "Component2"...   Define component dependencies

            if (abbrP(sparam, "pa")) {
                if (llGetListLength(dependencyList) == 0) {
                    /*  On first declaration, initialise the dependencyList
                        list to no dependencies.  */
                    integer n = llGetListLength(linkNames);
                    integer l;

                    for (l = 1; l <= n; l++) {
                        dependencyList += [ -1 ];
                    }
                }
                args = llParseString2List(llStringTrim(fixArgs(message), STRING_TRIM), [ " " ], []);
                args = fixQuotes(args);
                argn = llGetListLength(args);
                integer linkno = flGetCompLink(llList2String(args, 2));
                if (linkno < 0) {
                    tawk("Set parent: parent component \"" + llList2String(args, 2) + "\" unknown.");
                    return FALSE;
                }
                integer i;

                for (i = 3; i < argn; i++) {
                    integer deplink = flGetCompLink(llList2String(args, i));
                    if (deplink < 0) {
                        tawk("Set parent: child component \"" + llList2String(args, i) + "\" unknown.");
                        return FALSE;
                    }
                    if (llList2Integer(dependencyList, deplink - 1) != -1) {
                        tawk("Set parent: child component \"" + llList2String(args, i) +
                            "\" previously declared dependent on \"" +
                            flGetCompName(llList2Integer(dependencyList, deplink - 1)) + "\".");
                        return FALSE;
                    }
                    dependencyList = llListReplaceList(dependencyList, [ linkno ],
                        deplink - 1, deplink - 1);
                }
                if (!checkDependencies()) {
                    return FALSE;
                }

                //  Set restore "Component" <position> <rotation>   Set panic restore orientation

                } else if (abbrP(sparam, "re")) {
                    if (llGetListLength(panicRestore) == 0) {
                        /*  On first declaration, initialise the panicRestore
                            list to values marked unspecified through an
                            unnormalised all-zero-component rotation
                            quarternion.  */
                        integer n = llGetListLength(linkNames);
                        integer l;

                        for (l = 1; l <= n; l++) {
                            panicRestore += [ ZERO_VECTOR, <0, 0, 0, 0> ];
                        }
                    }
                    args = llParseString2List(llStringTrim(fixArgs(message), STRING_TRIM), [ " " ], []);
                    args = fixQuotes(args);
                    integer linkno = flGetCompLink(llList2String(args, 2));
                    if (linkno < 0) {
                        tawk("Set restore: unknown component \"" + llList2String(args, 2) + "\".");
                        return FALSE;
                    }
                    linkno--;

                    panicRestore = llListReplaceList(panicRestore,
                        [ (vector) llList2String(args, 3),
                          (rotation) llList2String(args, 4) ], linkno * 2,
                            (linkno * 2) + 1);
                } else {
                    tawk("Invalid.  Set parent/restore");
                    return FALSE;
                }

        } else {
            tawk("Huh?  \"" + message + "\" undefined.");
            return FALSE;
        }
        return TRUE;
    }

    default {

        on_rez(integer n) {
            llResetScript();
        }

        state_entry() {
            whoDat = owner = llGetOwner();
            flMechInit(owner);      // Preemptively initialise to avoid confusion
        }

        /*  The link_message() event receives commands from other scripts
            and passes them on to the script processing functions
            within this script.  */

        link_message(integer sender, integer num, string str, key id) {

            //  LM_ME_INIT (120): Initialise mechanisms module

            if (num == LM_ME_INIT) {
                flMechInit(id);

            //  LM_ME_RESET (121): Reset script

            } else if (num == LM_ME_RESET) {
                llResetScript();

            //  LM_ME_STAT (122): Print status

            } else if (num == LM_ME_STAT) {
                flMechStatus((integer) str, id);

            /* IF OMEGA */
            //  LM_ME_SPIN (125): Spin (omega rotate) component

            } else if (num == LM_ME_SPIN) {
                list args = llCSV2List(str);
                flSetCompOmega((integer) llList2String(args, 0),
                    (vector) llList2String(args, 1),
                    (float) llList2String(args, 2),
                    (float) llList2String(args, 3),
                    (float) llList2String(args, 4),
                    (integer) llList2String(args, 5));
            /* END OMEGA */

            //  LM_ME_PANIC (126): Save or restore initial condition

            } else if (num == LM_ME_PANIC) {
                flMechPanic((integer) str);

            //  LM_ME_SETTINGS (128): Set modes

            } else if (num == LM_ME_SETTINGS) {
                list params = llCSV2List(str);
                /* IF TRACE */
                trace = (integer) llList2String(params, 0);
                /* END TRACE */
                /* IF COMPILER */
//              compileMode = (integer) llList2String(params, 1);
                /* END COMPILER */

            //  LM_ME_COMPLETE (131): Mechanism update complete

            } else if (num == LM_ME_COMPLETE) {
                integer hx = llListFindList(pendingHandles,
                    [ (integer) llList2String(llCSV2List(str), 1) ]);
                if (hx >= 0) {
                    //  This was completion of one of our pending updates
                    pendingHandles = llDeleteSubList(pendingHandles, hx, hx);
                    updatePending--;
if (updatePending < 0) {
tawk("LM_ME_COMPLETE: updatePending underflow.");
updatePending = 0;
}
                    //  If events were pending completion of updates, do them now
                    if (updatePending == 0) {
                        /* IF OMEGA */
                        if (omegaTimerPending) {
                            omegaTimer();
                            omegaTimerPending = FALSE;
                        }
                        /* END OMEGA */
                        /* IF MOTION */
                        if (motionTimerPending) {
                            motionTimer();
                            motionTimerPending = FALSE;
                        }
                        if (panicPending) {
                            flMechPanic(FALSE);
                            panicPending = FALSE;
                        }
                    }
                }

            /* IF MOTION */
            //  LM_ME_MOVE (133): Move component

            } else if (num == LM_ME_MOVE) {
                list args = llCSV2List(str);
                flSetCompMotion((integer) llList2String(args, 0),
                    (vector) llList2String(args, 1),
                    (float) llList2String(args, 2),
                    (float) llList2String(args, 3),
                    (integer) llList2String(args, 4));
            /* END MOTION */
            }
        }

        /*  The timer is used to perform omega animation.  The timer
            modifies the next event time in omegaList items and
            re-sorts the list in order of next even time but it never
            adds or deletes entries from the omegaList.  */

        timer() {
            /* IF OMEGA */
            if (omegaList != [ ]) {
                if (updatePending > 0) {
                    omegaTimerPending = TRUE;
                } else {
                    omegaTimer();
                }
            }
            /* END OMEGA */
            /* IF MOTION */
            if (motionList != [ ]) {
                if (updatePending > 0) {
                    motionTimerPending = TRUE;
                } else {
                    motionTimer();
                }
            }
            /* END MOTION */
        }

        //  The dataserver event receives lines from the configuration notecard

        dataserver(key query_id, string data) {
            if (query_id == ncQuery) {
                if (data == EOF) {
                    tawk("End configuration: " + ncSource);
                    ncSource = "";
                    ncLine = 0;
                    //  Send mechanism configuration to client
                    llMessageLinked(LINK_THIS, LM_ME_CONFIG,
                        llList2Json(JSON_ARRAY,
                                [ llGetListLength(dependencyList) ] +   // Number of components / links
                                linkNames +                             // Link name table
                                dependencyList),                        // Component dependency list
                        owner);
                } else {
                    string s = llStringTrim(data, STRING_TRIM);
                    //  Ignore comments and process valid commands
                    if ((llStringLength(s) > 0) && (llGetSubString(s, 0, 0) != "#")) {
                        integer stat = processCommand(owner, s, TRUE);
                        if (!stat) {
                            tawk("Configuration error: Mechanisms disabled.");
                            return;
                        }
                    }
                    ncQuery = llGetNotecardLine(ncSource, ncLine);
                    ncLine++;
                }
            }
        }
    }
