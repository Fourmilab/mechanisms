    /*
                  Blobby Man Deployer

        This script deploys and links together a version of Jim
        Blinn's original Blobby Man.  Note that this differs
        substantially from the Blobby Man model used with Fourmilab
        Mechanisms: it lacks the joint objects for articulations,
        the separate Abdomen and Thorax parts, and the separation
        between the Shoulders and Left and Right Clavicle components
        added to that model for compatibility with the Second Life
        standard avatar skeleton and the ability to play poses and
        animations developed for it.  The default pose of this Blobby
        Man is arms to the side, while the Second Life avatar defaults
        to a "T Pose".

        This tool is provided in case you want to start with the
        original Blobby Man for another project, or use the deployer
        to build other models from scaled sphere blobs.  It is driven
        from the Blobby Man notecard in the inventory, which may be
        modified to create any structure whatever.

        Operation of the deployer is simple.  To deploy, enter the
        command:
            /49 Deploy
        in local chat.  After the primitive objects have been created,
        you'll be asked for permission to link them together.  After
        you grant that permission, this will be done (it takes a while
        due to artificial delays imposed by Second Life), and you'll
        end up with a linked model you can move and use as you wish.
        After the deployment is complete, all connection with the
        deployer is severed and you can manipulate the Blobby Man
        independently and, if you like, deploy others to fill out
        the ranks of your Blobby Army.

                    by John Walker
    */

    key owner;                          //  Owner UUID
    string ownerName;                   //  Name of owner

    integer commandChannel = 49;        // Chat command channel (James Blinn was born in 1949)
    integer commandH;                   // Handle for command channel
    key whoDat = NULL_KEY;              // Avatar who sent command
    integer restrictAccess = 2;         // Access restriction: 0 none, 1 group, 2 owner
    integer echo = TRUE;                // Echo chat and script commands ?

    string confNotecard = "Blobby Man"; // Configuration notecard
    string ncSource = "";               // Current notecard being read
    key ncQuery;                        // Handle for notecard query
    integer ncLine = 0;                 // Current line in notecard

    integer siteChannel = -982446720;   // Channel for communicating with deployed objects
    integer siteChannelH;               // Handle for site channel listener
    string ypres = "Q?+:$$";            // It's pronounced "Wipers"

    integer siteIndex = 0;              // Index of last site deployed
    list componentConfig;               // Configuration for pending components
    integer deployComplete;             // Is deployment complete ?
    integer componentsDeployed;         // Number of components deployed
    integer componentsLinked;           // Number of components linked to root prim
    list componentKeys;                 // Component number and UUID table
    key rootPrim;                       // Root prim of components deployed

    vector crepos;                      // Base position to create objects
    float globalScale = 1;              // Global scale factor

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

    //  generateObject  --  Process an object generation command

    integer generateObject(string cmd) {
        tawk("++ " + cmd);
        list rargs = llCSV2List(cmd);
        integer n = llGetListLength(rargs);
        integer i;
        list args = [ ];

        //  Trim leading and trailing spaces from arguments
        for (i = 0; i < n; i++) {
            args += [ llStringTrim(llList2String(rargs, i), STRING_TRIM) ];
        }
        rargs = [ ];

        string type = llList2String(args, 0);

        if (type == "SCALE") {
            globalScale = (float) llList2String(args, 1);
        } else if (type == "SPHERE") {
            string cname = llList2String(args, 1);          // Component name
            vector cpos = < (float) llList2String(args, 2), // Component position
                            (float) llList2String(args, 3),
                            (float) llList2String(args, 4) >;
            vector cscale = < (float) llList2String(args, 5), // Component scale
                              (float) llList2String(args, 6),
                              (float) llList2String(args, 7) >;
//            tawk("Create " + llList2String(args, 0) + " named \"" + cname +
//                "\" at " + (string) cpos + " scaled " + (string) cscale);

            //  Transform component position and scale by global scale factor
            cpos *= globalScale;
            cscale *= globalScale;

            /*  Unfortunately, there is no way to squeeze the component name
                and scale information we need to pass to the component into
                the 32-bit integer start_param, which is all we can pass to an
                object we rez.  So, we do  the following little dance.  We pass
                the component we're creating a unique handle in its start_param.
                When it gets control and its on_rez() runs, it sends a READY message
                back to us [directing it to our attention via our UUID obtained
                from OBJECT_REZZER_KEY in llGetObjectDetails()] indicating it's
                up and running.  This informs us we can now send it a CONFIG
                messsage containing the JSON-encoded name and scale information.
                But where does that information come from?  Why, from the
                componentConfig list, where we squirrel it away here so that
                the listen() event handler can find it when needed.  */

            siteIndex++;
            componentConfig += [ siteIndex, cname, cscale ];

            llRezObject("Blobby sphere", crepos + cpos,
                ZERO_VECTOR, ZERO_ROTATION, siteIndex);
        } else {
            tawk("Invalid generate object command.");
            return FALSE;
        }
        return TRUE;
    }

    //  processCommand  --  Process a command

    integer processCommand(key id, string message, integer fromScript) {

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
        if (echo && echoCmd) {
            string prefix = ">> ";
            if (fromScript) {
                prefix = "++ ";
            }
            tawk(prefix + message);                 // Echo command to sender
        }

        string lmessage = llToLower(llStringTrim(message, STRING_TRIM));
        list args = llParseString2List(lmessage, [" "], []);    // Command and arguments
//      integer argn = llGetListLength(args);       // Number of arguments
        string command = llList2String(args, 0);    // The command

        //  Access who                  Restrict chat command access to public/group/owner

        if (abbrP(command, "ac")) {
            string who = llList2String(args, 1);

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

        /*  Channel n                   Change command channel.  Note that
                                        the channel change is lost on a
                                        script reset.  */
        } else if (abbrP(command, "ch")) {
            integer newch = (integer) llList2String(args, 1);
            if ((newch < 2)) {
                tawk("Invalid channel " + (string) newch + ".");
                return FALSE;
            } else {
                llListenRemove(commandH);
                commandChannel = newch;
                commandH = llListen(commandChannel, "", NULL_KEY, "");
                tawk("Listening on /" + (string) commandChannel);
            }

        //  Clear                       Clear chat for debugging

        } else if (abbrP(command, "cl")) {
            tawk("\n\n\n\n\n\n\n\n\n\n\n\n\n");

        //  Deploy                      Deploy model

        } else if (abbrP(command, "de")) {
            siteIndex = 0;              // Reset component indices
            componentsDeployed = 0;     // None deployed so far
            componentsLinked = 0;       // None linked so far
            componentKeys = [ ];        // Clear component key list
            deployComplete = FALSE;     // Deployment not complete
            //  Start listening for messages from deployed components
            siteChannelH = llListen(siteChannel, "", "", "");
            componentConfig = [ ];
            tawk("Creating components.");
            processNotecardCommands(confNotecard);

        //  Help                        Display help text

        } else if (abbrP(command, "he")) {
            tawk("Blobby Man Deployer commands:\n" +
                 "  deploy\n" +
                 "  remove\n" +
                 "For additional information, see the Fourmilab Mechanisms User Guide"
                );

        //  Remove                      Remove all sites

        } else if (abbrP(command, "re")) {
            llRegionSay(siteChannel, ypres);
            siteIndex = 0;

        } else {
            tawk("Huh?  \"" + message + "\" undefined.  Chat /" +
                (string) commandChannel + " help for instructions.");
            return FALSE;
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

    default {

        state_entry() {
            owner = llGetOwner();
            ownerName = llKey2Name(owner);  //  Save name of owner

            llSetText("/" + (string) commandChannel, <0, 1, 0>, 1);

            crepos = llGetPos();            // Our position
            crepos = < llRound(crepos.x),   // Round position to one above deployer
                       llRound(crepos.y),
                       llCeil(crepos.z) + 1 >;

            siteIndex = 0;

            //  Start listening on the command chat channel
            commandH = llListen(commandChannel, "", NULL_KEY, "");
            llOwnerSay("Listening on /" + (string) commandChannel);
        }

        /*  The listen event handler processes messages from
            our chat control channel.  */

        listen(integer channel, string name, key id, string message) {
//tawk("listen channel " + (string) channel + " name " + name + " id " + (string) id + " message " + message);
            if (channel == siteChannel) {
                list args = llCSV2List(message);
                string msg = llList2String(args, 0);

                //  READY       Component reports its script is running

                if (msg == "READY") {
                    integer compn = (integer) llList2String(args, 1);
                    //  If this is component 1, save UUID of root prim
                    if (compn == 1) {
                        rootPrim = id;
                    }
                    componentKeys += [ compn, id ];
                    integer n = llGetListLength(componentConfig);
                    integer i;

                    for (i = 0; i < n; i += 3) {
                        if (llList2Integer(componentConfig, i) == compn) {
                            llRegionSayTo(id, siteChannel, llList2CSV([ "CONFIG",
                                llList2String(componentConfig, i + 1),
                                llList2Vector(componentConfig, i + 2) ]));
                            i = n;
                        }
                    }

                    //  Increment number of components deployed
                    componentsDeployed++;

                //  LINKED      Root prim reports it has linked a child prim

                } else if (msg == "LINKED") {
                    componentsLinked++;
                   if (componentsLinked == (siteIndex - 1)) {
                        tawk("All components linked.  Deleting deployment script from components.");
                         /*  All components have been linked to the root prim.
                            Send CLEANUP messages to all components to delete
                            their deployment scripts.  */
                        integer i;
                        integer n = llGetListLength(componentKeys);

                        for (i = 0; i < n; i += 2) {
                            key k = llList2Key(componentKeys, i + 1);
                            llRegionSayTo(k, siteChannel, llList2CSV([ "CLEANUP",
                                llList2Integer(componentKeys, i), k ]));
                        }
                        tawk("Deployment complete.");
                    }
                }
            } else {
                processCommand(id, message, FALSE);
            }
        }

        //  The dataserver event receives lines from the configuration notecard

        dataserver(key query_id, string data) {
            if (query_id == ncQuery) {
                if (data == EOF) {
                    tawk("End configuration: " + ncSource);
                    ncSource = "";
                    ncLine = 0;
                    deployComplete = TRUE;
                    /*  Now that we've processed all component creation
                        commands we want to link them into a single link
                        set.  But we can't do that until all of the components
                        are known to have initialised (have their scripts
                        running).  So, we start a timer to poll until we've
                        received READY messages from all components, then send
                        the link commands from the timer.  */
                    llSetTimerEvent(0.1);
                } else {
                    string s = llStringTrim(data, STRING_TRIM);
                    //  Ignore comments and process valid commands
                    if ((llStringLength(s) > 0) && (llGetSubString(s, 0, 0) != "#")) {
                        integer stat = generateObject(s);
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

        /*  The timer waits until all components are confirmed
            deployed and then starts up the process to link them
            together.  */

        timer() {
            if (deployComplete && (componentsDeployed >= siteIndex)) {
                tawk("All " + (string) siteIndex + " components deployed.\n" +
                     "Linking components to root prim: please grant permission.\n" +
                     "Linking will take about " + (string) (siteIndex - 1) + " seconds.");
                llSetTimerEvent(0);             // Cancel timer

                /*  Walk through the component keys and send LINKUP
                    messages to introduce all of the child components
                    to the root prim.  */

                integer i;
                integer n = llGetListLength(componentKeys);

                for (i = 0; i < n; i += 2) {
                    key k = llList2Key(componentKeys, i + 1);
                    if (k != rootPrim) {
                        llRegionSayTo(rootPrim, siteChannel, llList2CSV([ "LINKUP",
                            llList2Integer(componentKeys, i), k ]));
                    }
                }
            }
        }
    }
