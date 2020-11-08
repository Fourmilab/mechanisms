#
#   Blobby Man waving
#

#   This script is adapted from an example in Jim Blinn's original
#   article in "Jim Blinn's Corner", IEEE Computer Graphics and Applications,
#   October 1987, Page 59.

#   There are numerous changes due to differences in the co-ordinate
#   systems used and our use of a "T Pose" as the initial position instead
#   of Blinn's arms at the side posture.  Blinn's original settings are given
#   as comments (actually, just ignored extra arguments) on the commands.

panic gently

#   Nod head
joint rot head <25, 0, 0>       # nod -25

#   Turn neck
joint rot neck <0, 0, -28>      # next 28

#   Turn left leg at hip
joint rot lThigh <0, 0,  105>   # rhip 105
joint rot lThigh <0, -13, 0>     # rout 13
joint rot lThigh <0, 0, -105>   # -rhip 105
joint rot lThigh <0, 0, 86>      # rtwis -86
#   Flex left knee
joint rot lShin <53, 0, 0>        # rknee -53

#   Left arm
joint rot lShldr <0, -22, 0>      # rsid 112
joint rot lShldr <0, 0, -40>     # rshou 40
joint rot lShldr <-192, 0, 0>    # ratwis -102
joint rot lForeArm <0, 85, 0>  # relbo 85

#   Right arm
joint rot rShldr <0, -45, 0>      # lsid -45
joint rot rShldr <180, 0, 0>      # latwis -90
joint rot rForeArm <0, 90, 0>   # lelbo 90

#   The following settings of hand do not appear in
#   Blinn's example, as his Blobby Man does not
#   have these articulations.  We add them here just
#   because we can.

#   Left hand
joint rot lHand <120, 0, 0>
#   Right hand
joint rot rHand <0, -45, 0>
