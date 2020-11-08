/*

                    BVH Animation Utilities

        This program allows reading something like Second Life
        animation definitions (BVH files) from notecards.  A
        few notes are in order.  First of all, this is not a
        general-purpose BVH reader: it understands the hierarchy
        format which appears in Second Life's definition files
        for its internal animations and makes no guarantees
        about those created with other tools.  Second, because
        everything in Second Life seems bent on reminding you
        of those halcyon days of the Commodore 64, lines read from
        notecards are silently truncated at 255 characters, which
        means the long lines used to define motion channels in BVH
        files cannot be read without loss of data.

        To cope with this, files must be pre-processed by a Perl
        program, bvh_to_bvm.pl, which splits the frame motion records
        into three numbers per line, which this program is clever
        enough to know how to read.  Fortunately, Second Life strings
        are limited only by script memory, so we can read the
        continuation lines and assemble them into a complete line
        prior to parsing.

        Another extension is a new optional statement in the
        MOTION section:
            Vscale: n
        which specifies, as a floating point number, the scale
        factor to be used with positions specified for the ROOT
        joint (usually the hip) of the hierarchy.  This allows the
        model to translate from frame to frame, but the BVH standard
        specifies no scale factor for these values.  In order for the
        animation to work as intended, the position values in each
        frame should be scaled to the co-ordinate of the corresponding
        joint (hip) in the model.  We can't infer the scale from the
        channel records, since there's no guarantee the model starts
        at full height (the animation might, for example, be standing
        up from a sitting position, or fiddling with the hands while
        seated).

        The Second Life standard animations seem to assume a hip
        height scale factor of 43.568405, which roughly corresponds
        to centimetres for a person of typical stature.  (Which is
        odd, in itself, since Second Life uses metres everywhere.)
        I haven't seen this specified anywhere, but this is the
        hip height used in the Standard Avatar T-pose animation
        (SL_Avatar_Tpose.bvh), and most of the other animations which
        start from a near-standard position have an initial hip
        height co-ordinate near this.

        The Vscale statement allows you to specify the vertical scale
        for animations.  If none is specified, the Second Life
        default of 43.568405 is used.

*/

    key owner;                      // Owner UUID
    key whoDat = NULL_KEY;          // Avatar who sent command

/* IF COMMAND_PROCESSOR
    integer commandChannel = 42;    // Command channel in chat (answer to Ultimate Question)
    integer commandH;               // Handle for command channel
    integer echo = TRUE;            // Echo chat and script commands ?
    integer trace = FALSE;          // Trace operation ?
    integer restrictAccess = 0;     // Access restriction: 0 none, 1 group, 2 owner
/* END COMMAND_PROCESSOR */

    string ncSource = "";           // Current notecard being read
    key ncQuery;                    // Handle for notecard query
    integer ncLine = 0;             // Current line in notecard

    integer bvhState = 0;           // BVH parser state

    //  Link messages

    //  Animation BVH messages

//  integer LM_AB_INIT = 140;       // Initialise script
//  integer LM_AB_RESET = 141;      // Reset script
    integer LM_AB_STAT = 142;       // Print status
    integer LM_AB_LOAD = 143;       // Load and process BVH file from notecard
    integer LM_AB_FRAME = 144;      // Load channel settings for frame
    integer LM_AB_LOADED = 145;     // BVH load complete
    integer LM_AB_FRAME_LOADED = 146;   // BVH frame load complete

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

    string eff(float f) {
        return ef((string) f);
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

/* IF COMMAND_PROCESSOR
    //  checkAccess  --  Check if user has permission to send commands

    integer checkAccess(key id) {
        return (restrictAccess == 0) ||
               ((restrictAccess == 1) && llSameGroup(id)) ||
               (id == llGetOwner());
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

    /*  inventoryName  --   Extract inventory item name from Set subcmd.
                            This is a horrific kludge which allows
                            names to be upper and lower case.  It finds the
                            subcommand in the lower case command then
                            extracts the text that follows, trimming leading
                            and trailing blanks, from the upper and lower
                            case original command.   *_/

    string inventoryName(string subcmd, string lmessage, string message) {
        //  Find subcommand in Set subcmd ...
        integer dindex = llSubStringIndex(lmessage, subcmd);
        //  Advance past space after subcmd
        dindex += llSubStringIndex(llGetSubString(lmessage, dindex, -1), " ") + 1;
        //  Note that STRING_TRIM elides any leading and trailing spaces
        return llStringTrim(llGetSubString(message, dindex, -1), STRING_TRIM);
    }
/* END COMMAND_PROCESSOR */

    //  processNotecardCommands  --  Read and execute commands from a notecard

    processNotecardCommands(string ncname) {
        ncSource = ncname;
        ncLine = 0;
        tawk("Loading animation: " + ncSource);
        bvhState = 0;                       // Waiting for start of hierarchy
        ncQuery = llGetNotecardLine(ncSource, ncLine);
        ncLine++;
    }

    goof(string oops) {
        tawk("BVH error on line " + (string) ncLine + ": " + oops);
        bvhState = -1;      // Error in BVH file
    }

    //  processNotecardLine  --  Process line from notecard

    string bvhName;         // BVH current object name
    integer bvhDepth;       // BVH current tree depth
    vector bvhOffset;       // BVH current object offset
    integer bvhNchans;      // BVH current number of channels
    string bvhChans;        // BVH current channel names

    string bvhFile;         // BVH file loaded
    list bvhTree;           // BVH hierarchy tree
    integer bvhTchans;      // BVH total channels defined
    integer bvhFrames;      // BVH number of frames
    float bvhFrameTime;     // BVH frame time in seconds
    float bvhVscale = 43.568405;    // Extension: vertical scale in hip position
    integer bvhFirstFrame;  // Line number of first frame definition
    integer bvhLinesPerFrame;   // Lines per frame, due to continuation
    integer bvhFrameLine;   // Frame line accumulation counter
    string bvhFrameRec;     // Frame record assembly buffer

    integer bvhLoadPending; // BVH file load in progress
    integer bvhFramePending;    // BVH frame load in progress

    integer processNotecardLine(string s) {
//        tawk("-- " + s);
        list args = llParseString2List(s, [ " " ], []);
        integer argn = llGetListLength(args);       // Number of arguments
        string arg0 = llList2String(args, 0);

        //  State 0: Waiting for HIERARCHY

        if (bvhState == 0) {
            if (arg0 == "HIERARCHY") {
                bvhFile = ncSource;
                bvhState = 1;           // Waiting for ROOT
                bvhTree = [ ];
                bvhTchans = 0;          // Clear total channels
            } else {
                goof("HIERARCHY declaration missing.");
                return FALSE;
            }

        //  State 1: Waiting for ROOT

        } else if (bvhState == 1) {
            if (arg0 == "ROOT") {
                string rname = llList2String(args, 1);
                if (rname != "hip") {
                    goof("ROOT object is not hip.");
                    return FALSE;
                }
                bvhState = 2;           // Processing hierarchy body
                bvhName = rname;
                bvhDepth = 0;
            } else {
                goof("ROOT declaration missing.");
                return FALSE;
            }

        //  State 2: Processing body of hierarchy

        } else if (bvhState == 2) {
            if (arg0 == "{") {
                bvhDepth++;
            } else if (arg0 == "}") {
                bvhDepth--;
                if (bvhDepth < 0) {
                    goof("Tree nesting underflow: extra \"}\".");
                    return FALSE;
                }
                if (bvhName == "End Site") {
                    bvhName = "";
                }
            } else if (arg0 == "OFFSET") {
                bvhOffset = < (float) llList2String(args, 1),
                              (float) llList2String(args, 2),
                              (float) llList2String(args, 3) >;
            } else if (arg0 == "CHANNELS") {
                bvhNchans = (integer) llList2String(args, 1);   // Number of channels
                if ((bvhNchans == 3) || ((bvhNchans == 6) && (bvhName == "hip"))) {
                    integer i;
                    bvhChans = "";
                    for (i = 2; i < argn; i++) {
                        bvhChans += llList2String(args, i) + ",";
                    }
                    bvhChans = llGetSubString(bvhChans, 0, -2);
                    bvhTchans += bvhNchans;
                } else {
                    goof("Unexpected number of channels: must be 6 for root, 2 for other joints.");
                    return FALSE;
                }
            } else if ((arg0 == "JOINT") || ((arg0 == "End") &&
                (llList2String(args, 1) == "Site"))) {
                if (bvhName != "") {
                    bvhTree += [ bvhName, bvhDepth, bvhOffset, bvhNchans, bvhChans ];
                }
                bvhName = llList2String(args, 1);
                if (arg0 == "End") {
                    bvhName = "End Site";
                }

            } else if (arg0 == "MOTION") {
                if (bvhName != "") {
                    goof("Last joint (" + bvhName + ") definition incomplete.");
                    return FALSE;
                }
                if (bvhDepth != 0) {
                    goof("Hierarchy tree nesting incomplete (" +
                        (string) bvhDepth + " missing \"}\").");
                    return FALSE;
                }
                bvhState = 3;           // Processing MOTION header
            }

        //  State 3: Processing header of MOTION section

        } else if (bvhState == 3) {
            if (arg0 == "Frames:") {
                bvhFrames = (integer) llList2String(args, 1);
            } else if ((arg0 == "Frame") && (llList2String(args, 1) == "Time:")) {
                bvhFrameTime = (float) llList2String(args, 2);
            } else if (arg0 == "Vscale:") {
                bvhVscale = (float) llList2String(args, 1);
            } else {
                bvhFirstFrame = ncLine - 1;
                bvhLinesPerFrame = (bvhTchans + 2) / 3; // Notecard lines per frame record
                bvhState = 4;           // Header processing complete
                tawk("Animation " + bvhFile + " loaded, " + (string) bvhFrames +
                    " frames, " + (string) llRound(1 / bvhFrameTime) + " frames/second.");
                if (bvhLoadPending) {
                    bvhLoadPending = FALSE;
// tawk("bvhTree length " + (string) llGetListLength(bvhTree));
                    //  Report animation header to requesting script
                    llMessageLinked(LINK_THIS, LM_AB_LOADED,
                        llList2Json(JSON_ARRAY,
                            [  TRUE,                // Load completed successfully
                               llGetListLength(bvhTree) / 5,    // Number of nodes in hierarchy tree
                               bvhFrames,           // Frames in animation
                               bvhFrameTime,        // Time per frame
                               bvhVscale            // Vertical scale
                            ] + bvhTree),           // Hierarchy tree
                            owner);
                }
            }
        }
        return TRUE;
    }

    //  bvhFrame  --  Request channel definition for a frame

    integer bvhFrame(integer frameno) {
        if (bvhState == 4) {
            if ((frameno < 0) || (frameno >= bvhFrames)) {
                tawk("bvhFrame: Frame number out of range.");
            } else {
                bvhFrameLine = 0;
                bvhFrameRec = "";
                ncLine = bvhFirstFrame + (frameno * bvhLinesPerFrame);
                ncQuery = llGetNotecardLine(ncSource, ncLine);
                ncLine++;
                return TRUE;
            }
        } else {
            tawk("bvhFrame: No BVH file loaded.");
        }
        return FALSE;
    }

    //  processFrame  --  Process BVH frame motion record

    list currentFrame;

    processFrame(string frec) {
//tawk("Frame " + frec);
//tawk("Tree: " + llList2CSV(bvhTree));
        list args = llParseString2List(frec, [ " " ], []);
        integer argn = llGetListLength(args);       // Number of arguments

        /*  Walk through the hierarchy and extract channel settings
            for each joint.  */

        integer i;
        integer n = llGetListLength(bvhTree);
        integer p = 0;
        currentFrame = [ ];

        for (i = 0; i < n; i += 5) {
            integer nc = llList2Integer(bvhTree, i + 3);
            //  Append joint name, number of channels
            currentFrame += [ llList2String(bvhTree, i), nc ];
            integer j;
            for (j = 0; j < nc; j++) {
                if (j >= argn) {
                    tawk("Frame record is incomplete.");
                    currentFrame = [ ];
                    i = n;
                }
                currentFrame += [ (float) llList2String(args, p) ];    // Append channel setting
                p++;
            }
        }

        //  If frame load pending, return frame to client

        if (bvhFramePending) {
            bvhFramePending = FALSE;
            llMessageLinked(LINK_THIS, LM_AB_FRAME_LOADED,
                llList2Json(JSON_ARRAY,
                    [  TRUE             // BVH frame loaded successfully
                    ] + currentFrame),
                    owner);

        //  Otherwise, dump the frame to local chat

        } else {
            p = 0;
            for (i = 0; i < n; i += 5) {
                integer nc;
                string indent = "";
                for (nc = 0; nc < llList2Integer(bvhTree, i + 1); nc++) {
                    indent += "  ";
                }
                string r = indent + llList2String(currentFrame, p) + " (" +
                                (string) (nc = llList2Integer(currentFrame, p + 1)) +
                    "): ";
                p += 2;
                integer j;
                for (j = 0; j < nc; j++) {
                    r += eff((float) llList2Float(currentFrame, p)) + ", ";
                    p++;
                }
                r = llGetSubString(r, 0, -3);
                tawk(r);
            }
        }
    }

    /*  showStatus  --  Send script status to local chat  */

    showStatus() {
        tawk("Animation BVH status:");
        if (bvhState == 0) {
            tawk("  No BVH file loaded.");
        } else if (bvhState == -1) {
            tawk("  Error loading BVH file " + bvhFile);
        } else if (bvhState == 4) {
            tawk("  BVH file loaded: " + bvhFile);
            tawk("    Nodes: " + (string) (llGetListLength(bvhTree) / 5) +
                 " Frames: " + (string) bvhFrames + " Frame time: " + eff(bvhFrameTime) +
                 " Channels: " + (string) bvhTchans +
                 " Vscale: " + (string) bvhVscale);
            tawk("    Frames start at line: " + (string) bvhFirstFrame);
        } else {
            tawk("  Currently loading BVH file " + bvhFile + ".  Please stand by.");
        }

        integer mFree = llGetFreeMemory();
        integer mUsed = llGetUsedMemory();
        tawk("  Script memory.  Free: " + (string) mFree +
                "  Used: " + (string) mUsed + " (" +
                (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
        );
    }

/* IF COMMAND_PROCESSOR

    /*  processCommand  --  Process a command from chat.

                            Note that the command processor is
                            fundamentally a debugging tool.  If
                            and when this module becomes an opaque
                            component used entirely by other scripts
                            via its link message interface, all of
                            this code may be disabled.  *_/

    integer processCommand(key id, string message) {

        if (!checkAccess(id)) {
            llRegionSayTo(id, PUBLIC_CHANNEL,
                "You do not have permission to control this object.");
            return FALSE;
        }

        whoDat = id;            // Direct chat output to sender of command

        /*  If echo is enabled, echo command to sender unless
            prefixed with "@".  The command is prefixed with ">>"
            if entered from chat or "++" if from a script.  *_/

        integer echoCmd = TRUE;
        if (llGetSubString(llStringTrim(message, STRING_TRIM_HEAD), 0, 0) == "@") {
            echoCmd = FALSE;
            message = llGetSubString(llStringTrim(message, STRING_TRIM_HEAD), 1, -1);
        }
        if (echo && echoCmd) {
            tawk(">> /" + (string) commandChannel + " " + message); // Echo command to sender
        }

        string lmessage = llStringTrim(llToLower(message), STRING_TRIM);
        list args = llParseString2List(lmessage, [ " " ], []);    // Command and arguments
//      integer argn = llGetListLength(args);       // Number of arguments
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

        /*  Channel n               Change command channel.  Note that
                                    the channel change is lost on a
                                    script reset.  *_/

        } else if (abbrP(command, "ch")) {
            integer newch = (integer) sparam;
            if ((newch < 2)) {
                tawk("Invalid channel " + (string) newch + ".");
                return FALSE;
            } else {
                llListenRemove(commandH);
                commandChannel = newch;
                commandH = llListen(commandChannel, "", NULL_KEY, "");
                tawk("Animation BVH listening on /" + (string) commandChannel);
            }

        //  Clear                   Clear chat for debugging

        } else if (abbrP(command, "cl")) {
            tawk("\n\n\n\n\n\n\n\n\n\n\n\n\n");

        //  Frame n                 Examine frame n from  BVH file

        } else if (abbrP(command, "fr")) {
            integer frameno = (integer) sparam;
            bvhFrame(frameno);

        //  Load                   Load BVH file for processing

        } else if (abbrP(command, "lo")) {
            processNotecardCommands(inventoryName("lo", lmessage, message));

        //  Set                     Set parameter

        } else if (abbrP(command, "se")) {
            string svalue = llList2String(args, 2);

                //  Set trace on/off

                if (abbrP(sparam, "tr")) {
                    trace = onOff(svalue);

                } else {
                    tawk("Invalid.  Set trace");
                    return FALSE;
                }

        //  Status

        } else if (abbrP(command, "st")) {
            showStatus();

        } else {
            tawk("Huh?  \"" + message + "\" undefined.  Chat /" +
                (string) commandChannel + " help for instructions.");
            return FALSE;
        }
        return TRUE;
    }
/* END COMMAND_PROCESSOR */

    default {

        on_rez(integer n) {
            llResetScript();
        }

        state_entry() {
            whoDat = owner = llGetOwner();

/* IF COMMAND_PROCESSOR
            //  Start listening on the command chat channel
            commandH = llListen(commandChannel, "", NULL_KEY, "");
            llOwnerSay("Animation BVH listening on /" + (string) commandChannel);
/* END COMMAND_PROCESSOR */
        }

/* IF COMMAND_PROCESSOR
        /*  The listen event handler processes messages from
            our chat control channel.  *_/

        listen(integer channel, string name, key id, string message) {
            processCommand(id, message);
        }
/* END COMMAND_PROCESSOR */

        /*  The link_message() event receives commands from other scripts
            script and passes them on to the script processing functions
            within this script.  */

        link_message(integer sender, integer num, string str, key id) {

            //  LM_AB_STAT (142): Show script status

            if (num == LM_AB_STAT) {
                whoDat = id;
                showStatus();

            //  LM_AB_LOAD (143): Load animation from BVH file in notecard

            } else if (num == LM_AB_LOAD) {
                bvhLoadPending = TRUE;
                processNotecardCommands(str);

            //  LM_AB_FRAME (144): Return frame information from current animation

            } else if (num == LM_AB_FRAME) {
                bvhFramePending = TRUE;
                if (!bvhFrame((integer) str)) {
                    bvhFramePending = FALSE;
                    llMessageLinked(LINK_THIS, LM_AB_FRAME_LOADED,
                        llList2Json(JSON_ARRAY, [ FALSE ]), id);    // Error retrieving frame
                }
            }
        }

        //  The dataserver event receives lines from the BVH notecard we're reading

        dataserver(key query_id, string data) {
            if (query_id == ncQuery) {
                if (data == EOF) {
                    tawk("End notecard: " + ncSource);
                    ncSource = "";
                    ncLine = 0;
                } else {
                    string s = llStringTrim(data, STRING_TRIM);
                    if (bvhState == 4) {
//tawk("== (" + (string) (bvhFrameLine + 1) + ") " + s);
                        /*  BVH file loaded: process frame request.  Due to the
                            limit of 255 characters on lines in notecards, we must
                            pre-process original BVH files and split the long frame
                            channel records in the MOTION section onto multiple lines.
                            The following code re-assembles these "chunks" into complete
                            channel lines, performing a sequence number check on them,
                            before eventually passing the complete line to processFrame().  */
                        integer c = llSubStringIndex(s, " #");      // Chunk number comment
                        string csn = llGetSubString(s, c + 3, -1);  // Chunk sequence number
                        integer d;
                        if ((d = llSubStringIndex(csn, " ")) > 0) {
                            csn = llGetSubString(csn, 0, d - 1);    // Trim any comment after sequence number
                        }
                        integer cn = (integer) csn;                 // Chunk number from notecard line
                        if ((cn - 1) != bvhFrameLine) {
                            tawk("Sequence number error on chunk " + (string) (bvhFrameLine + 1) +
                                " of frame at line " + (string) (ncLine - 1) + ".");
                                bvhFramePending = FALSE;
                                llMessageLinked(LINK_THIS, LM_AB_FRAME_LOADED,
                                    llList2Json(JSON_ARRAY, [ FALSE ]), owner);
                                return;
                        }
                        s = llGetSubString(s, 0, c - 1);        // Elide chunk number
                        if (bvhFrameLine > 0) {
                            s = " " + s;
                        }
                        bvhFrameRec += s;
                        bvhFrameLine++;
                        if (bvhFrameLine >= bvhLinesPerFrame) {
                            processFrame(bvhFrameRec);
                        } else {
                            //  Still assembling frame: request next chunk
                            ncQuery = llGetNotecardLine(ncSource, ncLine);
                            ncLine++;
                        }
                    } else {
                        //  Ignore comments and process valid commands
                        if ((llStringLength(s) > 0) && (llGetSubString(s, 0, 0) != "#")) {
                            integer stat = processNotecardLine(s);
                            if (!stat) {
                                tawk("Error: Animation loading disabled.");
                                if (bvhLoadPending) {
                                    bvhLoadPending = FALSE;
                                    llMessageLinked(LINK_THIS, LM_AB_LOADED,
                                        llList2Json(JSON_ARRAY, [ FALSE ]), owner);
                                }
                                return;
                            }
                        }
                    }
                    if (bvhState != 4) {
                        //  Still processing animation header: fetch next line
                        ncQuery = llGetNotecardLine(ncSource, ncLine);
                        ncLine++;
                    }
                }
            }
        }
    }
