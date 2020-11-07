    /*

                    Import/Export Mechanism Positions

    */


    key owner;                      // Owner UUID
    key whoDat = NULL_KEY;          // Avatar who sent command

    //  Command processor messages

    integer LM_CP_COMMAND = 223;    // Process command

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
//string ef(string s) { return s; }

    /*          ************************************************
                *                                              *
                *             Fourmilab Mechanisms             *
                *             Client-Side Interface            *
                *                                              *
                ************************************************  */

    //  Support storage for Mechanisms module
    list dependencyList;            // List of dependency relationships
//  list omegaList;                 // List of omega rotations
    list linkNames;                 // List of link names

    //  Mechanisms link messages
//  integer LM_ME_INIT = 120;       // Initialise mechanisms
//  integer LM_ME_RESET = 121;      // Reset mechanisms script
//  integer LM_ME_STAT = 122;       // Print status
    integer LM_ME_TRANSLATE = 123;  // Translate component
    integer LM_ME_ROTATE = 124;     // Rotate component
//  integer LM_ME_SPIN = 125;       // Spin (omega rotate) component
//  integer LM_ME_PANIC = 126;      // Reset components to initial state
    integer LM_ME_CONFIG = 127;     // Return configuration to client script
//  integer LM_ME_SETTINGS = 128;   // Set parameters in mechanisms module
//  integer LM_ME_OMEGALIMIT = 129; // Omega rotation reached limit
//  integer LM_ME_CHANGED = 130;    // Position/rotation change report to compiler
    integer LM_ME_COMPLETE = 131;   // Confirm component update complete
    integer LM_ME_MOVELIMIT = 132;  // Move limit reached
    integer LM_ME_MOVE = 133;       // Move component
    integer LM_ME_ROTSTEP = 134;    // Rotation step by spin command
    integer LM_ME_TRANSTEP = 135;   // Translation step by move command

    integer flMechHandle = -982449724;  // Request handle base

    //  flMechConfig  --  Process configuration message

    flMechConfig(string msg) {
        list ml = llJson2List(msg);
        integer ncomps = llList2Integer(ml, 0);
        linkNames = llList2List(ml, 1, (1 + ncomps) - 1);
        dependencyList = llList2List(ml, ncomps + 1, -1);
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

    //  abbrP  --  Test if string matches abbreviation

    integer abbrP(string str, string abbr) {
        return abbr == llGetSubString(str, 0, llStringLength(abbr) - 1);
    }

    //  processAuxCommand  --  Process a command

    integer processAuxCommand(key id, list args) {

        whoDat = id;            // Direct chat output to sender of command

        string message = llList2String(args, 0);
//      string lmessage = llList2String(args, 1);
        args = llDeleteSubList(args, 0, 1);
        integer argn = llGetListLength(args);       // Number of arguments
        string command = llList2String(args, 0);    // The command
        string sparam = llList2String(args, 1);     // First argument, for convenience

        //  Export                  Export commands

        if (abbrP(command, "ex")) {

                //  Export list

                if (abbrP(sparam, "li")) {
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
                    }

                //  Export script

                } else if (abbrP(sparam, "sc")) {
                    //  Sort joints in alphabetic order
                    list joints = llListSort(linkNames, 1, TRUE);
                    integer i;
                    integer n = llGetListLength(joints);

                    for (i = 0; i < n; i++) {
                        integer l = llListFindList(linkNames, [ llList2String(joints, i) ]);
                        if (l > LINK_ROOT) {        // We don't export the root of the link set
                            l++;
                            //  It's only a joint is something is dependent upon it
                            if (llListFindList(dependencyList, [ l ]) >= 0) {
                                string jname = flGetCompName(l);
                                tawk("== Import rotate \"" + jname + "\" " +
                                    (string) efr(flGetCompRot(l)));
                            }

                            //  If this component has no parent, re-create its position

                            if (flGetCompParent(l) < 0) {
                                string jname = flGetCompName(l);
                                string cmd = "== Import translate \"" + jname + "\" ";
                                tawk(cmd + (string) efv(flGetCompPos(l)));
                            }
                        }
                    }

                } else {
                    tawk("Unknown export command.  Valid: list/script.");
                }

        //  Import                  Import commands

        } else if (abbrP(command, "im")) {
                args = llParseString2List(llStringTrim(fixArgs(message), STRING_TRIM), [ " " ], []);
                args = fixQuotes(args);
                argn = llGetListLength(args);

                //  Import rotate "name" <x,y,z>

                if (abbrP(sparam, "ro")) {
                    integer linkno = flGetCompLink(llList2String(args, 2));
                    if (linkno > 0) {
                        flSetCompRot(linkno,
                            llEuler2Rot(((vector) llList2String(args, 3)) * DEG_TO_RAD));
                    } else {
                        tawk("Unknown component.  Use \"Export list\" for names.");
                    }

                //  Import translate "name" <x,y,z>

                } else if (abbrP(sparam, "tr")) {
                    integer linkno = flGetCompLink(llList2String(args, 2));
                    if (linkno > 0) {
                        flSetCompPos(linkno, (vector) llList2String(args, 3));
                    } else {
                        tawk("Unknown component.  Use \"Export list\" for names.");
                    }

                } else {
                    tawk("Unknown import command.  Valid: rotate.");
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

            //  LM_CP_COMMAND (223): Process auxiliary command

            } else if (num == LM_CP_COMMAND) {
                processAuxCommand(id, llJson2List(str));
            }
        }
    }
