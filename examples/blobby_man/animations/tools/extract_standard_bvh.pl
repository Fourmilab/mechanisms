
    #       Extract information from the standard Second Life animation
    #       BVH file to permit generation by our Export BVH command.

    #       The program reads from standard input and writes its output
    #       to standard output.

    use strict;
    use warnings;
    use Text::Tabs;

    use Data::Dumper;

    my @joints;
    my @channels;
    my @sigs;

    #   Define the numerical permutations of the axes

    my %axperms = (
        XYZ => 1,
        XZY => 2,
        YXZ => 3,
        YZX => 4,
        ZXY => 5,
        ZYX => 6
    );

    #   Compose axis signature from CHANNEL declaration for joint

    sub axsig {
        my ($idx) = @_;

        my $sig = "";
        $channels[$idx] =~ m/(\w)/;
        $sig = $1;
        $channels[$idx + 1] =~ m/(\w)/;
        $sig .= $1;
        $channels[$idx + 2] =~ m/(\w)/;
        $sig .= $1;

        return $sig;
    }

    #   Read the file, recording joint names and channel assignments as we go.

    while (my $l = <>) {
        chomp($l);
        $l =~ s/\s+$//;
        $l = expand($l);

        if ($l =~ m/^MOTION/) {
            last;
        }

        if ($l =~ m/(?:ROOT|JOINT)\s+(\S+)/) {
            my $joint = $1;

            push(@joints, $joint);
        }

        if ($l =~ m/CHANNELS\s+(\d+)\s+(\S.*)$/) {
            my ($nchans, $chans) = ($1, $2);
            @channels = split(/\s+/, $chans);
            my $csig = $axperms{axsig(0)};
            if ($nchans == 6) {
                $csig = ($csig * 10) + $axperms{axsig(3)};
            }
            push(@sigs, $csig);
        }
    }

    #   Now we're ready to assemble the magic string that we
    #   parse with llCSV2List() to extract channel axes and
    #   joint names.

    my $chax = "    string bones = \"";

    for (my $i = 0; $i < scalar(@joints); $i++) {
        $chax .= $sigs[$i] . $joints[$i] . ",";
    }
    $chax =~ s/,$//;
    print("$chax\";\n");
