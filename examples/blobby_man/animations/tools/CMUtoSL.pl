
    #   Transform and extract a CMU motion capture file
    #   converted to DAZ format:
    #
    #       https://www.sites.google.com/a/cgspeed.com/cgspeed/motion-capture/daz-friendly-release
    #
    #   to a BVH animation usable with Second life.
    #
    #       CMUtoSL start_frame end_frame frames_per_second [ DAZfile.bvh ]
    #

    #   We make some assumptions about the generality of Second
    #   Life's BVH processing on uploads which can only be
    #   verified experimentally.
    #
    #       1.  It is OK to omit parts of the hierarchy
    #           which are not used by the standard avatar
    #           animations (neckDummy and figureHair).
    #       2.  Animation channel co-ordinates may be
    #           specified in any order, and need not be
    #           in the order used in the example standard
    #           animation BVH files.
    #       3.  Indentation rules are not strictly enforced,
    #           and spaces may be used instead of tab characters.
    #       4.  End of line convention may be Unix or DOS/Windows.

    use strict;
    use warnings;

    use Text::Tabs;
    use Getopt::Long;
    use POSIX qw(ceil);

    use constant PI => (4 * atan2(1, 1));
    use constant RAD_TO_DEG => (180 / PI);
    use constant DEG_TO_RAD => (PI / 180);

    #   Command line argument defaults and parsing

    my $nokeyframe = 0;             # No synthetic keyframe generation
    my $globrot = "";               # Adjust global rotation of model
    my $gsign = 0;                  # If global rotation relative, sign, else 0
    my $start_frame = 1;            # Start frame in input
    my $end_frame = -1;             # End frame in input
    my $fps = 15;                   # Frames per second in output
    my $scale = 1 / 2.0932;         # Scale of output root positions to input
    my $trace = 0;                  # Trace parsing of file
    my $verbose = 0;                # Generate internal processing output

    GetOptions("start=i", \$start_frame,
               "end=i", \$end_frame,
               "fps=f", \$fps,
               "nokeyframe", \$nokeyframe,
               "grotate=s", \$globrot,
               "scale=f", \$scale,
               "trace", \$trace,
               "verbose", \$verbose) ||
        die("Error in command line options.\n");

    my $channelIndex = 0;           # Next source channel number
    my @chmap;                      # Map input to output channels
    my %rotchan;                    # ROOT rotation channel indices
    my @rotorder;                   # ROOT rotation channel order
    my $nesting = 0;                # Parenthesis nesting depth
    my $lineno = 0;                 # Source line number

    my %chaxes = (                  # Basis vectors for axes
        X => [ 1, 0, 0 ],
        Y => [ 0, 1, 0 ],
        Z => [ 0, 0, 1 ]
    );

    if ($trace) {
        open(TR, ">trace.out") || die("Cannot create trace.out");
    }

    if ($globrot ne "") {
        if ($globrot =~ s/^([\+\-])//) {
            $gsign = ($1 eq "+") ? 1 : -1;
        }
        $globrot = $globrot + 0;
    } else {
        $globrot = 0;
        $gsign = 0;
    }

    xscribe(qr/JOINT\s+leftEye/, 1);    # Copy until leftEye
    skipnest(0);                        # Skip leftEye definition
    xscribe(qr/JOINT\s+rightEye/, 0);   # Skip rightEye head
    skipnest(0);                        # Skip rightEye definition
    endSite(0, 0, 0);                   # End head structure

    #   Now we move on to the right arm, and specifically the fingers

    xscribe(qr/JOINT\s+rThumb1/, 1);    # Copy to right thumb
    skipnest(0);
    xscribe(qr/JOINT\s+rIndex1/, 0);    # Skip right index
    skipnest(0);
    xscribe(qr/JOINT\s+rMid1/, 0);      # Skip right middle
    skipnest(0);
    xscribe(qr/JOINT\s+rRing1/, 0);     # Skip right ring
    skipnest(0);
    xscribe(qr/JOINT\s+rPinky1/, 0);    # Skip right pinky
    skipnest(0);
    endSite(0, 0, 0);                   # End right hand

    #   Onward to the left arm and hand

    xscribe(qr/JOINT\s+lThumb1/, 1);    # Copy to left thumb
    skipnest(0);
    xscribe(qr/JOINT\s+lIndex1/, 0);    # Skip left index
    skipnest(0);
    xscribe(qr/JOINT\s+lMid1/, 0);      # Skip left middle
    skipnest(0);
    xscribe(qr/JOINT\s+lRing1/, 0);     # Skip left ring
    skipnest(0);
    xscribe(qr/JOINT\s+lPinky1/, 0);    # Skip left pinky
    skipnest(0);
    endSite(0, 0, 0);                   # End left hand

    #   Now, for the legs, it's a little more complicated.
    #   The DAZ file articulates the legs from a buttock
    #   joint which doesn't appear in the Second Life
    #   standard avatar skeleton.  We delete the Buttock
    #   joint and transcribe to the thigh.

    #   Downward to the right buttock

    xscribe(qr/JOINT\s+rButtock/, 1);   # Copy to right buttock
    xscribe(qr/JOINT\s+rThigh/, 0);     # Skip to right thigh
    additem("JOINT rThigh");
    skipnest(1);                        # Copy leg structure

    #   Wind up with the left buttock

    xscribe(qr/JOINT\s+lButtock/, 0);   # Copy to right buttock
    xscribe(qr/JOINT\s+lThigh/, 0);     # Skip to right thigh
    additem("JOINT lThigh");
    skipnest(1);                        # Copy leg structure

    #   Advance to MOTION section

    xscribe(qr/MOTION/, 0);

    if ($nesting != 0) {
        print(STDERR "$lineno.  Nesting nonzero ($nesting) at end of hierarchy.\n");
    }
    additem("}");                       # Close ROOT of hierarchy

    if ($trace) {
        print(TR "Channel map: " . join(", ", @chmap) . "\n");
    }

    additem("MOTION");

    #   Parse and verify frame count and time

    my ($nFrames, $tFrame);

    if (my $l = <>) {
        $l = inl($l);
        if ($l =~ m/Frames:\s+(\d+)/) {
            $nFrames = $1;
        } else {
            print(STDERR "$lineno.  Frames: expected, received $l.\n");
            exit(2);
        }
    } else {
        print(STDERR "$lineno.  EOF where Frames: expected.\n");
        exit(2);
    }

    if (my $l = <>) {
        $l = inl($l);
        if ($l =~ m/Frame\s+Time:\s+([\d\.]+)/) {
            $tFrame = $1;
        } else {
            print(STDERR "$lineno.  Frame Time: expected, received $l.\n");
            exit(2);
        }
    } else {
        print(STDERR "$lineno.  EOF where Frame Time: expected.\n");
        exit(2);
    }

    #   Compute our frame information

    if ($end_frame < 0) {           # If no end frame specified...
        $end_frame = $nFrames;      # ...default to all frames
    }
    if ($fps < 0) {                 # If no frames per second specified...
        $fps = 1 / $tFrame;         # ...use value from input file
    }

    my $iframes = ($end_frame - $start_frame) + 1;

    #   If requested frames per second is less than that
    #   of the input, compute the sampling rate of input
    #   frames and adjust the number of output frames
    #   accordingly.

    my $framesamp = 1;
    if ($fps < (1 / $tFrame)) {
        $framesamp = int(((1 / $tFrame) / $fps) + 0.5);
    }
    my $oframes = ceil($iframes / $framesamp) + ($nokeyframe ? 0 : 1);

    if ($verbose) {
        print(STDERR "start_frame $start_frame  end_frame $end_frame  nFrames $nFrames  tFrame $tFrame\n");
        print(STDERR "iframes $iframes  framesamp $framesamp  fps $fps  oframes $oframes\n");
    }

    additem("Frames: " . $oframes);
    additem(sprintf("Frame Time: %g", 1 / $fps));

    #   Skip to the first frame to be output

    my $iframe = 0;
    my $fsamp = 0;
    my $Oframe = 0;
    while (my $l = <>) {
        my $l = inl($l);
        $iframe++;
        if (($iframe >= $start_frame) && ($iframe <= $end_frame)) {
            if ($fsamp == 0) {
                compframe($l);
                $Oframe++;
                if ($verbose) {
                    print(STDERR "  Iframe $iframe  ->  Oframe $Oframe\n");
                }
            }
            $fsamp++;
            if ($fsamp >= $framesamp) {
                $fsamp = 0;
            }
        } elsif ($iframe > $end_frame) {
            last;
        }
    }

    if ($trace) {
        close(TR);
    }

    #   Transcribe/skip until we find a line with a given pattern.
    #   Updates nesting count and channels as we go.

    sub xscribe {
        my ($pattern, $copy) = @_;

        while (my $l = <>) {
            $l = inl($l);
            upstruct($l, $copy);
            if ($l =~ m/$pattern/i) {
                if ($trace) {
                    print(TR "- $lineno.  $nesting  $channelIndex  " .
                        scalar(@chmap) . "  $l\n");
                }
                return;
            }
            if ($trace) {
                print(TR ($copy ? "+" : "-") .
                    " $lineno.  $nesting  $channelIndex  " .
                    scalar(@chmap) . "  $l\n");
            }
            if ($copy) {
                print("$l\n");
            }
        }
        print(STDERR "$lineno: Failed to find pattern /$pattern/ by EOF.\n");
        exit(2);
    }

    #   Skip/copy a nested structure delimited by braces

    sub skipnest {
        my ($copy) = @_;

        my $l;
        my $startnest = $nesting;
        my $startline = $lineno;
        my $cskip = $copy ? "+" : "-";
        if ($l = <>) {
            $l = inl($l);
            upstruct($l, $copy);
            if ($trace) {
                print(TR "$cskip $lineno.  $nesting  $channelIndex  " .
                    scalar(@chmap) . "  $l\n");
            }
            if ($copy) {
                print("$l\n");
            }
            if ($l =~ m/{/) {
                while ($l = <>) {
                    $l = inl($l);
                    upstruct($l, $copy);
                    if ($trace) {
                        print(TR "$cskip $lineno.  $nesting  $channelIndex  " .
                            scalar(@chmap) . "  $l\n");
                    }
                    if ($copy) {
                        print("$l\n");
                    }
                    if ($nesting == $startnest) {
                        return;
                    }
                }
                print(STDERR "$lineno. EOF closing skipnest started at line $startline.\n");
            } else {
                print(STDERR "$lineno. Opening brace not found by skipnest.\n");
            }
        } else {
            print(STDERR "$lineno: EOF at start of skipnest.\n");
            exit(2);
        }
    }

    #   Adds an item to the hierarchy structure

    sub additem {
        my ($l) = @_;

        my $il = "";
        for (my $i = 0; $i < $nesting; $i++) {
            $il .= "        ";
        }
        print("$il$l\n");
        if ($trace) {
            print(TR "* $lineno.  $nesting  $channelIndex  " .
                scalar(@chmap) . "  $il$l\n");
        }
    }

    #   Keep track of file structure and channels as we parse

    sub upstruct {
        my ($l, $transcribing) = @_;

        if ($l =~ m/{/) {
            $nesting++;
        } elsif ($l =~ m/}/) {
            $nesting--;
            if ($nesting < 0) {
                print(STDERR "$lineno: Structure nesting underflow.\n");
                exit(2);
            }
        } elsif ($l =~ m/CHANNELS\s+(\d+)\s/i) {
            my $nchans = $1;
            if ($transcribing) {
                for (my $i = 0; $i < $nchans; $i++) {
                    push(@chmap, $channelIndex + $i);
                }
            }
            $channelIndex += $nchans;
            #   If this is the ROOT declaration of the
            #   its position and rotation channels, save
            #   the channel numbers of the rotation angles.
            if ($nchans == 6) {
                if ($l =~ m/CHANNELS\s+\d+\s+(\S.*)$/i) {
                    my $chnames = $1;
                    $chnames =~ s/\s+/ /;
                    my @chlist = split(/\s+/, $chnames);
                    my $chindex = 0;
                    my $chord = 0;
                    foreach my $chan (@chlist) {
                        if ($chan =~ m/([XYZ])rotation/) {
                            my $axis = $1;
                            $rotchan{$axis} = $chindex;
                            $rotorder[$chord++] = $axis;
                        }
                        $chindex++;
                    }
                } else {
                    print(STDERR "$lineno: Cannot parse root CHANNEL names.\n");
                }
            }
        }
    }

    #   Generate an End Site sequence

    sub endSite {
        my ($ox, $oy, $oz) = @_;

        additem("End Site");
        additem("{");
        additem(sprintf("        OFFSET  %g %g %g", $ox, $oy, $oz));
        additem("}");

    }

    #   Compile frame channel data

    sub compframe {
        my ($l) = @_;

        my @chan = split(/\s+/, $l);

        my $of = "";

        #   If automatic keyframe generation is enabled and this
        #   is the first frame, synthesise a key frame with the
        #   position of the root element.  The rotation of the
        #   root element in the key frame is set to all zeroes,
        #   preserving rotations in the capture frames unless
        #   $derot is set, in which case the Y (vertical axis)
        #   rotation is copied from the first motion capture frame,
        #   which has the effect of removing any global rotation
        #   from the frames that follow.

        if ((!$nokeyframe) && ($Oframe == 0)) {
            for (my $i = 0; $i < scalar(@chmap); $i++) {
                my $v = $chan[$chmap[$i]];
                #   If this is one of the position co-ordinates
                #   of the root component, apply the position
                #   scale factor to it.
                if ($i < 3) {
                    $v *= $scale;
                } elsif (($globrot ne "") && ($i == $rotchan{Y})) {
                    if ($gsign != 0) {
                        $v = $chan[$chmap[$i]] + ($globrot * $gsign);
                    } else {
                        $v = $globrot;
                    }
                } else {
                    #   Zero out all joint rotation angles
                    $v = 0;
                }
                $of .= sprintf("%g ", $v);
            }
            $of =~ s/\s+$//;

            print("$of\n");
            $of = "";
            $Oframe++;
            if ($verbose) {
                print(STDERR "  Keyframe  ->  Oframe $Oframe\n");
            }
        }

        for (my $i = 0; $i < scalar(@chmap); $i++) {
            my $v = $chan[$chmap[$i]];
            #   If this is one of the position co-ordinates
            #   of the root component, apply the position
            #   scale factor to it.
            if ($i < 3) {
                $v *= $scale;
            }
            $of .= sprintf("%g ", $v);
        }
        $of =~ s/\s+$//;

        print("$of\n");
    }

    #   Preprocess input line

    sub inl {
        my ($l) = @_;

        chomp($l);
        $l =~ s/\s+$//;
        $l = expand($l);
        $lineno++;
        return $l;
    }
