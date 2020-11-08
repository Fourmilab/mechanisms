    /*

                    Fourmilab Blobby Man

         This is a demonstration of Fourmilab Mechanisms
         in the somewhat extreme case of an avatar-like object
         built entirely of basic Second Life prims, using the
         Mechanisms facility for its hierarchical skeleton, and
         able to process and execute Second Life avatar animations
         from their (slightly modified due to restrictions on
         notecard format) BVH source definitions.

         This model is inspired by Jim Blinn's original Blobby Man,
         described in chapter 3 of the book:
            Blinn, Jim.  Jim Blinn's Corner: A Trip Down the Graphics
            Pipeline.  San Francisco: Morgan Kauffmann, 1996.
            ISBN 978-1-55860-387-5.
        The dimensions of components have been altered to work with
        those assumed for Second Life avatars, and joints have been
        introduced between them to permit real-time articulation of
        the components.  The original Blobby Man's shoulders were
        a single rigid component.  Here, we add two separate collar
        bones to agree with the skeleton used in Second Life animations.

    */

    key owner;                      // Owner UUID

    integer commandChannel = 1721;  // Command channel in chat (birth year of Pierre Jaquet-Droz)
    integer commandH;               // Handle for command channel
    key whoDat = NULL_KEY;          // Avatar who sent command
    integer echo = TRUE;            // Echo chat and script commands ?

    integer trace = FALSE;          // Trace operation ?

    list calcResult;                // Last result from calculator

    //  Currently loaded animation

    string animFile = "";           // Animation file name
    integer animNodes;              // Nodes in hierarchy tree
    integer animFrames;             // Frames in animation
    float animTime;                 // Time per frame
    list animTree;                  // Animation hierarchy tree
    float animVscale = 43.568405;   // Vertical scale: hip height in animation model

    integer animFrameNo = -1;       // Currently loaded frame number
    list animFrame;                 // Animation frame channel values
    list jReferenceFrame;           // Reference frame (frame 0) hip channels

    integer jPlaying = FALSE;       // Playing in progress
    integer jCompiling = FALSE;     // Are we compiling as we play ?
    integer jPlayFrameNo;           // Next frame to play
    integer jPlayFrameLast;         // Last frame to play

    integer animRunning = FALSE;    // Are we running a compiled animation ?
    integer animLoop;               // Are we looping animation ?

    //  Script processing

    integer scriptActive = FALSE;   // Are we reading from a script ?
    integer scriptSuspend = FALSE;  // Suspend script execution for asynchronous event

    //  Link messages

    //  Script Processor messages
    integer LM_SP_INIT = 50;            // Initialise
//  integer LM_SP_RESET = 51;           // Reset script
    integer LM_SP_STAT = 52;            // Print status
//  integer LM_SP_RUN = 53;             // Enqueue script as input source
    integer LM_SP_GET = 54;             // Request next line from script
    integer LM_SP_INPUT = 55;           // Input line from script
    integer LM_SP_EOF = 56;             // Script input at end of file
    integer LM_SP_READY = 57;           // Script ready to read
    integer LM_SP_ERROR = 58;           // Requested operation failed

    //  Animation BVH messages

//  integer LM_AB_INIT = 140;       // Initialise script
//  integer LM_AB_RESET = 141;      // Reset script
    integer LM_AB_STAT = 142;       // Print status
    integer LM_AB_LOAD = 143;       // Load and process BVH file from notecard
    integer LM_AB_FRAME = 144;      // Load channel settings for frame
    integer LM_AB_LOADED = 145;     // BVH load complete
    integer LM_AB_FRAME_LOADED = 146;   // BVH frame load complete

    //  Animation Compiler messages

//  integer LM_AC_INIT = 170;       // Initialise script
//  integer LM_AC_RESET = 171;      // Reset script
//  integer LM_AC_STAT = 172;       // Print status
    integer LM_AC_START = 173;      // Start compilation of changes
    integer LM_AC_END = 174;        // End compilation, optimise frame
    integer LM_AC_FRAME = 175;      // Animation frame compilation complete

    //  Calculator messages

//  integer LM_CA_INIT = 210;       // Initialise script
//  integer LM_CA_RESET = 211;      // Reset script
//  integer LM_CA_STAT = 212;       // Print status
    integer LM_CA_COMMAND = 213;    // Submit calculator command
    integer LM_CA_RESULT = 214;     // Report calculator result

    //  Command processor messages

    integer LM_CP_COMMAND = 223;    // Process command

    //  Animation Player messages

    integer LM_AP_PLAY = 241;       // Play entire animation
    integer LM_AP_COMPLETE = 242;   // Animation play complete
    integer LM_AP_STOP = 243;       // Stop current animation

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

    string ef(string s) { return s; }

    /*          ************************************************
                *                                              *
                *             Fourmilab Mechanisms             *
                *             Client-Side Interface            *
                *                                              *
                ************************************************  */

    //  Support storage for Mechanisms module
    list dependencyList;            // List of dependency relationships
    list linkNames;                 // List of link names
    /* IF OMEGA
    list omegaList;                 // List of omega rotations
    /* END OMEGA */
    /* IF MOTION
    list motionList;                // List of component motions
    /* END MOTION */

    //  Mechanisms link messages
    integer LM_ME_INIT = 120;       // Initialise mechanisms
//  integer LM_ME_RESET = 121;      // Reset mechanisms script
    integer LM_ME_STAT = 122;       // Print status
    integer LM_ME_TRANSLATE = 123;  // Translate component
    integer LM_ME_ROTATE = 124;     // Rotate component
//  integer LM_ME_SPIN = 125;       // Spin (omega rotate) component
    integer LM_ME_PANIC = 126;      // Reset components to initial state
    integer LM_ME_CONFIG = 127;     // Return configuration to client script
    integer LM_ME_SETTINGS = 128;   // Set parameters in mechanisms module
//  integer LM_ME_OMEGALIMIT = 129; // Omega rotation reached limit
//  integer LM_ME_CHANGED = 130;    // Position/rotation change report to compiler
    integer LM_ME_COMPLETE = 131;   // Confirm component update complete
//  integer LM_ME_MOVELIMIT = 132;  // Move limit reached
//  integer LM_ME_MOVE = 133;       // Move component
//  integer LM_ME_ROTSTEP = 134;    // Rotation step by spin command
//  integer LM_ME_TRANSTEP = 135;   // Translation step by move command

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

/*
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
*/

    /* IF OMEGA
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

    /* IF MOTION
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

    /* IF OMEGA
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
                "End flGetCompOmega support" comment.  *_/
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

    /* IF MOTION
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
                "End flGetCompMotion support" comment.  *_/
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

/*
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
                            case original command.   */

    string inventoryName(string subcmd, string lmessage, string message) {
        //  Find subcommand in Set subcmd ...
        integer dindex = llSubStringIndex(lmessage, subcmd);
        //  Advance past space after subcmd
        dindex += llSubStringIndex(llGetSubString(lmessage, dindex, -1), " ") + 1;
        //  Note that STRING_TRIM elides any leading and trailing spaces
        return llStringTrim(llGetSubString(message, dindex, -1), STRING_TRIM);
    }

    /*  setHierarchyTop  --  Find top of model hierarchy and same parameters.

                             Second Life animations contains position information
                             expressed as co-ordinates of the root of the
                             skeleton hierarchy, which is always the hips.
                             These co-ordinates are in an arbitrary scale which,
                             in practice, works out close to centimetres for
                             an avatar of typical size (you'll see initial world
                             up axis [specified as Y in BVH animations]) around 42
                             or so for initial standing poses).  This, dare I say,
                             poses a problem for our models, where we'd like to
                             be able to use animations for avatars of any size,
                             scaled automatically.

                             To work around this, after the model has been loaded
                             by flMechConfig(), we search through the model to find
                             the root of the mechanism hierarchy, which we define
                             as the lowest-numbered link in the object which has no
                             parent link but does have child links.  This doesn't
                             worry about the case where there are two or more
                             independent mechanisms within a link set, but that
                             never happens with Second Life animations.  If you have
                             additional models in your link set, just make sure the one
                             you wish to animate has its root link with a lower number
                             than any other root link in the set.  */

    integer rootLink = -1;                  // Root link of first mechanism hierarchy
    vector rootPos;                         // Local position of mechanism root

    setHierarchyTop() {
        integer i;
        integer n = llGetListLength(dependencyList);

        for (i = 0; i < n; i++) {
            if ((llList2Integer(dependencyList, i) < 0) &&
                (llListFindList(dependencyList, [ (i + 1) ]) >= 0)) {
                rootLink = i + 1;
                rootPos = llList2Vector(llGetLinkPrimitiveParams(rootLink,
                            [ PRIM_POS_LOCAL ]), 0);
                i = n;
            }
        }
    }

    /*  jAngles  --  Return angles for a joint in an animation.

                     This function takes a joint name and extracts
                     the angles from the currently loaded frame's
                     channel array, then permutes them into a vector
                     where the X, Y, and Z components are as designated
                     by the CHANNELS declaration in the hierarchy for
                     this joint.

                     Items to note: Angles are in degrees, as specified
                     in the BVH file, not radians.  X, Y, and Z co-ordinates
                     are as used in BVH, not Second Life.  The result of
                     jAngles contains no information regarding the order in
                     which the channel angles were specified nor implication
                     about the order in which the rotations should be
                     performed.  */

    vector jAngles(string joint, list chans) {
        if (animFrameNo < 0) {
            tawk("No animation frame loaded.");
            return ZERO_VECTOR;
        }
        integer p = 0;
        integer n = llGetListLength(animFrame);

        while (p < n) {
            integer cs = llList2Integer(animFrame, p + 1);
            if (llList2String(animFrame, p) == joint) {
                integer px = p + 2;     // Index of channels for this joint's angles
                integer pc = 0;         // Offset of rotation channels in joint motion data
                if (cs != 3) {
                    //  Root joint has angles following position
                    px = p + 5;
                    pc = 3;
                }
                integer i;
                vector angles;
                for (i = 0; i < 3; i++) {
                    string ax = llGetSubString(llList2String(chans, i + pc), 0, 0);

                    if (ax == "X") {
                        angles.x = llList2Float(animFrame, px + i);
                    } else if (ax == "Y") {
                        angles.y = llList2Float(animFrame, px + i);
                    } else if (ax == "Z") {
                        angles.z = llList2Float(animFrame, px + i);
                    }
                }
                return angles;
            }
            p += cs + 2;
        }
        tawk("No joint \"" + joint + "\" in frame.");
        return ZERO_VECTOR;
    }

    /*  jChans  --  Return list of channels for this joint.
                    The channels are returned as a list whose
                    items are the channel names like:
                        Xrotation
                        Yposition       */

    list jChans(string joint) {
        integer i;
        integer n = llGetListLength(animTree);
        string channels = "";
        for (i = 0; i < n; i += 5) {
            if (llList2String(animTree, i) == joint) {
                channels = llList2String(animTree, i + 4);
                i = n;
            }
        }
        if (channels == "") {
            tawk("Cannot find joint \"" + joint + "\" in hierarchy tree.");
            return [ ];
        }
        return llCSV2List(channels);
    }

    //  jRotateBySig  --  Compose rotations according to a signature

    rotation jRotateBySig(vector ja, string chsig) {
        rotation comprot;

        /*  Perform the rotations in the order given by the channel
            signature, a string like "YZX".  All permutations of
            channel order are supported.

            Note that the rotations in vector argument ja represent
            rotations in the co-ordinates used within the BVH file,
            not those of Second Life.  The following code transforms
            tht BVH Y axis into our Z (global up) axis and reverses
            the sign of the BVH Y axis when transforming it into our Y
            axis as the handedness of the co-ordinate systems are opposite.

            All co-ordinate signatures are not used in BVH files we've
            encountered to date.  Any we haven't seen are noted as
            untested below.  */

        if (chsig == "XZY") {
            comprot = llAxisAngle2Rot(<0, 0, 1>, ja.y) *
                      llAxisAngle2Rot(<0, -1, 0>, ja.z) *
                      llAxisAngle2Rot(<1, 0, 0>, ja.x);
        } else if (chsig == "XYZ") {
            comprot = llAxisAngle2Rot(<0, -1, 0>, ja.z) *
                      llAxisAngle2Rot(<0, 0, 1>, ja.y) *
                      llAxisAngle2Rot(<1, 0, 0>, ja.x);
        } else if (chsig == "ZYX") {
            comprot = llAxisAngle2Rot(<1, 0, 0>, ja.x) *
                      llAxisAngle2Rot(<0, 0, 1>, ja.y) *
                      llAxisAngle2Rot(<0, -1, 0>, ja.z);
        } else if (chsig == "YZX") {
            comprot = llAxisAngle2Rot(<1, 0, 0>, ja.x) *
                      llAxisAngle2Rot(<0, -1, 0>, ja.z) *
                      llAxisAngle2Rot(<0, 0, 1>, ja.y);
        } else if (chsig == "ZXY") {
            comprot = llAxisAngle2Rot(<0, 0, 1>, ja.y) *
                      llAxisAngle2Rot(<1, 0, 0>, ja.x) *
                      llAxisAngle2Rot(<0, -1, 0>, ja.z);
        } else if (chsig == "YXZ") {
/*          WARNING!!  I have never actually seen this signature
            in a BVH file, so this code is untested.  */
            comprot = llAxisAngle2Rot(<0, -1, 0>, ja.z) *
                      llAxisAngle2Rot(<1, 0, 0>, ja.x) *
                      llAxisAngle2Rot(<0, 0, 1>, ja.y);
/*      Can't happen (in theory!) because we handle all possible
        permutations of axis rotation sequence in the cases above.
        } else {
            tawk("Unknown co-ordinate signature " + chsig + " for joint " + joint);
*/
        }
        return comprot;
    }

    //  jRot  --  Rotate a joint by hierarchy name

    /*  The following storage is used to co-ordinate issuance of
        joint translation and rotation from the animation frame.
        When jRot issues commands to the mechanism, it increments
        jPlayFrameIntPend for each command and saves the handles
        for the pending operations in jPlayFrameIntHandT (translations)
        and jPlayFrameIntHandR (rotations).  These will be compared
        with the handles returned by the LM_ME_COMPLETE message
        confirming the operation has completed.  */

    integer jPlayFrameIntPend = 0;          // Pending operation count
    integer jPlayFrameIntHandT;             // Pending translation handle
    integer jPlayFrameIntHandR;             // Pending rotation handle

    jRot(string joint) {
        list chl = jChans(joint);
        vector ja = jAngles(joint, chl) * DEG_TO_RAD;
        integer isRoot = FALSE;     // Is this the root node ?
        vector rootAnim;            // Root position from reference frame
        rotation refRootRot;        // Root rotation from reference frame
        string jname = "Joint: " + joint;
        if (joint == "hip") {
            jname = "Hips";
        }
        integer linkno = flGetCompLink(jname);
        if (linkno > 0) {
            integer chlo = 0;
            //  If this is root element, offset to get rotation channels
            if (llGetListLength(chl) == 6) {
                /*  This is the root element ("Hips") of the model.  It
                    supplies the global position and rotation of the
                    model, and values in frames 1 through the end are
                    relative to those specified in frame 0 (the reference
                    frame).  We must, therefore, before applying the
                    position and rotation to the root, transform them
                    back to absolute values using those from the reference
                    frame.  We allow the channel order to be arbitrary but,
                    inherent in BVH, we know they're identical for all frames,
                    so we can use the channel assignments for any frame when
                    extracting those we saved for frame 0 when we saw it.

                    (You might consider this code grossly inefficient, as
                    it repeats the work of extracting the position and
                    orientation of the reference frame for every frame in
                    the animation instead of just once when we process the
                    reference frame.  It is, indeed, repetitive.  But consider
                    that the overhead for doing this is negligible compared
                    to the massive work in reading in the frame channels from
                    the BVH/BVM notecard, parsing all of the numbers from
                    text to binary, and re-arranging and transforming them
                    into Second Life co-ordinates.  Yes, this could be "sped
                    up" at the cost of some more code and complexity, but you'd
                    never notice the difference in speed.)  */
                isRoot = TRUE;
                chlo = 3;

                //  Extract position of root node in the hierarchy

                string trsig = llGetSubString(llList2String(chl, 0), 0, 0) +
                               llGetSubString(llList2String(chl, 1), 0, 0) +
                               llGetSubString(llList2String(chl, 2), 0, 0);
                /*  We're guaranteed the root node is first in animFrame
                    and that its position is in the first three channels.  */

                //  Note that we transform from BVH co-ordinates to ours right here
                rootAnim.x = llList2Float(animFrame, llSubStringIndex(trsig, "X") + 2);
                rootAnim.z = llList2Float(animFrame, llSubStringIndex(trsig, "Y") + 2);
                rootAnim.y = -llList2Float(animFrame, llSubStringIndex(trsig, "Z") + 2);

                //  Obtain position and rotation from saved reference frame
                vector refAnim;
                refAnim.x = llList2Float(jReferenceFrame, llSubStringIndex(trsig, "X") + 2);
                refAnim.z = llList2Float(jReferenceFrame, llSubStringIndex(trsig, "Y") + 2);
                refAnim.y = -llList2Float(jReferenceFrame, llSubStringIndex(trsig, "Z") + 2);
                rootAnim -= refAnim;
                //  Root rotation axis signature
                string rosig = llGetSubString(llList2String(chl, 3), 0, 0) +
                               llGetSubString(llList2String(chl, 4), 0, 0) +
                               llGetSubString(llList2String(chl, 5), 0, 0);
                //  Assemble BVH joint angles for reference frame root
                vector jaRootRot = < llList2Float(jReferenceFrame,
                                                llSubStringIndex(rosig, "X") + 5),
                                     llList2Float(jReferenceFrame,
                                                llSubStringIndex(rosig, "Y") + 5),
                                     llList2Float(jReferenceFrame,
                                                llSubStringIndex(rosig, "Z") + 5)
                                    > * DEG_TO_RAD;
                //  Compose, using signature, to obtain reference root rotation
                refRootRot = jRotateBySig(jaRootRot, rosig);
            }
            //  Assemble rotation channel signature for this joint
            string chsig = llGetSubString(llList2String(chl, chlo + 0), 0, 0) +
                           llGetSubString(llList2String(chl, chlo + 1), 0, 0) +
                           llGetSubString(llList2String(chl, chlo + 2), 0, 0);
            rotation comprot = jRotateBySig(ja, chsig);

            /*  The handling of the root node of the hierarchy (the
                "Hips" joint) is special, as it defines the position
                and overall orientation of the entire model with
                respect to the root prim of the link set within which
                the model exists.  The root node is also special in
                that, unlike all of the other joints of the model, for
                which each animation frame specifies absolute rotations
                (with respect to their parent components), the position
                and rotation of the root node is relative to the position
                and rotation of that node given in the reference frame
                (Frame 0), which is not directly rendered and usually
                is just the default T-pose.  Here, we must transform the
                position and rotation for the root node by the offsets
                saved from the reference frame.  Since all other nodes
                are children of the root, they need not be transformed.  */

            if (isRoot) {
                //  This is the hierarchy root: translate to scaled and rotated position
                float posScale = rootPos.z / animVscale;    // Scale for root position vectors
                jPlayFrameIntHandT = flSetCompPos(linkno,
                    ((rootAnim * posScale) + <0, 0, rootPos.z>) / refRootRot);
                jPlayFrameIntPend++;
//tawk("flSetCompPos jPlayFrameIntHandT " + (string) jPlayFrameIntHandT);
                //  Rotate root component by reference rotation from Frame 0
                comprot = comprot / refRootRot;
            }

            jPlayFrameIntHandR = flSetCompRot(linkno, comprot);
            jPlayFrameIntPend++;
//tawk("flSetCompRot jPlayFrameIntHandR " + (string) jPlayFrameIntHandR);
        } else {
            /*  We ignore joints in the skeleton such as neckDummy
                which are not part of our model.  Note that we
                will not increment jPlayFrameIntPend for these dummy
                joints; this is a signal we should not suspend
                waiting for an LM_ME_COMPLETE confirmation.  */
            if (!jPlaying) {
                tawk("No joint named " + jname + ".");
            }
        }
    }

    //  jPlayFrameIncStart()  --  Start playing of the current loaded frame

    integer jPlayFrameIncPtr;               // Frame list pointer
    integer jPlayFrameIncLen;               // Frame list length

    jPlayFrameIncStart() {
        jPlayFrameIncPtr = 0;
        jPlayFrameIncLen = llGetListLength(animFrame);
    }

    //  jPlayFrameIncNext()  --  Play next joint from current frame

    integer jPlayFrameIncNext() {
        /*  The following "loop" handles two different cases during
            transmission of joint commands from the frame.  The
            test causes us to escape from the loop when we've
            reached the end of the frame.  In most cases, we'll
            return from the function after sending the joint
            motion command, waiting for the LM_ME_COMPLETE
            message indicating its completion.  If this is a
            dummy joint, however, we will have sent no commands,
            and the loop will take us on immediately to the next
            joint in the frame.  */
        while (jPlayFrameIncPtr < jPlayFrameIncLen) {
            integer cs = llList2Integer(animFrame, jPlayFrameIncPtr + 1);
            string joint = llList2String(animFrame, jPlayFrameIncPtr);
//tawk("jPlayFrameIncNext  Ptr = " + (string) jPlayFrameIncPtr + "  Len " + (string) jPlayFrameIncLen +
//    "  Joint " + joint + "  cs " + (string) cs);
            jRot(joint);
            jPlayFrameIncPtr += cs + 2;
            if (jPlayFrameIntPend > 0) {
                return TRUE;
            }
        }
        return FALSE;
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

        if (id != owner) {
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
            prefixed with "@".  The command is prefixed with ">>"
            if entered from chat or "++" if from a script.  */

        integer echoCmd = TRUE;
        if (llGetSubString(llStringTrim(message, STRING_TRIM_HEAD), 0, 0) == "@") {
            echoCmd = FALSE;
            message = llGetSubString(llStringTrim(message, STRING_TRIM_HEAD), 1, -1);
        }
        if (echo && echoCmd) {
            string prefix = ">> /" + (string) commandChannel + " ";
            if (fromScript) {
                prefix = "++ ";
            }
            tawk(prefix + message);                 // Echo command to sender
        }

//      string lmessage = fixArgs(llToLower(message));
        string lmessage = llStringTrim(llToLower(message), STRING_TRIM);
        list args = llParseString2List(lmessage, [ " " ], []);    // Command and arguments
        integer argn = llGetListLength(args);       // Number of arguments
        string command = llList2String(args, 0);    // The command
        string sparam = llList2String(args, 1);     // First argument, for convenience

        //  Animation               Commands related to animations

        if (abbrP(command, "an")) {

            //  Animation joint name/*              List parameters of joints of current frame

            if (abbrP(sparam, "jo")) {
                sparam = inventoryName("jo", lmessage, message);
                if (sparam == "*") {
                    //  List all joints
                    integer p = 0;
                    integer n = llGetListLength(animFrame);

                    while (p < n) {
                        integer cs = llList2Integer(animFrame, p + 1);
                        string jname = llList2String(animFrame, p);
                        string s = "  " +  jname + "  " +
                            efv(jAngles(jname, jChans(jname)));
                        if (cs == 6) {
                            s += " Pos " + efv(< llList2Float(animFrame, p + 2),
                                             llList2Float(animFrame, p + 3),
                                             llList2Float(animFrame, p + 4) >);
                        }
                        tawk(s);
                        p += cs + 2;
                    }
                } else {
                    //  List named joint (jAngles handles invalid name)
                    vector ja = jAngles(sparam, jChans(sparam));
                    tawk("Joint \"" + sparam + "\" angles " + efv(ja));
                }

            //  Animation load [ Animation name ]   Load animation or list

            } else if (abbrP(sparam, "lo")) {
                if (argn > 2) {
                    animTree = [ ];
                    animFile = inventoryName("lo", lmessage, message);
                    if (llSubStringIndex(animFile, "BVH: ") != 0) {
                        animFile = "BVH: " + animFile;
                    }
                    if (llGetInventoryType(animFile) != INVENTORY_NOTECARD) {
                        tawk("No such BVH animation.");
                        return FALSE;
                    }
                    llMessageLinked(LINK_THIS, LM_AB_LOAD, animFile, owner);
                    scriptSuspend = TRUE;
                } else {
                    //  Unload current animation, list available animations
                    animFile = "";
                    animTree = [ ];
                    animFrame = [ ];
                    animFrameNo = -1;
                    //  No argument: list available notecards
                    integer n = llGetInventoryNumber(INVENTORY_NOTECARD);
                    integer i;
                    integer j = 0;
                    for (i = 0; i < n; i++) {
                        string s = llGetInventoryName(INVENTORY_NOTECARD, i);
                        if ((s != "") && (llGetSubString(s, 0, 4) == "BVH: ")) {
                            tawk("  " + (string) (++j) + ". " + s);
                        }
                    }
                }

            //  Animation play/compile [ start [ end ] ]    Play/compile frames or all of loaded animation

            } else if ((jCompiling = abbrP(sparam, "co")) || abbrP(sparam, "pl")) {
                if (animFile != "") {
                    jPlayFrameNo = 0;                   // Next frame to play
                    jPlayFrameLast = animFrames - 1;    // Last frame to play
                    if (argn > 2) {
                        jPlayFrameNo = (integer) llList2String(args, 2);
                        if (argn > 3) {
                            jPlayFrameLast = (integer) llList2String(args, 3);
                        } else {
                            jPlayFrameLast = jPlayFrameNo;
                        }
                    }
                    if (jCompiling) {
                        tawk("---------- Compiling animation \"" + animFile +
                             "\": Frames " + (string) jPlayFrameNo + "-" +
                                (string) jPlayFrameLast + " of " + (string) animFrames +
                             " Time " + eff(animTime) +
                             " Vscale " + eff(animVscale) +
                             " Nodes " + (string) animNodes + " ----------");
                    }
                    jPlaying = TRUE;                    // Playing in progress
                    animFrameNo = (integer) sparam;
                    animFrame = [ ];
                    llMessageLinked(LINK_THIS, LM_AB_FRAME, (string) jPlayFrameNo, owner);
                    scriptSuspend = TRUE;
                } else {
                    tawk("No animation loaded.");
                }

            //  Animation run/repeat [ Animation name ]    Play compiled animation or list animations

            } else if (abbrP(sparam, "ru") || abbrP(sparam, "re")) {
                /*  If the user enters a nonexistent animation name, we wish
                    to give a warning.  This is complicated because animation
                    scripts in the inventory may have names like:
                        Animation: Wave 1/2
                    which we can't look up directly with llGetAnimationType().
                    So, we integrate the code which lists animation with that
                    which runs them, allowing validation of the name entered
                    without duplication of the enumeration of scripts.  */
                string aname = "";
                if (argn > 2) {
                    aname = inventoryName(sparam, lmessage, message);
                    animLoop = abbrP(sparam, "re");
                }

                integer n = llGetInventoryNumber(INVENTORY_SCRIPT);
                integer i;
                list anims = [ ];
                for (i = 0; i < n; i++) {
                    string s = llGetInventoryName(INVENTORY_SCRIPT, i);
                    if (llGetSubString(s, 0, 10) == "Animation: ") {
                        s = llGetSubString(s, 11, -1);
                        if (llSubStringIndex(s, "/") > 0) {
                            while (llSubStringIndex("0123456789/", llGetSubString(s, -1, -1)) > 0) {
                                s = llDeleteSubString(s, -1, -1);
                            }
                            s = llStringTrim(s, STRING_TRIM_TAIL);
                        }
                        if (aname == s) {
                            llMessageLinked(LINK_THIS, LM_AP_PLAY | (1 << 8), aname, whoDat);
                            scriptSuspend = !animLoop;
                            animRunning = TRUE;
                            return TRUE;
                        } else {
                            if (llListFindList(anims, [ s ]) < 0) {
                                anims += s;
                            }
                        }
                    }
                }
                if (aname != "") {
                    tawk("No such animation script.");
                    return FALSE;
                } else {
                    anims = llListSort(anims, 1, TRUE);
                    n = llGetListLength(anims);
                    for (i = 0; i < n; i++) {
                        tawk("  " + (string) (i + 1) + ". " + llList2String(anims, i));
                    }
                }

            //  Animation stop              Stop current animation

            } else if (abbrP(sparam, "st")) {
                llMessageLinked(LINK_THIS, LM_AP_STOP, "", whoDat);
                animLoop = jPlaying = FALSE;
            }

        //  Boot                    Reset the script to initial settings

        } else if (abbrP(command, "bo")) {
            integer n = llGetInventoryNumber(INVENTORY_SCRIPT);
            integer i;
            string us = llGetScriptName();
            for (i = 0; i < n; i++) {
                string s = llGetInventoryName(INVENTORY_SCRIPT, i);
                if (s != us) {
                    llResetOtherScript(s);
                }
            }
            llSleep(1);
            llResetScript();

        //  Calc                    Submit command to the calculator

        } else if (abbrP(command, "ca")) {
            llMessageLinked(LINK_THIS, LM_CA_COMMAND, message, id);

        //     Handled by the Auxiliary Command Processor
        //  Clear                   Clear chat for debugging
        //  Export                  Export mechanism configuration
        //  Help                    Request help notecards
        //  Import                  Import mechanism configuration
        //  Joint                   Joint manipulation commands
        //  Script                  Script commands

        } else if (abbrP(command, "cl") ||
                   abbrP(command, "ex") ||
                   abbrP(command, "he") ||
                   abbrP(command, "im") ||
                   abbrP(command, "jo") ||
                   abbrP(command, "sc")) {
            llMessageLinked(LINK_THIS, LM_CP_COMMAND,
                llList2Json(JSON_ARRAY, [ message, lmessage ] + args), whoDat);

        //  Panic [ gently ]        Restore initial positions and locations

        } else if (abbrP(command, "pa")) {
            llMessageLinked(LINK_THIS, LM_AP_STOP, "", whoDat);
            if (animRunning) {
                llSleep(0.25);      // Wait for animation to stop
            }
            animRunning = animLoop = jPlaying = FALSE;
            flMechPanic(abbrP(sparam, "sa"));
            if ((argn < 2) || (!abbrP(sparam, "ge"))) {
                //  Terminate any running script
                llMessageLinked(LINK_THIS, LM_SP_INIT, "", id);
            }

        //  Set                     Set parameter

        } else if (abbrP(command, "se")) {
            string svalue = llList2String(args, 2);

                //  Set trace on/off

                if (abbrP(sparam, "tr")) {
                    trace = onOff(svalue);
                    flMechSettings(trace, FALSE);

                } else {
                    tawk("Invalid.  Set trace");
                    return FALSE;
                }

        //  Status [ extended ]

        } else if (abbrP(command, "st")) {
            integer extended = abbrP(sparam, "ex");

            tawk(llGetScriptName() + " status:");
            if (animFile != "") {
                string s = "  Animation loaded: " + animFile +
                    " Nodes: " + (string) animNodes + " Frames: " + (string) animFrames +
                    " Frame time: " + (string) animTime;
                tawk(s);
                if (animFrameNo >= 0) {
                    tawk("  Frame " + (string) animFrameNo + " loaded.");
                }
            }

            integer mFree = llGetFreeMemory();
            integer mUsed = llGetUsedMemory();
            tawk("  Script memory.  Free: " + (string) mFree +
                    "  Used: " + (string) mUsed + " (" +
                    (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
            );

            //  Request status of Command Processor module

            llMessageLinked(LINK_THIS, LM_CP_COMMAND,
                llList2Json(JSON_ARRAY, [ "", "" ] + args), whoDat);

            //  Request status of Mechanisms module
            llSleep(1);         // Allow this script's status to complete
            flMechStatus(extended, whoDat);

            //  Request status of Animation BVH module
            llSleep(1);         // Wait for Mechanisms status to complete
            llMessageLinked(LINK_THIS, LM_AB_STAT, "", whoDat);

            //  Request status of Script Processor
            llSleep(1);         // Wait for Animation BVH status to complete
            llMessageLinked(LINK_THIS, LM_SP_STAT, "", id);

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
//          if (commandChannel < 1000) {
//          //  If special command channel for testing, show as floating text
                llSetText("/" + (string) commandChannel, <0, 1, 0>, 1);
//          } else {
//              llSetText("", ZERO_VECTOR, 0);
//          }
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
//tawk(llGetScriptName() + " link message sender " + (string) sender + "  num " + (string) num + "  str " + str + "  id " + (string) id);

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
                setHierarchyTop();

            //  LM_ME_COMPLETE (131): Completion of mechanism movement

            } else if (num == LM_ME_COMPLETE) {
                /*  When we're playing an animation from a BVH file,
                    we mustn't get ahead of ourselves and pump in too
                    many joint motion commands from a frame all in a
                    burst of activity.  Since joint motion commands
                    are performed by the Mechanism script they are
                    automatically serialised by its link message input
                    queue, so it's OK to fire off a few at once, but
                    since a mechanism may have a large number of joints
                    and the link message queue is limited to 64 messages
                    (after which they are [*shudder*] silently ignored)
                    of all types, we must be careful to avoid coming too
                    close to this abyss.

                    When jRot commands motion of a joint, it increments
                    jPlayFrameIntPend for each pending motion and saves
                    the handles for the operations.  When the motion
                    completes, we receive the LM_ME_COMPLETE messages here.
                    If jPlayFrameIntPend is nonzero, we match the handles in
                    the completion messages with the pending operations and,
                    when the motion is complete, we then call
                    jPlayFrameIncNext() to move the next joint.
                    When we reach the end of the frame, we start the
                    next frame if requested or end if we've reached the
                    last requested frame or the end of the animation.  */
                if (jPlayFrameIntPend > 0) {
                    list compl = llCSV2List(str);
                    integer opend = jPlayFrameIntPend;
                    integer op = (integer) llList2String(compl, 0);
                    integer hand = (integer) llList2Integer(compl, 1);
//tawk("LM_ME_COMPLETE " + str + "  HandT " + (string) jPlayFrameIntHandT +
//    "  HandR " + (string) jPlayFrameIntHandR + "  Pend " + (string) jPlayFrameIntPend);
                    if ((op == LM_ME_TRANSLATE) & (hand == jPlayFrameIntHandT)) {
                        jPlayFrameIntPend--;
                        jPlayFrameIntHandT = -1;
                    } else if ((op == LM_ME_ROTATE) && (hand == jPlayFrameIntHandR)) {
                        jPlayFrameIntPend--;
                        jPlayFrameIntHandR = -1;
                    }
                    if ((opend > 0) && (jPlayFrameIntPend == 0)) {
//tawk("LM_ME_COMPLETE process next frame movement");
                        if (!jPlayFrameIncNext()) {
                            if (jCompiling) {
                                flMechSettings(trace, FALSE);    // Clear compile mode
                                llMessageLinked(LINK_THIS, LM_AC_END,
                                    (string) (jPlayFrameNo == jPlayFrameLast), whoDat);
                                //  Defer further processing until LM_AC_FRAME received
                                return;
                            }
                            jPlayFrameNo++;
                            if (jPlayFrameNo <= jPlayFrameLast) {
                                llMessageLinked(LINK_THIS, LM_AB_FRAME, (string) jPlayFrameNo, whoDat);
                            } else {
                                jPlaying = FALSE;
                                tawk("Animation complete.");
                                scriptResume();
                            }
                        }
                    }
                }

            //  LM_AB_LOADED (145): BVH file loaded

            } else if (num == LM_AB_LOADED) {
                list bvh = llJson2List(str);
                if (llList2Integer(bvh, 0)) {
                    animNodes = llList2Integer(bvh, 1);     // Nodes in hierarchy tree
                    animFrames = llList2Integer(bvh, 2);    // Frames in animation
                    animTime = llList2Float(bvh, 3);        // Time per frame
                    animVscale = llList2Float(bvh, 4);      // Vertical scale factor
                    animTree = llList2List(bvh, 5, -1);     // Animation hierarchy tree
                    scriptResume();
                } else {
                    tawk("BVH animation file \"" + animFile + "\" load failed.");
                    animFile = "";
                }

            //  LM_AB_FRAME_LOADED (146): BVH frame loaded

            } else if (num == LM_AB_FRAME_LOADED) {
                list framed = llJson2List(str);
                if (llList2Integer(framed, 0)) {
                    animFrame = llList2List(framed, 1, -1);
                    if (jPlaying) {
                        tawk("Frame " + (string) jPlayFrameNo);

                        /*  The first frame of a BVH animation is a special
                            creature: the "BVH Reference Frame" as documented
                            (kind of) in:
                                http://wiki.secondlife.com/wiki/BVH_Reference_Frame

                            It has two main functions: providing the reference
                            position and orientation for the hip joint (which is
                            the root of the hierarchy), and indicating, in a curious
                            manner, which of the joints should move in the animation.

                            In a Second Life BVH file, the position and rotation values
                            for the hip joint are, unlike those for all of the other
                            joints, relative to those given in the reference frame (0),
                            which is not played.  This allows easy editing of the
                            animation to change the overall position and rotation of
                            the character simply by adjusting the values in the
                            reference frame and leaving those in the subsequent actual
                            frame of the animation unchanged.  In practice, this means
                            we have to capture the reference frame and then use its hip
                            joint channels to adjust those in subsequent frames.

                            But wait, there's more!  The values for the other channels
                            also play a role: specifying which joints actually move in
                            the animation.  If a joint contains identical non-zero
                            values for rotation (recall that only the hip has position
                            values) in the first (reference, 0) frame and the second
                            frame, then that joint *will not* be animated, regardless
                            of what is specified for it in subsequent frames.  */

                        if (jPlayFrameNo == 0) {
                            jReferenceFrame = llList2List(animFrame, 0, 7);
                        } else {
                            if (jCompiling) {
                                flMechSettings(trace, TRUE);    // Set compile mode
                                llMessageLinked(LINK_THIS, LM_AC_START, (string) jPlayFrameNo, whoDat);
                            }
                            jPlayFrameIncStart();

                            //  Start incremental playing of this frame
                            if (jPlayFrameIncNext()) {
                                //  If the first frame is void, we're done
                                return;
                            }
//  We shouldn't need this, but let's leave it in to see if it triggers somehow
tawk("GAAAAH!  VOID FIRST FRAME!");
                            if (jCompiling) {
                                flMechSettings(trace, FALSE);    // Clear compile mode
                                llMessageLinked(LINK_THIS, LM_AC_END,
                                    (string) (jPlayFrameNo == jPlayFrameLast), whoDat);
                                //  Defer further processing until LM_AC_FRAME received
                                return;
                            }
                        }
                        jPlayFrameNo++;
                        if (jPlayFrameNo <= jPlayFrameLast) {
                            llMessageLinked(LINK_THIS, LM_AB_FRAME, (string) jPlayFrameNo, whoDat);
                        } else {
                            jPlaying = FALSE;
                            tawk("Animation complete.");
                            scriptResume();
                        }
                    } else {
                        tawk("Frame " + (string) animFrameNo + " loaded.");
                    }
                } else {
                    tawk("Frame " + (string) animFrameNo + " load failed.");
                    animFrameNo = -1;
                }

            //  LM_AC_FRAME (175): Animation frame compilation complete

            } else if (num == LM_AC_FRAME) {
                jPlayFrameNo++;
                if (jPlayFrameNo <= jPlayFrameLast) {
                    llMessageLinked(LINK_THIS, LM_AB_FRAME, (string) jPlayFrameNo, whoDat);
                } else {
                    jPlaying = FALSE;
                    tawk("Animation complete.");
                    scriptResume();
                }

            //  LM_CA_RESULT (214): Calculator result report

            } else if (num == LM_CA_RESULT) {
                calcResult = llJson2List(str);

            //  LM_AP_COMPLETE (242): Animation complete

            } else if (num == LM_AP_COMPLETE) {
                if (animLoop) {
                    llMessageLinked(LINK_THIS, LM_AP_PLAY | (1 << 8), str, whoDat);
                } else {
                    tawk("Animation " + str + " complete.");
                    animRunning = FALSE;
                    scriptResume();
                }
            }
        }
    }
