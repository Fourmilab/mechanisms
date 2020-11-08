
    #   Compile animation from Fourmilab Second Life's Blobby Man

    #   This program reads a copy-and-pasted transcript from
    #   the chat output of a Blobby Man animation compilation.
    #   The animation information is flagged with sentinels
    #   which allow extracting it from a "noisy" chat transcript
    #   which may contain extraneous traffic.  Reasonably
    #   comprehensive error checking is performed to detect
    #   sequence errors and omissions in the animation data.

    use strict;
    use warnings;

    my $uglify = 1;             # Deter editing of player code ?

    my $state = 0;              # Current parser state
    my $lineno = 0;             # Input line number
    my $orElse = "";            # Are we compiling else clause ?
    my $frame = -1;             # Current frame
    my $lastframe = -1;         # Previous frame
    my $expseg;                 # Expected segment number
    my $startseen = 0;          # Start sentinel seen ?
    my $endseen = 0;            # End sentinel seen ?
    my $maxFrames = 19;         # Maximum frames per segment

    my $sent = qr(\-\-\-\-\-\-\-\-\-\-);
    my $player = "animation_player.lsl";    # Animation player source code

    my $nSegments;              # Number of segments required

    my $cseg;                   # Current output segment
    my $frameseg;               # Frames in current segment
    my $ofname;                 # Base output file name
    my $ofile;                  # Output file for this segment

    my $toolsDir;               # Our resources directory

    #   Animation header information
    my ($Aname, $Asframe, $Aeframe, $Anframes, $Aftime, $Avscale, $Anodes);

    $toolsDir = __FILE__;
    $toolsDir =~ s:/[^/]*$::;

    while (my $l = <>) {
        chomp($l);
        $l =~ s/^.*:\s\-\-/--/;
        $lineno++;

        if ($state == 0) {
            #   Start of animation sentinel
            if ($l =~ m/$sent\sCompiling\sanimation\s"([^"]*)":\sFrames\s(\d+)\-(\d+)\sof\s(\d+)\sTime\s([\d\.]+)\sVscale\s([\d\.]+)\sNodes\s(\d+)\s$sent/) {
                ($Aname, $Asframe, $Aeframe, $Anframes, $Aftime, $Avscale, $Anodes) = ($1, $2, $3, $4, $5, $6, $7);
                if ($startseen) {
                    print(STDERR "$lineno.  Error: Duplicate start animation sentinel.\n");
                }
                $startseen = 1;
                $Aname =~ s/^BVH:\s+//;     # Discard BVH: prefix, if present
                #   If this compilation included the reference frame (Frame 0),
                #   exclude it as it is not compiled to output.
                if ($Asframe == 0) {
                    $Asframe = 1;
                    $Anframes--;
                }
                $nSegments = int(((($Aeframe - $Asframe) + 1) + ($maxFrames - 1)) / $maxFrames);
                print(STDERR "$Aname: generating $nSegments segment" .
                    ($nSegments == 1 ? "" : "s") . ".\n");
                $cseg = 0;
                $frameseg = 0;
                genHeader($Asframe, $Aeframe);
                $lastframe = $Asframe - 1;
            #   Start of frame sentinel
            } elsif ($l =~ m/$sent\sFrame (\d+)\s$sent/) {
                $frame = $1;

                #   If current segment is full, close it out and start next segment

                if ($frameseg >= $maxFrames) {
                    print($ofile "        }\n");
                    $orElse = "";
                    genFooter();
                    genHeader($frame, $Aeframe);
                    $frameseg = 0;
                }

                if ($frame != ($lastframe + 1)) {
                    print(STDERR "$lineno.  Error: Frame number sequence incorrect.  " .
                        "Expected " . ($lastframe + 1) . ", received $frame.\n");
                }
                $lastframe = $frame;

                if (!$startseen) {
                    print(STDERR "$lineno.  Error: Missing start animation sentinel before frame $frame.\n");
                }
                print($ofile "        ${orElse}if (f == $frame) {\n");
                print($ofile "            expandFrame([\n");
                $state = 1;
                if ($orElse eq "") {
                    $orElse = "} else ";
                }
                $expseg = 0;
            #   End of animation sentinel received
            } elsif ($l =~ m/$sent\sAnimation compilation complete\s$sent/) {
                if ($frame < 0) {
                    print(STDERR "$lineno.  Error: End animation sentinel seen before " .
                        "any frames.\n");
                }
                if ($frame != $Aeframe) {
                    print(STDERR "$lineno.  Error: Declared last frame $Aeframe not " .
                        "seen before end of animation sentinel.\n");
                }
                $endseen = 1;
                print($ofile "        }\n");
                genFooter();
            }
        } elsif ($state == 1) {
            #   Accumulating content of frame
            if ($l =~ m/\-\-\s$frame\.(\d+)\s\-\-\s(.*)$/) {
                my ($seg, $chans) = ($1, $2);
                if ($seg != $expseg) {
                    print(STDERR "$lineno.  Error: Segment $frame.$expseg expected, " .
                        "segment $seg received.\n");
                }
                $expseg++;
                $chans =~ s/\s//g;      # Elide embedded spaces
                print($ofile "    $chans\n");
            #   End of frame sentinel received
            } elsif ($l =~ m/$sent\sEnd\sframe\s(\d+),\slines\s(\d+)\s$sent/) {
                my ($eframe, $elines) = ($1, $2);
                print($ofile "            ]);\n");
                $state = 0;
                $frameseg++;                # Increment frames in segment
                if ($eframe != $frame) {
                    print(STDERR "$lineno.  Error: mismatched End frame.  Expected $frame, " .
                        "received $eframe.\n");
                }
                if ($elines != $expseg) {
                    print(STDERR "$lineno.  Error: end frame line count $elines " .
                        "doesn't match last $expseg segments received.\n");
                }
            #   End of animation sentinel
            } elsif ($l =~ m/$sent\sAnimation compilation complete\s$sent/) {
                print(STDERR "$lineno.  Error: End animation sentinel seen before " .
                    "end of frame $frame.\n");
            }
            #   Ignore any other chatter interrupting the frame
        }
    }

    if (!$startseen) {
        print(STDERR "End of file.  No start animation sentinel seen.\n");
    }
    if ($frame < 0) {
        print(STDERR "End of file.  No frames processed.\n");
    }
    if (!$endseen) {
        print(STDERR "End of file.  No end animation sentinel seen.\n");
    }

    #   Generate header for the animation script segment

    sub genHeader {
        my ($fframe, $lframe) = @_;

        $ofname = $Aname;
        $ofname =~ s/\s+/_/g;
        $cseg++;
        open($ofile, ">$ofname-${cseg}_$nSegments.lsl") ||
            die("Cannot create $ofname-${cseg}_$nSegments.lsl");

        my $rframes = ($Aeframe - $fframe) + 1;         # Remaining frames
        if ($rframes > $maxFrames) {
            $lframe  = $fframe + ($maxFrames - 1);
        } else {
            $lframe = $Aeframe;
        }

        print($ofile "\n//  Fourmilab Blobby Man animation: $Aname  (Segment $cseg of $nSegments)\n\n");
        print($ofile "    string animation = \"$Aname\";  // Name of this animation\n");
        print($ofile "    integer frameStart = $fframe;  // First frame in this segment\n");
        print($ofile "    integer frameEnd = $lframe;  // Last frame in this segment\n");
        printf($ofile "    integer frameLast = %d;  // Last frame of entire animation\n", $Aeframe);
        printf($ofile "    float frameTime = %g;  // Time per frame\n", $Aftime);
        print($ofile "\n");
        print($ofile "    playFrame(integer f) {\n");
    }

    #   Transcribe the canned animation player to the end of the script

    sub genFooter {
        print($ofile "    }\n");        # Close playFrame function

        #   Transcribe animation player to end of file

        open(FI, "<$toolsDir/$player") || die("Cannot open $toolsDir/$player");

        print($ofile "\n// STANDARD ANIMATION PLAYER: DO NOT EDIT THIS CODE.\n");
        print($ofile "// IF YOU NEED TO CHANGE, EDIT MASTER AND RE-GENERATE ANIMATION.\n\n");

        my $incom = 0;
        while (my $fl = <FI>) {
            chomp($fl);

            #   Uglify animation player to deter users' editing it

            if ($uglify) {
                $fl =~ s:\s//\s.*$::;
                $fl =~ s/\s+/ /g;
                $fl =~ s/^\s+//;
                if ((!$incom) && ($fl =~ m:^/\*:)) {
                    $incom = 1;
                }
                if ($incom && ($fl =~ m:\*/$:)) {
                    $incom = 0;
                    next;
                }
            }

            if ((!$incom) && $fl !~ m/^\s*$/) {
                print($ofile "$fl\n");
            }
        }
        close(FI);
        close($ofile);
    }
