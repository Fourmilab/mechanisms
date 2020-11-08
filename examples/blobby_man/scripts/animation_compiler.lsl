    /*

                        Animation Compiler

        The animation compiler receives LM_ME_CHANGED messages while
        the Animation BVH module is playing a transformed BVH animation
        file.  These messages contain the JSON-encoded configuration of
        the mechanism.  This is then encoded and compressed into lists
        which express the positions and rotations of all joints in the
        model.  The lists are output in local chat in a coded form, whence
        they can be copied and fed into the Perl compile_animation.pl
        program, which emits one or more LSL script programs which can
        be compiled and installed in the root prim of the mechanism.
        These scripts can be run with the "Animation run" or "Animation
        repeat" commands to replay the animation at high speed.

        The compression used in compiled animations is documented in
        the source code below, particularly functions compileChanges()
        and optFrame().

    */

    key owner;                      // Owner UUID
    key whoDat = NULL_KEY;          // Avatar who sent command

    /* IF COMMAND_PROCESSOR
    integer commandChannel = 1901;  // Command channel in chat (birth year of Walt Disney)
    integer commandH;               // Handle for command channel
    integer restrictAccess = 0;     // Access restriction: 0 none, 1 group, 2 owner
    integer echo = TRUE;            // Echo chat and script commands ?
    /* END COMMAND_PROCESSOR */

    integer compiledFrameNo;        // Frame number being compiled
    list compiledFrame;             // Compiled frame being assembled

    //  Link messages

    //  Animation Compiler messages

//  integer LM_AC_INIT = 170;       // Initialise script
//  integer LM_AC_RESET = 171;      // Reset script
//  integer LM_AC_STAT = 172;       // Print status
    integer LM_AC_START = 173;      // Start compilation of changes
    integer LM_AC_END = 174;        // End compilation, optimise frame
    integer LM_AC_FRAME = 175;      // Animation frame compilation complete

    //  Mechanisms messages
    integer LM_ME_CHANGED = 130;    // Position/rotation change report to compiler

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

    //  compileStart  --  Start compilation of frame changes

    compileStart(integer frameno) {
        compiledFrameNo = frameno;
        compiledFrame = [ ];
    }

    //  list2CSVdense  --  List to CSV without extra spaces (don't use with strings!)

    string list2CSVdense(list l) {
        string s = llList2CSV(l);
        integer i;

        while ((i = llSubStringIndex(s, " ")) >= 0) {
            s = llDeleteSubString(s, i, i);
        }
        return s;
    }

    //  compileChanges  --  Save mechanism configuration changes for compiler

    compileChanges(list changes) {

        /*  First of all, since lists transmitted via JSON
            have their vectors and rotations flattened into
            strings, re-create their native values in the
            changes list.  */

        list newch = [ ];
        integer n = llGetListLength(changes);
        integer i = 0;
        //  This assumes everything in the list is a key, value pair
        for (i = 0; i < n; i += 2) {
            integer rule = llList2Integer(changes, i);
            if (rule == PRIM_POS_LOCAL) {
                newch += [ rule, (vector) llList2String(changes, i + 1) ];
            } else if (rule == PRIM_ROT_LOCAL) {
                newch += [ rule, (rotation) llList2String(changes, i + 1) ];
            } else {
                newch += llList2List(changes, i, i + 1);
            }
        }
        changes = newch;
        newch = [ ];            // Allow garbage collector to dispose

        /*  Walk through the changes and delete any change
            to a link which is superseded by a subsequent
            change to that link.  */

        integer o = llGetListLength(compiledFrame);

        if (o > 0) {
            n = llGetListLength(changes);
            i = 0;
            integer currentLink = -1;
            while (i < n) {
                integer rule = llList2Integer(changes, i);
                if (rule == PRIM_LINK_TARGET) {
                    currentLink = llList2Integer(changes, i + 1);
                    i += 2;
                } else if ((rule == PRIM_POS_LOCAL) ||
                           (rule == PRIM_ROT_LOCAL)) {
                    /*  This is followed by a vector or rotation, but
                        since we care only about the link number and
                        rule, we may ignore this here.  Now look for
                        an entry in the compiled frame so far with the
                        same link and rule and, if present, delete it.  */
                    integer j = 0;
                    integer oLink = -1;
                    while (j < o) {
                        integer orule = llList2Integer(compiledFrame, j);
                        if (orule == PRIM_LINK_TARGET) {
                            oLink = llList2Integer(compiledFrame, j + 1);
                            j += 2;
                        } else if ((orule == PRIM_POS_LOCAL) ||
                                   (orule == PRIM_ROT_LOCAL)) {
                            if ((orule == rule) && (oLink == currentLink)) {
                                compiledFrame = llDeleteSubList(compiledFrame,
                                    j, j + 1);
                                o -= 2;
                            } else {
                                j += 2;
                            }
                        }
else { tawk("Unexpected rule " + (string) orule + " in compiled changes"); }
                    }
                    i += 2;
                }
else { tawk("Unexpected rule " + (string) rule + " in new changes"); }
            }

            compiledFrame += changes;

            /*  Now, there's one more twist.  Scan the compiled
                frame and elide any void PRIM_LINK_TARGET sequences
                which have been created by deletion of all of their
                contents.  We do this on the concatenated changes
                in order to catch void link containers which span
                the previous and newly added changes.  */

            o = llGetListLength(compiledFrame);
            for (i = 0; i < (o - 2); i += 2) {
                if ((llList2Integer(compiledFrame, i) == PRIM_LINK_TARGET) &&
                    (llList2Integer(compiledFrame, i + 2) == PRIM_LINK_TARGET)) {
                    compiledFrame = llDeleteSubList(compiledFrame, i, i + 1);
                    i -= 2;         // Adjust pointer so we don't skip next rule
                    o -= 2;         // Adjust list length
                }
            }

            /*  Just one more thing....  It's possible our optimisations
                have resulted in two or more consecutive changes to the
                same link, resulting in a redundant PRIM_LINK_TARGET
                specification separated by position or rotation rules.
                Scan for that case and delete the later, nugatory link
                target rule.  */

            currentLink = -1;
            for (i = 0; i < (o - 2); i += 2) {
                if (llList2Integer(compiledFrame, i) == PRIM_LINK_TARGET) {
                    integer oLink = llList2Integer(compiledFrame, i + 1);
                    if (oLink == currentLink) {
                        compiledFrame = llDeleteSubList(compiledFrame, i, i + 1);
                        i -= 2;
                        o -= 2;
                    } else {
                        currentLink = oLink;
                    }
                }
            }

        } else {
            compiledFrame = changes;
        }
    }

    //  compileEnd  --  Complete animation compilation for frame

    compileEnd() {
        string sfn = (string) compiledFrameNo;
        tawk("---------- Frame " + sfn + " ----------");
        list of = optFrame();
        integer o = llGetListLength(of);
        integer i;
        integer l = 0;

        string d = "";
        for (i = 0; i < o; i += 2) {
            integer rule = llList2Integer(of, i);
            if (llStringLength(d) > 200) {
                tawk("-- " + sfn + "." + (string) (l++) + " -- " + d);
                d = "";
            }
            integer opcode = rule & 0xFF;
            if ((opcode == 91) || (opcode == 94)) {
                //  Rules 91 and 94 have two arguments
                d += list2CSVdense(llList2List(of, i, i + 2)) + ",";
                i += 1;
            } else {
                //  All other rules have but one
                d += list2CSVdense(llList2List(of, i, i + 1)) + ",";
            }
        }
        tawk("-- " + sfn + "." + (string) (l++) + " -- " + llGetSubString(d, 0, -2));
        tawk("---------- End frame " + (string) compiledFrameNo +
             ", lines " + (string) l + " ----------");
    }

    //  compRot  --  Compress rotation into our low-precision representation

    integer compRot(rotation r) {
        vector eu = llRot2Euler(r);         // Express as Euler angles (-PI to PI)
        vector seu = (eu * 511) / PI;       // Scale to -511 to + 511
        vector reu = seu + <512, 512, 512>; // Map into 0 - 1023
        return (llRound(reu.x) << 20) | (llRound(reu.y) << 10) | llRound(reu.z);
    }

    //  compPos  --  Compress relative position into 48-bit integer

    list compPos(vector v) {
        list vc = [ ];

        v *= 10000;
        if ((llFabs(v.x) < 32767) &&
            (llFabs(v.y) < 32767) &&
            (llFabs(v.z) < 32767)) {
            vc = [ llRound(v.x) & 0xFFFF,               // Remove sign to avoid confusion
                   (((llRound(v.y) & 0xFFFF) << 16) |   // Must mask lest sign-extension wreck
                   (llRound(v.z) & 0xFFFF)) ];
        }
        return vc;
    }

    /*  optFrame  --   Optimise compiled frame list

            Compressed frame structure:

            Item 0:  integer (cposX << 16) | (linkno << 8) | opcode

            Opcode 91
                Item 1: vector PRIM_POS_LOCAL
                Item 2: integer compRot(PRIM_ROT_LOCAL)

            Opcode 92
                Item 1: vector PRIM_POS_LOCAL

            Opcode 93
                Item 1: integer compRot(PRIM_ROT_LOCAL)

            Opcode 94
                Item 1: integer (cposY << 16) | (cposZ << 16)
                Item 2: integer compRot(PRIM_ROT_LOCAL)

            Opcode 95
                Item 1: integer (cposY << 16) | (cposZ << 16)

            cpos? values are positions compressed as integers from
            +/- 32767 which represent floating point co-ordinates
            obtained by dividing them by 10000.0.  Positions
            containing co-ordinates outside this range are not
            compressed.
    */

    list optFrame() {
        list nframe = [ ];

        integer n = llGetListLength(compiledFrame);
        integer i;

        while (i < n) {
            if ((i < (n - 5)) &&
                    (llList2Integer(compiledFrame, i) == PRIM_LINK_TARGET) &&
                    (llList2Integer(compiledFrame, i + 2) == PRIM_POS_LOCAL) &&
                    (llList2Integer(compiledFrame, i + 4) == PRIM_ROT_LOCAL)) {
                list cpos = compPos(llList2Vector(compiledFrame, i + 3));
                if (cpos == [ ]) {
                    nframe += [ 91 + (llList2Integer(compiledFrame, i + 1) << 8),
                                llList2Vector(compiledFrame, i + 3),
                                compRot(llList2Rot(compiledFrame, i + 5)) ];
                } else {
                    nframe += [ (94 + (llList2Integer(compiledFrame, i + 1) << 8)) |
                                      (llList2Integer(cpos, 0) << 16),
                                llList2Integer(cpos, 1),
                                compRot(llList2Rot(compiledFrame, i + 5)) ];

                }
                i += 6;
            } else if ((i < (n + 3)) &&
                (llList2Integer(compiledFrame, i) == PRIM_LINK_TARGET) &&
                (llList2Integer(compiledFrame, i + 2) == PRIM_POS_LOCAL)) {
                list cpos = compPos(llList2Vector(compiledFrame, i + 3));
                if (cpos == [ ]) {
                    nframe += [ 92 + (llList2Integer(compiledFrame, i + 1) << 8),
                                llList2Vector(compiledFrame, i + 3) ];
                } else {
                    nframe += [ 95 + (llList2Integer(compiledFrame, i + 1) << 8) |
                                     (llList2Integer(cpos, 0) << 16),
                                llList2Integer(cpos, 1) ];
                }
                i += 4;
            } else if ((i < (n + 3)) &&
                (llList2Integer(compiledFrame, i) == PRIM_LINK_TARGET) &&
                (llList2Integer(compiledFrame, i + 2) == PRIM_ROT_LOCAL)) {
                nframe += [ 93 + (llList2Integer(compiledFrame, i + 1) << 8),
                            compRot(llList2Rot(compiledFrame, i + 3)) ];
                i += 4;
            } else {
tawk("Incompressible rule in frame " + (string) compiledFrameNo + ": " +
    llList2CSV(llList2List(compiledFrame, i, i + 1)));
                nframe += llList2List(compiledFrame, i, i + 1);
                i += 2;
            }
        }
        return nframe;
    }

    /* IF ANIM_EXPAND_FRAME

    /*  The following functions expand frames compressed by optFrame()
        into a rule list for llSetLinkPrimitiveParamsFast() to
        set joint positions for the frame.  This code is used in the
        animation player stub embedded in animation scripts, and is
        included here purely for the the purposes of documentation and
        testing.  Any changes in optFrame() which modify its output
        should be handled here and then propagated to the animation
        script stub code.  *_/

    //  expRot  --  Expand compressed rotation into something like the original

    rotation expRot(integer cr) {
        vector icomps = < (float) (cr >> 20),
                          (float) ((cr >> 10) & 1023),
                          (float) (cr & 1023) >;
        icomps -= <512, 512, 512>;      // Re-centre around zero
        icomps *= PI / 511;             // Re-scale to radians
        return llEuler2Rot(icomps);
    }

    //  expPos  --  Expand a 48-bit compressed position into a vector

    vector expPos(integer ix, integer iyz) {
        return < ((ix << 16) >> 16),      // Dirty trick to sign-extend
                 (iyz >> 16),             // Note >> sign-extends
                 ((iyz << 16) >> 16) > / 10000.0;
    }

    /*  expandFrame  --  Expand a compressed frame into a ready-to-use
                         rule list for llSetLinkPrimitiveParamsFast().  *_/

    list expandFrame(list olist) {
        integer i = 0;
        integer n = llGetListLength(olist);
        list exlist = [ ];

        while (i < n) {
            integer rule = llList2Integer(olist, i);
            integer mrule = rule & 0xFF;

            if (mrule == 91) {
                //  (91 | (link << 8)), pos, rot
                exlist += [ PRIM_LINK_TARGET, rule >> 8,
                            PRIM_POS_LOCAL, llList2Vector(olist, i + 1),
                            PRIM_ROT_LOCAL,
                                expRot(llList2Integer(olist, i + 2))
                          ];
                i += 3;

            } else if (mrule == 92) {
                //  (92 | (link << 8)), pos
                exlist += [ PRIM_LINK_TARGET, rule >> 8,
                            PRIM_POS_LOCAL, llList2Vector(olist, i + 1) ];
                i += 2;

            } else if (mrule == 93) {
                //  (93 | (link << 8)), rot
                exlist += [ PRIM_LINK_TARGET, rule >> 8,
                            PRIM_ROT_LOCAL,
                                expRot(llList2Integer(olist, i + 1))
                          ];
                i += 2;

            } else if (mrule == 94) {
                //  (94 | (link << 8) | (compX << 16)), (compY << 16) | (compZ << 16), rot
                exlist += [ PRIM_LINK_TARGET, (rule >> 8) & 0xFF,
                            PRIM_POS_LOCAL,
                                expPos(rule >> 16, llList2Integer(olist, i + 1)),
                            PRIM_ROT_LOCAL,
                                expRot(llList2Integer(olist, i + 2))
                          ];
                i += 3;

            } else if (mrule == 95) {
                //  (95 | (link << 8) | (compX << 16)), (compY << 16) | (compZ << 16)
                exlist += [ PRIM_LINK_TARGET, (rule >> 8) & 0xFF,
                            PRIM_POS_LOCAL,
                                expPos(rule >> 16, llList2Integer(olist, i + 1)) ];
                i += 2;
            } else {
                //  Uncompressed rule, value pair ???
                exlist += llList2List(olist, i, i + 1);
                i += 2;
            }
        }
        return exlist;
    }
    /* END ANIM_EXPAND_FRAME */

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

    /*  processCommand  --  Process a command from chat

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
                tawk("Animation compiler listening on /" + (string) commandChannel);
            }

        //  Clear                   Clear chat for debugging

        } else if (abbrP(command, "cl")) {
            tawk("\n\n\n\n\n\n\n\n\n\n\n\n\n");

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

            tawk("Animation Compiler status:");

            integer mFree = llGetFreeMemory();
            integer mUsed = llGetUsedMemory();
            tawk("  Script memory.  Free: " + (string) mFree +
                    "  Used: " + (string) mUsed + " (" +
                    (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
            );

        //  Test n                  Run test n

        } else if (abbrP(command, "te")) {
//          integer which = (integer) sparam;

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
            tawk("Animation compiler listening on /" + (string) commandChannel);
            /* END COMMAND_PROCESSOR */
        }

        /*  The listen event handler processes messages from
            our chat control channel.  */

        /* IF COMMAND_PROCESSOR
        listen(integer channel, string name, key id, string message) {
            processCommand(id, message);
        }
        /* END COMMAND_PROCESSOR */

        /*  The link_message() event receives commands from other scripts
            script and passes them on to the script processing functions
            within this script.  */

        link_message(integer sender, integer num, string str, key id) {
//tawk("Animation compiler link message sender " + (string) sender + "  num " + (string) num + "  str " + str + "  id " + (string) id);

            //  LM_AC_START (173): Start compiling animation frame

            if (num == LM_AC_START) {
                whoDat = id;
                compileStart((integer) str);

            //  LM_AC_END (174): End compiling animation frame

            } else if (num == LM_AC_END) {
                compileEnd();
                //  The str argument is a flag indicating the last frame
                if ((integer) str) {
                    tawk("---------- Animation compilation complete ----------");
                }
                //  Notify client we're done with this frame
                llMessageLinked(LINK_THIS, LM_AC_FRAME,
                    (string) compiledFrameNo + "," + str, id);

            //  LM_ME_CHANGED (130): Mechanism configuration change report
            } else if (num == LM_ME_CHANGED) {
                compileChanges(llJson2List(str));
            }
        }
    }
