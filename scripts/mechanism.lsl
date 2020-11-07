    /*

                        Fourmilab Mechanisms

    */

    key owner;                      // Owner UUID

    key whoDat = NULL_KEY;          // Avatar who sent command

    /* IF TRACE */
    integer trace = FALSE;          // Trace operation ?
    /* END TRACE */

    //  Storage associated with deferral of link updates
    integer deferUpdate = TRUE;     // Enable update deferral ?
    integer deferMode = 0;          /* Mode: 0 no deferral active
                                             1 single update deferral in progress
                                             2 multiple update deferral in progress */
    list deferList;                 // List of deferred llSetLinkPrimitiveParamsFast() rules
    /* IF COMPILER */
    integer compileMode = FALSE;    // Report configuration changes to external compiler
    /* END COMPILER */

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

    //  Mechanisms messages (commented out are handled in Auxiliary)
//  integer LM_ME_INIT = 120;       // Initialise mechanisms
    integer LM_ME_RESET = 121;      // Reset mechanisms script
    integer LM_ME_STAT = 122;       // Print status
    integer LM_ME_TRANSLATE = 123;  // Translate component
    integer LM_ME_ROTATE = 124;     // Rotate component
//  integer LM_ME_SPIN = 125;       // Spin (omega rotate) component
//  integer LM_ME_PANIC = 126;      // Reset components to initial state
    integer LM_ME_CONFIG = 127;     // Return configuration to client script
    integer LM_ME_SETTINGS = 128;   // Set parameters in mechanisms module
//  integer LM_ME_OMEGALIMIT = 129; // Omega rotation reached limit
    integer LM_ME_CHANGED = 130;    // Position/rotation change report to compiler
    integer LM_ME_COMPLETE = 131;   // Confirm component update complete
    integer LM_ME_MOVELIMIT = 132;  // Move limit reached
    integer LM_ME_MOVE = 133;       // Move component
    integer LM_ME_ROTSTEP = 134;    // Rotation step by spin command
    integer LM_ME_TRANSTEP = 135;   // Translation step by move command

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

/*
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
*/
string ef(string f) { return f; }

    //  flMechConfig  --  Process configuration message

    flMechConfig(string msg) {
        list ml = llJson2List(msg);
        integer ncomps = llList2Integer(ml, 0);
        linkNames = llList2List(ml, 1, (1 + ncomps) - 1);
        dependencyList = llList2List(ml, ncomps + 1, -1);
//tawk("Components: " + (string) ncomps);
//tawk("Component names: " + llList2CSV(linkNames));
//tawk("Dependency list: " + llList2CSV(dependencyList));
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

    //  flSetCompPos  --  Set position of component relative to parent

    flSetCompPos(integer linkno, vector newpos) {
        if (!flMechCheckLink(linkno)) {
            return;
        }

        //  Compute existing position and rotation in parent co-ordinate system

        vector curpos = flGetCompPos(linkno);
        rotation currot = flGetCompRot(linkno);

        /*  Find parent of this component and obtain its rotation
            and position, which define its co-ordinate system.  */

        integer parent = flGetCompParent(linkno);
        vector parpos = ZERO_VECTOR;
        rotation parrot = ZERO_ROTATION;
        if (parent > 0) {
            list ppl = llGetLinkPrimitiveParams(parent, [ PRIM_POS_LOCAL, PRIM_ROT_LOCAL ]);
            parpos = llList2Vector(ppl, 0);
            parrot = llList2Rot(ppl, 1);
        }
        //  Transform new position from parent co-ordinates to LCS
        vector newposLCS = (newpos * parrot) + parpos;
        list cpr = llGetLinkPrimitiveParams(linkno,
            [ PRIM_POS_LOCAL, PRIM_ROT_LOCAL ]);
        vector pivpos = llList2Vector(cpr, 0);
        rotation pivrot = llList2Rot(cpr, 1);
        vector deltapos = newposLCS - pivpos;

        /* IF TRACE */
        if (trace) {
            tawk("flSetCompPos(linkno=" + (string) linkno + ", newpos=" + efv(newpos) + "):");
            tawk("  Parent link " + (string) parent + ", position " +
                efv(parpos) + ", rotation " + efr(parrot));
            tawk("  Current component location in parent co-ords, pos " +
                efv(curpos) + ", rot " + efr(currot));
            tawk("  New component location in LCS, pos " + efv(newposLCS));
            tawk("  pivpos " + efv(pivpos) + " deltapos " + efv(deltapos));
        }
        /* END TRACE */

        //  Adjust LCS position of this component

        deferUpdates(deferUpdate);
        if (deferMode > 0) {
            deferList += [ PRIM_LINK_TARGET, linkno, PRIM_POS_LOCAL, newposLCS ];
        } else {
            llSetLinkPrimitiveParamsFast(linkno, [ PRIM_POS_LOCAL, newposLCS ]);
        }

        /*  Rotate dependent components rigidly
            about the pivot point which is the origin of
            this component's co-ordinate system in LCS.  */

        integer i;
        integer n = llGetListLength(dependencyList);

        for (i = 0; i < n; i++) {
            if (llList2Integer(dependencyList, i) == linkno) {
                //  This link depends on us: propagate changes to it
                adjustComponent(i + 1, deltapos, ZERO_ROTATION, pivpos, pivrot);
            }
        }
        deferUpdates(0);
    }

    /*  flSetCompRot  --  Set rotation of component relative to parent
                          This is the heart of hierarchical mechanisms.
                          The arguments are the link number of a component
                          and its new rotation expressed in the co-ordinates
                          of its parent component (or, if it has no parent
                          component, the local co-ordinate system [LCS]) of
                          the link set of which it is a member).  It rotates
                          the component to the new orientation, then
                          propagates the rotation to all components which
                          are dependent (directly or indirectly) upon this
                          one.  */

    flSetCompRot(integer linkno, rotation newrot) {
        //  Validate link in range
        if (!flMechCheckLink(linkno)) {
            return;
        }

        /*  Find parent of this component and obtain its rotation
            and position, which define its co-ordinate system.
            If the component has no parent, its co-ordinate system
            is that of the link set of which it is a member, and thus
            its LCS co-ordinates are ZERO_ROTATION and ZERO_VECTOR.  */

        integer parent = flGetCompParent(linkno);
        rotation parrot = ZERO_ROTATION;
        if (parent > 0) {
            list ppl = llGetLinkPrimitiveParams(parent, [ PRIM_ROT_LOCAL ]);
            parrot = llList2Rot(ppl, 0);
        }
        rotation newrotLCS = newrot * parrot;
        /* IF TRACE */
        if (trace) {
            tawk("flSetCompRot(linkno=" + (string) linkno + ", newrot=" + efr(newrot) + "):");
            tawk("  Parent link " + (string) parent + ", rotation " + efr(parrot));
            tawk("  New rotation in LCS (newrotLCS) " + efr(newrotLCS));
        }
        /* END TRACE */

        //  Compute delta between existing and new rotation in LCS
        rotation currot = llList2Rot(llGetLinkPrimitiveParams(linkno, [ PRIM_ROT_LOCAL ]), 0);
        rotation deltarot = newrotLCS / currot;
        /* IF TRACE */
        if (trace) {
            tawk("  Current rotation in LCS " + efr(currot));
            tawk("  Delta rotation in LCS " + efr(deltarot));
        }
        /* END TRACE */

        //  Adjust LCS rotation of this component

        deferUpdates(deferUpdate);
        if (deferMode > 0) {
            deferList += [ PRIM_LINK_TARGET, linkno, PRIM_ROT_LOCAL, newrotLCS ];
        } else {
            llSetLinkPrimitiveParamsFast(linkno, [ PRIM_ROT_LOCAL, newrotLCS ]);
        }

        /*  Rotate dependent components rigidly
            about the pivot point which is the origin of
            this component's co-ordinate system in LCS.  */

        integer i;
        integer n = llGetListLength(dependencyList);
        vector curpos = llList2Vector(llGetLinkPrimitiveParams(linkno,
            [ PRIM_POS_LOCAL ]), 0);

        for (i = 0; i < n; i++) {
            if (llList2Integer(dependencyList, i) == linkno) {
                //  This link depends on us: propagate changes to it
                adjustComponent(i + 1, ZERO_VECTOR, deltarot, curpos, currot);
            }
        }
        deferUpdates(0);
    }

/*  CLIENT-ONLY
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
   CLIENT-ONLY */

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

    /*  adjustComponent  --  Re-orient a component.  This function
                             re-orients a component by translating
                             and rotating it around a pivot point.
                             All components which are dependent upon
                             this component move with it, in rigid
                             motion.  The pivot point, translation,
                             and rotation are specified in the local
                             co-ordinate system (LCS) of the link set.
                             All conversion from component co-ordinate
                             systems to LCS must be performed by the
                             caller of this function.  */

    adjustComponent(integer linkno,         // Link number to adjust
                    vector trans,           // Translation in LCS
                    rotation rot,           // Delta rotation in parent co-ordinate system
                    vector pivpos,          // Pivot position in LCS
                    rotation pivrot         // Rotation about pivot position in LCS
                   ) {
        /* IF TRACE */
        if (trace) {
            tawk("adjustComponent(linkno=" + (string) linkno +
                 ", trans=" + efv(trans) + ", rot=" + efr(rot) +
                 ", pivpos=" + efv(pivpos) + ", pivrot=" + efr(pivrot) + ")");
        }
        /* END TRACE */

        //  Get this link's rotation in pivot coords
        rotation currot = llList2Rot(llGetLinkPrimitiveParams(linkno, [ PRIM_ROT_LOCAL ]), 0) / pivrot;
        //  Transform this by delta rotation of pivot
        rotation newrotpar = currot * rot;
        /* IF TRACE */
        if (trace) {
            tawk("  current rotation " + efr(currot) + "  new rot in pivot " + efr(newrotpar));
        }
        /* END TRACE */
        //  Transform this by the original (pre-rotation) transform of the parent to LCS
        rotation newrotLCS = newrotpar * pivrot;
        /* IF TRACE */
        if (trace) {
            tawk("  new rotation in LCS " + efr(newrotLCS));
        }
        /* END TRACE */
        //  At this point, we have the new rotation of the component in LCS

        //  Get this link's position in pivot co-ordinates
        vector compos = llList2Vector(llGetLinkPrimitiveParams(linkno, [ PRIM_POS_LOCAL ]), 0);
        vector curpos = (compos / pivrot) - (pivpos / pivrot);
        //  Adjust by delta rotation of parent
        vector newpos = curpos * rot;
        //  Transform from parent co-ordinates to LCS
        vector newposLCS = (newpos * pivrot) + pivpos;
        //  Apply LCS translation, if any
        newposLCS += trans;

        /* IF TRACE */
        if (trace) {
            tawk("  adjustComponent: curpos (comp in par co-ords) " + efv(curpos) +
                 " newpos (delta rotated) " + efv(newpos) +
                 " newposLCS (pos transformed to LCS) " + efv(newposLCS));
        }
        /* END TRACE */

        if (deferMode > 0) {
            deferList += [ PRIM_LINK_TARGET, linkno,
                PRIM_POS_LOCAL, newposLCS, PRIM_ROT_LOCAL, newrotLCS ];
        } else {
            llSetLinkPrimitiveParamsFast(linkno,
                [ PRIM_POS_LOCAL, newposLCS, PRIM_ROT_LOCAL, newrotLCS ]);
        }

        /*  This component has now been re-oriented.  Now walk
            through the dependencyList and call ourselves recursively
            to adjust all components which depend upon this one.
            Since all dependencies move together rigidly, the
            same parent orientation parameters are used for
            the dependent components, even though their immediate
            parents may be different.  */

        integer i;
        integer n = llGetListLength(dependencyList);

        for (i = 0; i < n; i++) {
            if (llList2Integer(dependencyList, i) == linkno) {
                //  This link depends on us: propagate changes to it
                adjustComponent(i + 1, trans, rot, pivpos, pivrot);
            }
        }
    }

    //  deferUpdates  --  Manage deferral and consolidation of link updates

    deferUpdates(integer mode) {

        if (mode > 0) {
            //  Enter deferral mode and clear list of pending updates
            deferMode = mode;
            deferList = [ ];
        } else {
            //  End deferral mode: execute pending updates
            integer n;
            if ((deferMode > 0) && ((n = llGetListLength(deferList)) > 0)) {
                /*  Execute deferred link updates.  Note that since each
                    update specifies the link to which it applies with
                    PRIM_LINK_TARGET, the link number argument in the
                    following function call is ignored.  */
                llSetLinkPrimitiveParamsFast(LINK_ROOT, deferList);
                /* IF COMPILER */
                if (compileMode) {
                    //  Compile mode enabled: report configuration changes to requester
                    llMessageLinked(LINK_THIS, LM_ME_CHANGED,
                        llList2Json(JSON_ARRAY, deferList), owner);
                }
                /* END COMPILER */
                deferList = [ ];        // Just to reclaim space; not otherwise needed
            }
            deferMode = 0;
        }
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

            //  LM_ME_RESET (121): Reset script

            if (num == LM_ME_RESET) {
                llResetScript();

            //  LM_ME_STAT (122): Print status

            } else if (num == LM_ME_STAT) {
                llSleep(1.5);
                integer mFree = llGetFreeMemory();
                integer mUsed = llGetUsedMemory();
                tawk("Mechanism main status:" +
                     "\n  Script memory.  Free: " + (string) mFree +
                        "  Used: " + (string) mUsed + " (" +
                        (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
                );

            //  LM_ME_TRANSLATE (123): Translate component
            //  LM_ME_TRANSTEP  (135): Translation step by move command

            } else if ((num == LM_ME_TRANSLATE) ||
                       (num == LM_ME_TRANSTEP)) {
                list args = llCSV2List(str);
                flSetCompPos((integer) llList2String(args, 0),
                    (vector) llList2String(args, 1));
                llMessageLinked(LINK_THIS, LM_ME_COMPLETE,
                    (string) num +
                    "," + llList2String(args, 2) +
                    "," + llList2String(args, 0), id);

            //  LM_ME_ROTATE  (124): Rotate component
            //  LM_ME_ROTSTEP (134): Rotation step by spin command

            } else if ((num == LM_ME_ROTATE) ||
                       (num == LM_ME_ROTSTEP)) {
                list args = llCSV2List(str);
                flSetCompRot((integer) llList2String(args, 0),
                    (rotation) llList2String(args, 1));
                llMessageLinked(LINK_THIS, LM_ME_COMPLETE,
                    (string) num +
                    "," + llList2String(args, 2) +
                    "," + llList2String(args, 0), id);

            //  LM_ME_CONFIG (127): Set mechanism configuration from auxiliary

            } else if (num == LM_ME_CONFIG) {
                flMechConfig(str);

            //  LM_ME_SETTINGS (128): Set modes

            } else if (num == LM_ME_SETTINGS) {
                list params = llCSV2List(str);
                /* IF TRACE */
                trace = (integer) llList2String(params, 0);
                /* END TRACE */
                /* IF COMPILER */
                compileMode = (integer) llList2String(params, 1);
                /* END COMPILER */
            }
        }
    }
