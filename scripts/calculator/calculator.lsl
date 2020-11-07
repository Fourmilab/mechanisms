    /*

                Fourmilab Geometric Calculator

    */

    key owner;                      // Owner UUID

    /*  Command channel in chat (1805 is the birth year of William
        Rowan Hamilton).  To disable submission of commands via
        chat, and accept them only via the LM_CA_COMMAND link
        message, set commandChannel to 0.  */
    integer commandChannel = 0;
    integer commandH;               // Handle for command channel

    key whoDat = NULL_KEY;          // Avatar who sent command
    integer restrictAccess = 0;     // Access restriction: 0 none, 1 group, 2 owner
    integer echo = TRUE;            // Echo chat and script commands ?

    float angleScale = DEG_TO_RAD;  // Scale factor for angles
    integer trace = TRUE;           // Trace operation ?
    integer linkFrom = 0;           // Link message monitor start
    integer linkTo = -1;            // Link message monitor end

    string helpFileName = "Fourmilab Calculator User Guide";

    //  Undo state storage
    list lastres = [ ];             // Last result
    list undoList = [ ];            // Undo list
    integer maxUndo = 10;           // Maximum number of undo operations saved

    /*  Symbolic constants for common numerical values.  Note
        that these must be arranged so that longer names
        containing a substring thich is also a constant appear
        earlier in the table.  */
    list kpool = [
        "deg_to_rad", DEG_TO_RAD,
        "pi_by_two", PI_BY_TWO,
        "two_pi", TWO_PI,
        "pi", PI,
        "rad_to_deg", RAD_TO_DEG,
        "sqrt2", SQRT2
    ];

    //  Functions we implement

    list functions = [
        "acos",
        "anglebetween",
        "asin",
        "atan2",
        "cos",
        "dist",
        "mag",
        "norm",
        "sin",
        "sqrt",
        "tan"
    ];

    //  Link messages

    //  Calculator messages

    integer LM_CA_INIT = 210;       // Initialise script
    integer LM_CA_RESET = 211;      // Reset script
    integer LM_CA_STAT = 212;       // Print status
    integer LM_CA_COMMAND = 213;    // Submit calculator command
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

    string eff(float f) {
        return ef((string) f);
    }

    string efr(rotation r) {
        return efv(llRot2Euler(r) / angleScale);
    }

    string efe(rotation r) {
        string eu = efr(r);
        return "{" + llGetSubString(eu, 1, -2) + "}";
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

    //  showStatus  --  Show status on local chat

    showStatus() {
        integer mylink = llGetLinkNumber();
        string lex = "";
        if (mylink == 0) {
            lex = " (not linked)";
        } else {
            if (mylink == LINK_ROOT) {
                lex = " (root prim)";
            }
            lex += " of " + (string) llGetObjectPrimCount(llGetKey());
        }
        tawk("Calculator status for " + llGetObjectName() + ":" +
            " link number " + (string) mylink + lex);

        //  If in link set, list link numbers, names, positions, and rotations
        if (mylink > 0) {
            integer n = llGetObjectPrimCount(llGetKey());
            integer l;

            for (l = 1; l <= n; l++) {
                list pinfo = llGetLinkPrimitiveParams(l,
                    [ PRIM_NAME, PRIM_POS_LOCAL, PRIM_ROT_LOCAL ]);
                string meflag = ".";
                if (l == mylink) {
                    meflag = "*";
                }
                tawk("    " + (string) l + meflag + "  " + llList2String(pinfo, 0) +
                    "  " + efv(llList2Vector(pinfo, 1)) +
                    " " + efe(llList2Rot(pinfo, 2)));
            }
        }

        if (llGetListLength(undoList) > 0) {
            tawk("  Undo list length: " + (string) (llGetListLength(undoList) / 3));
        }

        string angUnit = "radians";
        if (angleScale < 1) {
            angUnit = "degrees";
        }
        tawk("  Angles: " + angUnit);

        integer mFree = llGetFreeMemory();
        integer mUsed = llGetUsedMemory();
        tawk("  Script memory.  Free: " + (string) mFree +
                "  Used: " + (string) mUsed + " (" +
                (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
        );
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

    //  checkAccess  --  Check if user has permission to send commands

    integer checkAccess(key id) {
        return (restrictAccess == 0) ||
               ((restrictAccess == 1) && llSameGroup(id)) ||
               (id == llGetOwner());
    }

    /*  fixArgs  --  Transform command arguments into canonical form.
                     All white space within vector and rotation brackets
                     is elided so they will be parsed as single arguments.  */

    string fixArgs(string cmd) {
        cmd = llToLower(llStringTrim(cmd, STRING_TRIM));
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

    /*  parseCalcArg  --  Parse a calculator argument and return a list
                          of type and value.  */

    list parseCalcArg(string a) {

        //  Substitute symbolic constants with numeric values

        integer n = llGetListLength(kpool);
        integer i;
        integer found1 = TRUE;

        while (found1) {
            found1 = FALSE;
            for (i = 0; i < n; i += 2) {
                integer k = llSubStringIndex(a, llList2String(kpool, i));
                if (k >= 0) {
                    integer l = llStringLength(llList2String(kpool, i));
                    string b = "";
                    if (k > 0) {
                        b = llGetSubString(a, 0, k - 1);
                    }
                    b += eff(llList2Float(kpool, i + 1));
                    integer e = k + l;
                    if (e < llStringLength(a)) {
                        b += llGetSubString(a, e, -1);
                    }
                    a = b;
                    found1 = TRUE;
                    i = n;                  // Escape loop
                }
            }
        }

        string c1 = llGetSubString(a, 0, 0);

        //  Vector or quarternion rotation
        if (c1 == "<") {
            if ((llGetSubString(a, -1, -1) != ">") ||
                (llSubStringIndex(a, ">") < (llStringLength(a) - 1))) {
                return [ "?", a ];                  // Unclosed or embedded bracket
            }
            list comps = llParseString2List(a, [ "," ], []);
            integer compn = llGetListLength(comps); // Number components

            if (compn == 3) {
                //  3-Vector
                return [ "v", (vector) a ];
            } else if (compn == 4) {
                //  Quaternion rotation: note that we do not normalise
                return [ "r", (rotation) a ];
            }

        //  Rotation by Euler angles
        } else if (c1 == "{") {
            if (llGetSubString(a, -1, -1) != "}" ||
                (llSubStringIndex(a, "}") < (llStringLength(a) - 1)) ||
                (llGetListLength(llParseString2List(a, [ "," ], [])) != 3)) {
                return [ "?", a ];                  // Unclosed or embedded bracket
            }
            //  Rotation from Euler angles
            return [ "r", llEuler2Rot(((vector) ("<" + llGetSubString(a, 1, -2) + ">")) *
                angleScale) ];

        //  Operator
        } else if ((llStringLength(a) == 1) && (llSubStringIndex("+-*/%", c1) >= 0)) {
            return [ "o", c1 ];

        //  Floating point number
        } else if (llSubStringIndex("0123456789.-", c1) >= 0) {
            return [ "f", (float) a ];
        //  ZERO_VECTOR
        } else if (abbrP(a, "zero_v")) {
            return [ "v", ZERO_VECTOR ];
        //  ZERO_ROTATION
        } else if (abbrP(a, "zero_r")) {
            return [ "r", ZERO_ROTATION ];

        //  Function name
        } else if (llListFindList(functions, [ a ]) >= 0) {
            return [ "u", a ];

        //  Local position or rotation of link

        } else if (abbrP(a, "pos(")) {
            integer lno = (integer) llGetSubString(a, 4, -2);
            return [ "v", llList2Vector(llGetLinkPrimitiveParams(lno,
                [ PRIM_POS_LOCAL ]), 0) ];
        } else if (abbrP(a, "rot(")) {
            integer lno = (integer) llGetSubString(a, 4, -2);
            return [ "r", llList2Rot(llGetLinkPrimitiveParams(lno,
                [ PRIM_ROT_LOCAL ]), 0) ];

        //  Region position or rotation of link

        } else if (abbrP(a, "gpos(")) {
            integer lno = (integer) llGetSubString(a, 5, -2);
            return [ "v", llList2Vector(llGetLinkPrimitiveParams(lno,
                [ PRIM_POSITION ]), 0) ];
        } else if (abbrP(a, "grot(")) {
            integer lno = (integer) llGetSubString(a, 5, -2);
            return [ "r", llList2Rot(llGetLinkPrimitiveParams(lno,
                [ PRIM_ROTATION ]), 0) ];

        //  Last result
        } else if (c1 == "$") {
            return lastres;
        }
        return [ "?", a ];              // Can't make hide or hair of it
    }

    //  processCommand  --  Process a command

    integer processCommand(key id, string message, integer fromLink) {

        if (!checkAccess(id)) {
            llRegionSayTo(id, PUBLIC_CHANNEL,
                "You do not have permission to control this object.");
            return FALSE;
        }

        whoDat = id;            // Direct chat output to sender of command

        /*  If echo is enabled, echo command to sender unless
            prefixed with "@".  The command is prefixed with ">>"
            if entered from chat or "++" if from a script.  */

        integer echoCmd = TRUE;
        if (llGetSubString(llStringTrim(message, STRING_TRIM_HEAD), 0, 0) == "@") {
            echoCmd = FALSE;
            message = llGetSubString(llStringTrim(message, STRING_TRIM_HEAD), 1, -1);
        }
        if ((!fromLink) && echo && echoCmd) {
            string prefix = ">> /" + (string) commandChannel + " ";
            tawk(prefix + message);                 // Echo command to sender
        }

        string lmessage = fixArgs(message);
        list args = llParseString2List(lmessage, [ " " ], []);    // Command and arguments
        string command = llList2String(args, 0);    // The command
        string sparam = llList2String(args, 1);     // First argument, for convenience
        integer argn = llGetListLength(args);       // Number of arguments

        if (abbrP(command, "ca") && (argn > 1)) {
            if (llListFindList(
                [ "ac", "bo", "ca", "ch", "cl", "he",
                  "se", "st", "un" ], [ llGetSubString(sparam, 0, 1) ]) >= 0) {
                args = llList2List(args, 1, -1);
                command = llList2String(args, 0);
                sparam = llList2String(args, 1);     // First argument, for convenience
                argn--;
            }
        }

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

        /*  Calc value1 op value2
                 function value1
                 function value1 value2  */

        } else if (abbrP(command, "ca")) {
            integer i;
            string at = "";         // Argument types signature
            list al = [ ];          // Argument list
            integer an = 0;         // Argument count

            for (i = 1; i < argn; i++) {
                list argl = parseCalcArg(llList2String(args, i));
                if ((llGetListLength(argl) == 2) && (llList2String(argl, 0) != "?")) {
                    at += llList2String(argl, 0);   // Append argument type
                    al += llList2List(argl, 1, 1);  // Append argument value, whatever the type
                    an++;
                } else {
                    tawk("Error parsing Calc argument " + (string) i + " \"" +
                        llList2String(args, i) + "\".");
                    return FALSE;
                }
            }

            string arg1 = "";
            string arg2 = "";
            string res = "";
            string op = "";

            if ((llGetSubString(at, 1, 1) == "o") && (an == 3)) {
                op = llList2String(al, 1);
            }

            //  Two operand infix operators

            if (at == "ror") {
                rotation r1 = llList2Rot(al, 0);
                rotation r2 = llList2Rot(al, 2);
                arg1 = efe(r1);
                arg2 = efe(r2);
                //  {x1, y1, z1} * {x2, y2, z2}     Compose rotation
                if (op == "*") {
                    res = efe(r1 * r2);
                    lastres = [ "r", r1 * r2 ];
                //  {x1, y2, z1} / {x2, y2, z2}     Compose inverse rotation
                } else if (op == "/") {
                    res = efe(r1 / r2);
                    lastres = [ "r", r1 / r2 ];
                }
            } else if (at == "vor") {
                vector v1 = llList2Vector(al, 0);
                rotation r2 = llList2Rot(al, 2);
                arg1 = efv(v1);
                arg2 = efe(r2);
                //  <x1, y1, z1> * {x2, y2, z2}     Rotate vector by rotation
                if (op == "*") {
                    res = efv(v1 * r2);
                    lastres = [ "v", v1 * r2 ];
                //  <x1, y1, z1> / {x2, y2, z2}     Rotate vector by inverse rotation
                } else if (op == "/") {
                    res = efv(v1 / r2);
                    lastres = [ "v", v1 / r2 ];
                }
            } else if (at == "vov") {
                vector v1 = llList2Vector(al, 0);
                vector v2 = llList2Vector(al, 2);
                arg1 = efv(v1);
                arg2 = efv(v2);
                //  <x1, y1, z1> * <x2, y2, z2>     Dot product of vectors
                if (op == "*") {
                    res = eff(v1 * v2);
                    lastres = [ "v", v1 * v2 ];
                //  <x1, y1, z1> % <x2, y2, z2>     Cross product of vectors
                } else if (op == "%") {
                    res = efv(v1 % v2);
                    lastres = [ "v", v1 % v2 ];
                //  <x1, y1, z1> + <x2, y2, z2>     Component-wise sum of vectors
                } else if (op == "+") {
                    res = efv(v1 + v2);
                    lastres = [ "v", v1 + v2 ];
                //  <x1, y1, z1> - <x2, y2, z2>     Component-wise difference of vectors
                } else if (op == "-") {
                    res = efv(v1 - v2);
                    lastres = [ "v", v1 - v2 ];
                }
            } else if (at == "vof") {
                vector v1 = llList2Vector(al, 0);
                float f2 = llList2Float(al, 2);
                arg1 = efv(v1);
                arg2 = eff(f2);
                //  <x1, y1, z1> * f                Scale vector multiply
                if (op == "*") {
                    res = efv(v1 * f2);
                    lastres = [ "v", v1 * f2 ];
                //  <x1, y1, z1> / f                Scale vector divide
                } else if (op == "/") {
                    res = efv(v1 / f2);
                    lastres = [ "v", v1 / f2 ];
                }
            } else if (at == "fov") {
                float f1 = llList2Float(al, 0);
                vector v2 = llList2Vector(al, 2);
                arg1 = eff(f1);
                arg2 = efv(v2);
                //  f * <x1, y1, z1>                Scale vector multiply
                if (op == "*") {
                    res = efv(f1 * v2);
                    lastres = [ "v", f1 * v2 ];
                }
            } else if (at == "fof") {
                float f1 = llList2Float(al, 0);
                float f2 = llList2Float(al, 2);
                arg1 = eff(f1);
                arg2 = eff(f2);
                //  f1 * f2                         Product of numbers
                if (op == "*") {
                    res = eff(f1 * f2);
                    lastres = [ "f", f1 * f2 ];
                //  f1 / f2                         Quotient of numbers
                } else if (op == "/") {
                    res = eff(f1 / f2);
                    lastres = [ "f", f1 / f2 ];
                //  f1 + f2                         Sum of numbers
                } else if (op == "+") {
                    res = eff(f1 + f2);
                    lastres = [ "f", f1 + f2 ];
                //  f1 - f2                         Difference of numbers
                } else if (op == "-") {
                    res = eff(f1 - f2);
                    lastres = [ "f", f1 - f2 ];
                //  i1 % i2                         Integer modulo integer (fractions truncated)
                } else if (op == "%") {
                    float fmod = ((integer) llFloor(f1)) % ((integer) llFloor(f2));
                    res = eff(fmod);
                    lastres = [ "f", fmod ];
                }

            //  One floating point argument functions

            } else if (at == "uf") {
                string s1 = llList2String(al, 0);
                float f2 = llList2Float(al, 1);
                arg1 = s1;
                arg2 = eff(f2);
                op = s1;

                //  Argument and result are pure numbers
                if (s1 == "sqrt") {
                    float r;
                    res = eff(r = llSqrt(f2));
                    lastres = [ "f", r ];

                //  Argument is angle, result is pure number
                } else if (s1 == "cos") {
                    float r;
                    res = eff(r = llCos(f2 * angleScale));
                    lastres = [ "f", r ];
                } else if (s1 == "sin") {
                    float r;
                    res = eff(r = llSin(f2 * angleScale));
                    lastres = [ "f", r ];
                } else if (s1 == "tan") {
                    float r;
                    res = eff(r = llTan(f2 * angleScale));
                    lastres = [ "f", r ];

                //  Argument is pure number, result is angle
                } else if (s1 == "acos") {
                    float r;
                    res = eff(r = llAcos(f2) / angleScale);
                    lastres = [ "f", r ];
                } else if (s1 == "asin") {
                    float r;
                    res = eff(r = llAsin(f2) / angleScale);
                    lastres = [ "f", r ];
                }

            //  Two floating point argument functions

            } else if (at == "uff") {
                string s1 = llList2String(al, 0);
                float f2 = llList2Float(al, 1);
                float f3 = llList2Float(al, 2);
                op = s1;
                arg1 = eff(f2);
                arg2 = eff(f3);

                //  Arguments pure numbers, returns an angle
                if (s1 == "atan2") {
                    float r;
                    res = eff(r = llAtan2(f2, f3) / angleScale);
                    lastres = [ "f", r ];
                }

            //  One vector argument functions

            } else if (at == "uv") {
                string s1 = llList2String(al, 0);
                vector v2 = llList2Vector(al, 1);
                arg1 = s1;
                arg2 = efv(v2);
                op = s1;

                //  Result is pure number
                if (s1 == "mag") {
                    float r;
                    res = eff(r = llVecMag(v2));
                    lastres = [ "f", r ];
                //  Result is vector
                } else if (s1 == "norm") {
                    res = efv(llVecNorm(v2));
                    lastres = [ "v", llVecNorm(v2) ];
                }

            //  Two vector argument functions

            } else if (at == "uvv") {
                string s1 = llList2String(al, 0);
                vector v2 = llList2Vector(al, 1);
                vector v3 = llList2Vector(al, 2);
                op = s1;
                arg1 = efv(v2);
                arg2 = efv(v3);

                //  Result is pure number
                if (s1 == "dist") {
                    float r;
                    res = eff(r = llVecDist(v2, v3));
                    lastres = [ "f", r ];
                }

            //  Two rotation argument functions

            } else if (at == "urr") {
                string s1 = llList2String(al, 0);
                rotation r2 = llList2Rot(al, 1);
                rotation r3 = llList2Rot(al, 2);
                op = s1;
                arg1 = efr(r2);
                arg2 = efr(r3);

                //  Result is angle
                if (s1 == "anglebetween") {
                    float r;
                    res = eff(r = llAngleBetween(r2, r3) / angleScale);
                    lastres = [ "f", r ];
                }

            //  Single values of various types (queries)

            } else if (at == "f") {
                res =  eff(llList2Float(al, 0));
                lastres = [at, llList2Float(al, 0) ];
            } else if (at == "v") {
                res = efv(llList2Vector(al, 0));
                lastres = [ at, llList2Vector(al, 0) ];
            } else if (at == "r") {
                res = efe(llList2Rot(al, 0)) + "  " + ef((string) llList2Rot(al, 0));
                lastres = [ at, llList2Rot(al, 0) ];
            }

            if (res != "") {
                if (an == 1) {
                    tawk(res);
                } if (an == 2) {
                    tawk(arg1 + "(" + arg2 + ") = " + res);
                } else if (an == 3) {
                    if ((at == "uff") || (at == "urr")) {
                        tawk(op + "(" + arg1 + ", " + arg2 + ") = " + res);
                    } else {
                        tawk(arg1 + " " + op + " " + arg2 + " = " + res);
                    }
                }

                //  Report result to client script(s)
                llMessageLinked(LINK_THIS, LM_CA_RESULT,
                    llList2Json(JSON_ARRAY, lastres), id);

                return TRUE;
            }

            if (llGetSubString(at, 0, 0) == "u") {
                tawk("Function " + llList2String(al, 0) + " not defined for these argument types.");
            } else {
                tawk("Operator " + op + " not defined for these argument types.");
            }
            return FALSE;

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
                if (commandChannel > 1) {
                    commandH = llListen(commandChannel, "", NULL_KEY, "");
                    tawk(llGetScriptName() + " listening on /" + (string) commandChannel);
                }
            }

        //  Clear                   Clear chat for debugging

        } else if (abbrP(command, "cl")) {
            tawk("\n\n\n\n\n\n\n\n\n\n\n\n\n");

        //  Help                        Give help information

        } else if (abbrP(command, "he")) {
            llGiveInventory(id, helpFileName);      // Give requester the User Guide notecard

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

            //  Set connection connector_link end_1 end_2       Position connector between two links

            } else if (abbrP(sparam, "co")) {
                integer conlink = (integer) svalue;
                integer end1 = (integer) llList2String(args, 3);
                integer end2 = (integer) llList2String(args, 4);
                integer nlinks = llGetObjectPrimCount(llGetKey());
                if ((conlink >= 1) && (conlink <= nlinks) &&
                    (end1 >= 1) && (end1 <= nlinks) &&
                    (end2 >= 1) && (end2 <= nlinks) &&
                    (conlink != end1) && (conlink != end2) && (end1 != end2)) {
                    undoList = [ "lp", conlink,
                        llList2Vector(llGetLinkPrimitiveParams(conlink,
                            [ PRIM_POS_LOCAL ]), 0) ] + undoList;
                    undoList = [ "lr", conlink,
                        llList2Rot(llGetLinkPrimitiveParams(conlink,
                            [ PRIM_ROT_LOCAL ]), 0) ] + undoList;
                    if (llGetListLength(undoList) > (maxUndo * 3)) {
                        undoList = llDeleteSubList(undoList, maxUndo, -1);
                    }
                    vector end1p = llList2Vector(llGetLinkPrimitiveParams(end1, [ PRIM_POS_LOCAL ]), 0);
                    vector end2p = llList2Vector(llGetLinkPrimitiveParams(end2, [ PRIM_POS_LOCAL ]), 0);
                    vector newpos = (end1p + end2p) / 2;        // Mid-position between ends
                    rotation newrot = llRotBetween(<0, 0, 1>, end2p - end1p);
                    vector sizeConn = llList2Vector(llGetLinkPrimitiveParams(conlink, [ PRIM_SIZE ]), 0);
                    sizeConn.z = llVecDist(end1p, end2p);
                    llSetLinkPrimitiveParamsFast(conlink,
                        [ PRIM_POS_LOCAL, newpos, PRIM_ROT_LOCAL, newrot, PRIM_SIZE, sizeConn ]);
                } else {
                    tawk("Invalid link numbers.");
                    return FALSE;
                }


            //  Set link [ from/off to ]    Listen and display link messages with from <= num <= to

            } else if (abbrP(sparam, "li")) {
                if (argn < 3) {                     // No argument: show range
                    if (linkTo < linkFrom) {
                        tawk("Link message monitoring off.");
                    } else {
                        tawk("Monitoring link messages from " + (string) linkFrom +
                             " to " + (string) linkTo + ".");
                    }
                } else {
                    if (abbrP(svalue, "of")) {      // Off: disable monitoring
                        linkFrom = 0;
                        linkTo = -1;
                    } else {                        // From [ to ]: set monitor range
                        linkFrom = (integer) svalue;
                        if (argn >= 4) {
                            linkTo = (integer) llList2String(args, 3);
                        } else {
                            linkTo = linkFrom;
                        }
                    }
                }

            //  Set pos linkno <position>   Set local position of link

            } else if (abbrP(sparam, "po")) {
                integer linkno = (integer) svalue;
                if ((linkno >= 1) && (linkno <= llGetObjectPrimCount(llGetKey()))) {
                    list al = parseCalcArg(llList2String(args, 3));
                    if (llList2String(al, 0) != "v") {
                        tawk("Not a vector.");
                        return FALSE;
                    }
                    undoList = [ "lp", linkno,
                        llList2Vector(llGetLinkPrimitiveParams(linkno,
                            [ PRIM_POS_LOCAL ]), 0) ] + undoList;
                    if (llGetListLength(undoList) > (maxUndo * 3)) {
                        undoList = llDeleteSubList(undoList, maxUndo, -1);
                    }
                    llSetLinkPrimitiveParamsFast(linkno, [ PRIM_POS_LOCAL, llList2Vector(al, 1) ]);
                } else {
                    tawk("Invalid link number.");
                    return FALSE;
                }

            //  Set rot linkno <rotation>   Set local rotation of link

            } else if (abbrP(sparam, "ro")) {
                integer linkno = (integer) svalue;
                if ((linkno >= 1) && (linkno <= llGetObjectPrimCount(llGetKey()))) {
                    list al = parseCalcArg(llList2String(args, 3));
                    if (llList2String(al, 0) != "r") {
                        tawk("Not a rotation.");
                        return FALSE;
                    }
                    undoList = [ "lr", linkno,
                        llList2Rot(llGetLinkPrimitiveParams(linkno,
                            [ PRIM_ROT_LOCAL ]), 0) ] + undoList;
                    if (llGetListLength(undoList) > (maxUndo * 3)) {
                        undoList = llDeleteSubList(undoList, maxUndo, -1);
                    }
                    llSetLinkPrimitiveParamsFast(linkno, [ PRIM_ROT_LOCAL, llList2Rot(al, 1) ]);
                } else {
                    tawk("Invalid link number.");
                    return FALSE;
                }

            //  Set trace on/off

            } else if (abbrP(sparam, "tr")) {
                trace = onOff(svalue);

            } else {
                tawk("Invalid.  Set angles/pos/rot/trace");
                return FALSE;
            }

        //  Status

        } else if (abbrP(command, "st")) {
            showStatus();

        //  Undo

        } else if (abbrP(command, "un")) {
            if (llGetListLength(undoList) == 0) {
                tawk("Nothing to undo.");
            } else {
                string what = llList2String(undoList, 0);
                integer linkno = llList2Integer(undoList, 1);

                if (what == "lp") {
                    //  Local position
                     llSetLinkPrimitiveParamsFast(linkno,
                        [ PRIM_POS_LOCAL, llList2Vector(undoList, 2) ]);
                } else if (what == "lr") {
                    //  Local rotation
                     llSetLinkPrimitiveParamsFast(linkno,
                        [ PRIM_ROT_LOCAL, llList2Rot(undoList, 2) ]);
                }

                undoList = llDeleteSubList(undoList, 0, 2);
            }

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
            whoDat = owner = llGetOwner();

            //  Start listening on the command chat channel
            if (commandChannel > 1) {
                commandH = llListen(commandChannel, "", NULL_KEY, "");
                llOwnerSay(llGetScriptName() + " listening on /" + (string) commandChannel);
            }
        }

        /*  The listen event handler processes messages from
            our chat control channel.  */

        listen(integer channel, string name, key id, string message) {
            processCommand(id, message, FALSE);
        }

        //  Monitor link messages and dump any within selected num range

        link_message(integer sender, integer num, string str, key id) {
            if ((num >= linkFrom) && (num <= linkTo)) {
                tawk("Link message from sender " + (string) sender +
                     " num: " + (string) num + " str \"" + str + "\" key " +
                     (string) id);
            }

            //  LM_CA_INIT (210): Initialise

            if (num == LM_CA_INIT) {

            //  LM_CA_RESET (211): Reset script

            } else if (num == LM_CA_RESET) {
                llResetScript();

            //  LM_CA_STAT (212): Show status on local chat

            } else if (num == LM_CA_STAT) {
                whoDat = id;
                showStatus();

            //  LM_CA_COMMAND (213): Submit calculator command

            } else if (num == LM_CA_COMMAND) {
                processCommand(id, str, TRUE);

            }
        }
    }
