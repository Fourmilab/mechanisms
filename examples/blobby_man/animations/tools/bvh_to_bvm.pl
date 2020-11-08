
    #       Fix BVH file so Second Life can read it from a notecard

    #       Second Life notecards are limited to a maximum line length
    #       255 characters, with anything beyond that silently
    #       truncated.  The channel data records in BVH files consist
    #       of as many floating point triples as declared in the
    #       hierarchy section, with no limit on line length.

    #       This program re-formats the MOTION section to place a
    #       maximum of 3 numbers per line.  The multiple-line records
    #       are annotated with a line number and frame number comment
    #       to aid in manual interpretation and debugging of parsers.

    #       The program reads from standard input and writes its output
    #       to standard output.  By convention, we call these
    #       re-formatted files BVM (BVH Modfied) and, when storing them
    #       on the development machine, give them a file type of .bvm.

    use strict;
    use warnings;

    #   Skip file header until we reach the start of the frame channel data

    while (my $l = <>) {
        chomp($l);
        $l =~ s/\s+$//;
        print("$l\n");
        if ($l =~ m/^Frame\s+Time:/) {
            last;
        }
    }

    #   Read frame channel data and split into three numbers per line

    my $frameno = 0;
    while (my $l = <>) {
        chomp($l);
        $l =~ s/\s+$//;
        my $n = 1;
        my $fcom = "  Frame $frameno";
        $frameno++;
        while ($l =~ s/^\s*(\S+\s+\S+\s+\S+)\s*//) {
            my $c = $1;
            #   Re-generate numbers with %g to remove insignificant
            #   zeroes after the decimal point and compress file size
            #   so it doesn't exceed the maximum for a Notecard.
            $c = "$c ";
            $c =~ m/^(\S+\s+)(\S+\s+)(\S+)/ || die("Cannot parse number in frame $frameno: $c");
            $c = sprintf("%g %g %g", $1, $2, $3);
            print("$c # $n$fcom\n");
            $fcom = "";
            $n++;
        }
        if ($l !~ m/^\s*$/) {
            print("$l # \n");
        }
    }
