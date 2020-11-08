    /*
                                Blobby Component

                                 by John Walker

            This script is included in every component deployed.  When it
            receives control, it sends a READY message to the deployer to
            inform it that it's running.  The deployer will then evetually
            respond with a CONFIG message which informs the component of
            its link name and size (it has already been deployed in the
            correct position).  If this is the root prim, when deployment
            of all components is complete, it will receive LINKUP messages
            from the deployer which cause the child prims to be linked to
            the root prim.

            Finally, when everything is done, all deployed prims will be
            sent CLEANUP messages which cause them to delete this script,
            whose job is complete.

    */

    key owner;                              // UUID of owner

    integer siteChannel = -982446720;       // Channel for communicating with sites
    string ypres = "Q?+:$$";                // It's pronounced "Wipers"

    key deployer;                           // UUID of our deployer
    integer compIndex = 0;                  // Component index (1 = root prim)

    list linkReqPending = [ ];              // Link requests pending permissions grant
    integer permitted = 0;                  /* Have we been granted permission to make links ?
                                                   0 = no, 1 = pending, 2 = granted  */

    default {

        state_entry() {
            owner = llGetOwner();
        }

        on_rez(integer start_param) {
            compIndex = start_param;
            llListen(siteChannel, "", "", "");      // Listen for commands from the deployer

            /*  Now that we're up and running, send a message back
                to the deployer to let it know we're listening for the
                configuration message.  */

            deployer = llList2Key(llGetObjectDetails(llGetKey(),
                            [ OBJECT_REZZER_KEY ]), 0);
            llRegionSayTo(deployer, siteChannel, "READY," + (string) compIndex);
//llOwnerSay("Sending READY to " + (string) deployer + " on " + (string) siteChannel);
        }

        //  The listen event handles commands from the deployer

        listen(integer channel, string name, key id, string message) {

            //  Message from our Blobby Man Deployer

            if ((channel == siteChannel) && (id == deployer)) {
                list args = llCSV2List(message);
                string cmd = llList2String(args, 0);

                if (message == ypres) {             // We're extra-picky parsing this one
                    if (compIndex > 0) {
                        //  Only die if created by this deployer
                        llDie();
                    }

                //  CONFIG                  Set component name and size

                } else if (cmd == "CONFIG") {
                    /*  The deployer has received our ready message and
                        responded with its CONFIG message.  Decode the
                        configuration parameters and set this component's
                        properties accordingly.  */

//llOwnerSay("Config received " + message);
                    /*  Scale factors are based upon ellipsoid semi-axis sizes
                        and must be multiplied by two to express in Second Life's
                        diameter-based prim sizes.  */
                    llSetLinkPrimitiveParamsFast(LINK_THIS,
                        [ PRIM_NAME, llList2String(args, 1),
                          PRIM_SIZE, (((vector) llList2String(args, 2)) * 2) ]);

                //  LINKUP                  Inform root prim of child prims to link

                } else if (cmd == "LINKUP") {
                    if (compIndex == 1) {
                        if (permitted == 2) {
                            llCreateLink((key) llList2String(args, 2), TRUE);
//llOwnerSay("Linked component " + llList2String(args, 1) + " " + llList2String(args, 2));
                            llRegionSayTo(deployer, siteChannel, "LINKED," +
                                llList2String(args, 1) + " " + llList2String(args, 2));
                        } else {
                            if (permitted == 0) {
                                //  We have to ask nicely before we're allowed to create links
                                llRequestPermissions(owner, PERMISSION_CHANGE_LINKS);
                                permitted = 1;              // Permission request pending
                            }
                            //  Enqueue link request for processing when permitted
                            linkReqPending += [ (integer) llList2String(args, 1), (key) llList2String(args, 2) ];
                        }
                    } else {
                        llOwnerSay("What!  LINKUP message sent to non-root prim (" +
                            (string) compIndex + ").");
                    }

                //  CLEANUP                 Clean up (delete this script) after deployment complete

                } else if (cmd == "CLEANUP") {
                    llRemoveInventory(llGetScriptName());
                    while (TRUE) {
//llOwnerSay("Component " + (string) compIndex + " awaiting clean-up.");
                        llSleep(0.1);
                    }
                }
            }
        }

        /*  When we're granted permissions to make links, link
            pending components together into a single link set.  */

        run_time_permissions(integer perms) {
            if (perms & PERMISSION_CHANGE_LINKS) {
                permitted = 2;          // Permission granted
                while (llGetListLength(linkReqPending) > 0) {
                    integer compno = llList2Integer(linkReqPending, 0);
                    key k = llList2Key(linkReqPending, 1);
                    linkReqPending = llDeleteSubList(linkReqPending, 0, 1);
                    llCreateLink(k, TRUE);
//llOwnerSay("Linked component (queued) " + (string) compno + " " + (string) k);
                    llRegionSayTo(deployer, siteChannel, "LINKED," +
                        (string) compno + " " + (string) k);
                }
            }
        }
    }
