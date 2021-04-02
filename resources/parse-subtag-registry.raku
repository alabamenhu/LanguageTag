#
#      ▄█▀▀▀█▄███▀▀██▀▀███ ▄▄█▀▀██▄ ▀███▀▀▀██▄
#     ▄██    ▀█▀   ██   ▀███▀    ▀██▄ ██   ▀██▄
#     ▀███▄        ██    ██▀      ▀██ ██   ▄██
#       ▀█████▄    ██    ██        ██ ███████
#     ▄     ▀██    ██    ██▄      ▄██ ██
#     ██     ██    ██    ▀██▄    ▄██▀ ██
#     █▀█████▀   ▄████▄    ▀▀████▀▀ ▄████▄
#
# Read the notices below before making any changes
#
#
#
# WARNING: If changing this file (in particular what is output), you
#          MUST adjust the BCP47.pm6 file.  Double check .t results.
#
#  The language subtag registry is located at
#  <https://www.iana.org/assignments/language-subtag-registry>
#  It is not included with this distribution because no specific license could
#  be found on the IANA website.  The result of processing the files, being
#  merely data, presents no impediment to being included.  If the registry is
#  updated, just place a copy of the above file in this resources directory,
#  run the script, and force the recompile of Subtag-Registry.pm6 (phasers
#  are used to set the data on compile only).
#
#  Yes this file is ugly.  I don't think it's worth refactoring
=begin pod
I have tried to account for the display of certain errors, but they might sometimes
be LTA.  Note the single requirement for this script

=item C<LibCurl> (requires L<curl|https://curl.haxx.se/>)

To run, just use the command

    raku parse-subtag-registry.raku

If the registry is not found, it will be downloaded (~700KB).  If the
registry has been updated, you can force an update to it:

    raku parse-subtag-registry.raku --update

First we have a few constants:
=end pod


constant clear-line = "\x001b[2K";

sub MAIN (Bool :$update = False) {
    use LibCurl::Easy;
    if !("language-subtag-registry".IO.e)
    || $update {
        print "{ $update ?? "Updating" !! "Downloading"} IANA subtag registry (~700kB)... ";
        LibCurl::Easy.new(
            URL => 'https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry',
            download => $*PROGRAM.sibling('language-subtag-registry').Str,
            useragent => 'Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0'
        ).perform;
        say  "OK";
    }

    my $registry            = slurp "language-subtag-registry";
    my @records             = $registry.split(/\%\%\n/);

    my IO::Handle $languages-valid      = open "languages-valid",      :w;
    my IO::Handle $languages-deprecated = open "languages-deprecated", :w;
    my IO::Handle $languages-script     = open "languages-script",     :w;
    my IO::Handle $languages-macro      = open "languages-macro",      :w;
    my IO::Handle $languages-preferred  = open "languages-preferred",  :w;

    my IO::Handle $scripts-valid      = open "scripts-valid",      :w;
    my IO::Handle $scripts-deprecated = open "scripts-deprecated", :w;

    my IO::Handle $regions-valid      = open "regions-valid",      :w;
    my IO::Handle $regions-deprecated = open "regions-deprecated", :w;
    my IO::Handle $regions-preferred  = open "regions-preferred",  :w;

    my IO::Handle $variants-valid      = open "variants-valid",      :w;
    my IO::Handle $variants-deprecated = open "variants-deprecated", :w;
    my IO::Handle $variants-prefixes   = open "variants-prefixes",   :w;

    #my $languages-enum-file = open "enum/languages.data",:w;
    #my $extlangs-file       = open "extlangs.data",      :w;
    #my $scripts-file        = open "scripts.data",       :w;
    #my $scripts-enum-file   = open "enum/scripts.data",  :w;
    #my $regions-file        = open "regions.data",       :w;
    #my $regions-enum-file   = open "enum/regions.data",  :w;
    #my $variants-file       = open "variants.data",      :w;
    #my $variants-enum-file  = open "enum/variants.data", :w;
    #my $redundancies-file   = open "redundancies.data",  :w;
    #my $grandfathered-file  = open "grandfathered.data", :w;

    #my %enum-override = do for "enum-override.data".IO.lines.grep(none *.starts-with('#')) {
    #    my ($orig, $over) = $_.split('=>');
    #    $orig.subst(/\s/,'',:g) => $over.trim;
    #}


    #sub format-description($d) {
    #    my $d2 = %enum-override{$d.subst(/\s/,'',:g)} // $d;
    #    $d2.subst(/(<< <:Ll>)/, {$0.uc},:g)   # capitalize initial words
    #       .subst(/    <:P>  /,      '',:g)   # remove punctuation
    #       .subst(/    <:Z>  /,      '',:g);  # remove spacing
    #}

    my $stage = 0;

    for @records -> $record {
        $record ~~ / 'Type: ' (\S+)/;
        my $type = $0 ?? $0.Str !! '';
        $record ~~ / 'Subtag: ' (\S+)/;
        my $code = $0 ?? $0.Str !! '';
        $record ~~ / 'Tag: ' (\S+)/;
        my $tag = $0 ?? $0.Str !! '';
        $record ~~ m:g/ 'Description: ' (<-[\n]>+ [\n\h+ <-[\n]>+]*)/;
        my @descriptions = $/ ?? $/.map(*.head.Str) !! ();
        $record ~~ / 'Suppress-Script: '(\S+)/;
        my $script = $0 ?? $0.Str !! '';
        $record ~~ / 'Preferred-Value: '(\S+)/;
        my $preferred = $0 ?? $0.Str !! '';
        $record ~~ m:g/ 'Prefix: ' <(\S+)>/;
        my $prefixes = $/ ?? $/>>.Str !! Empty;
        $record ~~ / 'Macrolanguage: '(\S+)/;
        my $macro = $0 ?? $0.Str !! '';
        my $deprecated = ?($record ~~ / 'Deprecated'/);

        if $type eq 'language' {
            print clear-line, "\rParsing languages ... $code ({ @descriptions ?? @descriptions.head.lines[0] !! '' })";
        } elsif $type eq 'script' {
            say clear-line, "\rParsing languages ... OK" and $stage++ if $stage == 0;
            print clear-line, "\rParsing scripts ... $code ({ @descriptions ?? @descriptions.head.lines[0] !! '' })";
        } elsif $type eq 'region' {
            say clear-line, "\rParsing scripts ... OK" and $stage++ if $stage == 1;
            print clear-line, "\rParsing regions ... $code ({ @descriptions ?? @descriptions.head.lines[0] !! '' })";
        } elsif $type eq 'variant' {
            say clear-line, "\rParsing regions ... OK" and $stage++ if $stage == 2;
            print clear-line, "\rParsing variants ... $code ({ @descriptions ?? @descriptions.head.lines[0] !! '' })";
        }
        my @codes;
        if $code ~~ /(\S+)'..'(\S+)/ {
            @codes = $0.Str .. $1.Str;
        } else {
            @codes = $code;
        }


        for @codes -> $code {
            given $type {
                when 'language' {
                    $languages-valid.say:      $code;
                    $languages-deprecated.say: $code              if $deprecated;
                    $languages-script.say:    "$code\n$script"    if $script;
                    $languages-macro.say:     "$code\n$macro"     if $macro;
                    $languages-preferred.say: "$code\n$preferred" if $preferred;
                    #$languages-file.say: "$code,$script,$macro,$preferred" ~ ( '!' if $deprecated);
                    #unless $deprecated {
                    #    for @descriptions -> $description is rw {
                    #        $description = %enum-override{$description.subst(/\s/,'',:g)} // $description;
                    #        my $description-enum = $description
                    #            .subst(/(<< <:Ll>)/, {$0.uc},:g)   # capitalize initial words
                    #            .subst(/    <:P>  /,      '',:g)   # remove punctuation
                    #            .subst(/    <:Z>  /,      '',:g);
                    #        # remove whitespace
                    #        #$languages-enum-file.say: "$description-enum,$code" unless $description-enum eq 'PrivateUse';
                    #        #say "$code = LanguageTag::$description-enum";
                    #    }
                    #}
                }
    #`<<<            when 'extlang' {
                    $extlangs-file.say: "$code,$prefix,$script,$preferred" ~ ('!' if $deprecated);
                }>>>
                when 'script' {
                    $scripts-valid.say: $code; # no deprecated ones, even though CLDR lists as such
                    $scripts-deprecated.say: $code if $deprecated; # no deprecated ones, even though CLDR lists as such
                    #unless $deprecated {
                    #    for @descriptions {
                    #        my $description-enum = format-description $_;
                    #        $scripts-enum-file.say("$description-enum,$code") unless $description-enum eq 'PrivateUse'
                    #    }
                    #}
                }
                when 'region' {
                    $regions-valid.say: $code;
                    $regions-deprecated.say: $code if $deprecated;
                    $regions-preferred.say: "$code\n$preferred" if $preferred;
                    #unless $deprecated {
                    #    for @descriptions {
                    #        my $description-enum = format-description $_;
                    #        $regions-enum-file.say("$description-enum,$code") unless $description-enum eq 'PrivateUse'
                    #    }
                    #}
                }
                when 'variant' {
                    $variants-valid.say: $code;
                    $variants-deprecated.say: $code if $deprecated;
                    $variants-prefixes.say: "$code\n{$prefixes.join: ','}" if $prefixes;

                    # TODO it is possible for there to be multiple prefixes !
                    #$variants-file.say: "$code,$prefix,$preferred" ~ ( '!' if $deprecated);
                    #unless $deprecated {
                    #    $variants-enum-file.say: "{format-description $_},$code" for @descriptions
                    #}
                }
                #`<<<when 'redundant' {
                    $redundancies-file.say: "$tag,$preferred" ~ ( '!' if $deprecated)
                }
                when 'grandfathered' {
                    $grandfathered-file.say: "$tag,$preferred" ~ ( '!' if $deprecated);
                }
                default  {
                    # The only record not processed should contain the date.
                    $record ~~ /(\d+\-\d+\-\d+) /;
                    print "Processing language subtag registry dated ", $0.Str, "...";
                }>>>
            }
        }
    }
    say clear-line, "\rParsing variants ... OK";
    say "Done.";

    close $languages-valid;
    close $languages-deprecated;
    close $languages-script;
    close $languages-macro;
    close $languages-preferred;

    close $scripts-valid;
    close $scripts-deprecated;
    #close $extlangs-file;
    #close $scripts-file;
    #close $regions-file;
    #close $variants-file;
    #close $redundancies-file;
    #close $grandfathered-file;
}