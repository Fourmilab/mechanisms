  /*
                    Fourmilab Marble Madness

                          Bumper Object

    */

    integer bState = 0;             /* Bumper state:
                                         0:  Armed
                                         1:  Fired, awaiting reset */
    float resetTime = 0.3;          // Reset time for bumper
    float volume = 1;               // Bounce sound volume

    //  Auxiliary script messages

    integer LM_AU_SETTINGS = 31;    // Settings

    default {

        state_entry() {
            bState = 0;
        }

        /*  When a collision occurs, we first check whether we're
            armed or recharging.  If recharging, the collision is
            ignored (handled by Second Life's physics engine as
            for any intert non-phantom object).  If active, we
            compute the negative of the incident object velocity,
            then impart a swift kick of constant impulse to it
            with llPushObject().  This places the number in the
            Fired state and starts a timer which, when it expires,
            re-arms the bumper, permitting it to respond once again
            to collisions.  */

        collision(integer n) {
            if (bState == 0) {
                integer i;

                for (i = 0; i < n; i++) {
                    key colk = llDetectedKey(i);
                    vector colv = llDetectedVel(i);
//llOwnerSay("Collided with " + llDetectedName(i) + " vel " + (string) colv);
                    if (llVecMag(colv) > 0) {
    //                    vector pmag = (-colv) / 100;
                        vector pmag = llVecNorm(-colv) / 10;
                        llPushObject(colk, pmag, ZERO_VECTOR, FALSE);
                        llSetTimerEvent(resetTime);
                        bState = 1;
                        llSetLinkPrimitiveParamsFast(LINK_THIS,
                            [ PRIM_COLOR, ALL_SIDES, <1, 0.1, 0.1>, 0.75,
                              PRIM_GLOW, ALL_SIDES, 0.1 ]);
                        if (volume > 0) {
                            llPlaySound("Bounce", volume);
                        }
                        i = n;              // Ignore any other collisions
                    }
                }
            }
        }

        /*  The timer handles re-arming the bumper when
            the recharge interval has elapsed.  */

        timer() {
            llSetTimerEvent(0);
            bState = 0;
            llSetLinkPrimitiveParamsFast(LINK_THIS,
                [ PRIM_COLOR, ALL_SIDES, <0, 0, 1>, 0.75,
                  PRIM_GLOW, ALL_SIDES, 0 ]);
        }

        //  Process link messages from other scripts

        link_message(integer sender, integer num, string str, key id) {

            //  LM_AU_SETTINGS (31): Update settings

            if (num == LM_AU_SETTINGS) {
                list setting = llCSV2List(str);
                volume = (float) llList2String(setting, 2);
            }
        }
    }
