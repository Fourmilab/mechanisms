#
#   Fourmilab Blobby Man mechanism configuration
#

#   Initial configuration to restore after disasters whilst testing

Set restore "Blobby Man" <148, 151, 1200.274> <0, 0, 0, 1>

#   Active joints: these compose the skeleton
Set restore "Joint: chest" <0, 0, 1.20654> <0, 0, 0, 1>
Set restore "Joint: rCollar" <-0.0231, 0, 1.53565> <0, 0, 0, 1>
Set restore "Joint: lCollar" <0.02309, 0, 1.53565> <0, 0, 0, 1>
Set restore "Joint: abdomen" <0, 0, 1.09619> <0, 0, 0, 1>
Set restore "Joint: lThigh" <0.0979, 0, 0.98523> <0, 0, 0, 1>
Set restore "Joint: rThigh" <-0.0979, 0, 0.98523> <0, 0, 0, 1>
Set restore "Joint: lFoot" <0.0979, 0, 0.05029> <0, 0, 0, 1>
Set restore "Joint: rFoot" <-0.0979, 0, 0.05029> <0, 0, 0, 1>
Set restore "Joint: lHand" <0.8139, 0, 1.53565> <0, 0, 0, 1>
Set restore "Joint: lForeArm" <0.5484, 0, 1.53565> <0, 0, 0, 1>
Set restore "Joint: lShldr" <0.2475, 0, 1.53565> <0, 0, 0, 1>
Set restore "Joint: rHand" <-0.8139, 0, 1.53565> <0, 0, 0, 1>
Set restore "Joint: rForeArm" <-0.5484, 0, 1.53565> <0, 0, 0, 1>
Set restore "Joint: rShldr" <-0.2475, 0, 1.53565> <0, 0, 0, 1>
Set restore "Joint: head" <0, 0, 1.68384> <0, 0, 0, 1>
Set restore "Joint: neck" <0, 0, 1.60046> <0, 0, 0, 1>
Set restore "Shoulders" <0, 0, 1.53528> <0, 0, 0, 1>
Set restore "Hips" <0, 0, 1.02929> <0, 0, 0, 1>
Set restore "Joint: lShin" <0.0979, 0, 0.51782> <0, 0, 0, 1>
Set restore "Joint: rShin" <-0.0979, 0, 0.51782> <0, 0, 0, 1>

#   Passive components: these are acted upon only via the joints
Set restore "Head" <0, 0, 1.83948> <0, 0, 0, 1>
Set restore "Nose" <0, -0.14024, 1.85046> <0, 0, 0, 1>
Set restore "Mouth" <0, -0.0891, 1.75098> <0, 0, 0, 1>
Set restore "Neck" <0, 0, 1.65796> <0, 0, 0, 1>

Set restore "Left Clavicle" <0.02309, 0, 1.53565> <0, 0.70706, 0, 0.70715>
Set restore "Left Upper arm" <0.398, 0, 1.5357> <0, 0, 0, 1>
Set restore "Left Lower arm" <0.6811, 0, 1.5357> <0, 0, 0, 1>
Set restore "Left Hand" <0.89917, 0, 1.53565> <0, 0, 0, 1>

Set restore "Right Clavicle" <-0.0231, 0, 1.53565> <-0, -0.70711, -0, 0.70711>
Set restore "Right Upper arm" <-0.398, 0, 1.5357> <0, 0, 0, 1>
Set restore "Right Lower arm" <-0.6811, 0, 1.5357> <0, 0, 0, 1>
Set restore "Right Hand" <-0.89913, 0, 1.53565> <0, 0, 0, 1>

Set restore "Thorax" <0, 0, 1.37854> <0, 0, 0, 1>
Set restore "Abdomen" <0, 0, 1.16504> <0, 0, 0, 1>

Set restore "Left Thigh" <0.0979, 0, 0.7515> <0, 0, 0, 1>
Set restore "Left Calf" <0.0979, 0, 0.2841> <0, 0, 0, 1>
Set restore "Left Foot" <0.0979, -0.08084, 0.05029> <0, 0, 0, 1>
Set restore "Left Heel" <0.0979, 0.0275, 0.02832> <0, 0, 0, 1>

Set restore "Right Thigh" <-0.0979, 0, 0.7515> <0, 0, 0, 1>
Set restore "Right Calf" <-0.0979, 0, 0.2841> <0, 0, 0, 1>
Set restore "Right Foot" <-0.0979, -0.08084, 0.05029> <0, 0, 0, 1>
Set restore "Right Heel" <-0.0979, 0.0275, 0.02832> <0, 0, 0, 1>

#   Define parent / child relationships for mechanism

Set parent "Hips"   "Joint: lThigh" "Joint: rThigh" "Joint: abdomen"

    Set parent "Joint: lThigh"   "Left Thigh" "Joint: lShin"
        Set parent "Joint: lShin"   "Left Calf" "Joint: lFoot"
            Set parent "Joint: lFoot"   "Left Foot" "Left Heel"

    Set parent "Joint: rThigh"   "Right Thigh" "Joint: rShin"
        Set parent "Joint: rShin"   "Right Calf" "Joint: rFoot"
            Set parent "Joint: rFoot"   "Right Foot" "Right Heel"

    Set parent "Joint: abdomen"   "Abdomen" "Joint: chest"
        Set parent "Joint: chest"    "Thorax" "Shoulders" "Joint: lCollar"  "Joint: rCollar" "Joint: neck"

        Set parent "Joint: neck"   "Neck" "Joint: head"
            Set parent "Joint: head"   "Head" "Nose" "Mouth"

        Set parent "Joint: lCollar"   "Left Clavicle" "Joint: lShldr"
            Set parent "Joint: lShldr"   "Left Upper arm" "Joint: lForeArm"
                Set parent "Joint: lForeArm"   "Left Lower arm" "Joint: lHand"
                    Set parent "Joint: lHand" "Left Hand"

        Set parent "Joint: rCollar"   "Right Clavicle" "Joint: rShldr"
            Set parent "Joint: rShldr"   "Right Upper arm" "Joint: rForeArm"
                Set parent "Joint: rForeArm"  "Right Lower arm" "Joint: rHand"
                    Set parent "Joint: rHand" "Right Hand"
