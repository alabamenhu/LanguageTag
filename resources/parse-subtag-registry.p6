
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
#          MUST adjust the file in Subtag-Registry.pm6 to match.
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

my $registry            = slurp "language-subtag-registry";
my @records             = $registry.split(/\%\%\n/);

my $languages-file      = open "languages.data",     :w;
my $languages-enum-file = open "enum/languages.data",:w;
my $extlangs-file       = open "extlangs.data",      :w;
my $scripts-file        = open "scripts.data",       :w;
my $scripts-enum-file   = open "enum/scripts.data",  :w;
my $regions-file        = open "regions.data",       :w;
my $regions-enum-file   = open "enum/regions.data",  :w;
my $variants-file       = open "variants.data",      :w;
my $variants-enum-file  = open "enum/variants.data", :w;
my $redundancies-file   = open "redundancies.data",  :w;
my $grandfathered-file  = open "grandfathered.data", :w;

my %enum-override = do for "enum-override.data".IO.lines.grep(none *.starts-with('#')) {
  my ($orig, $over) = $_.split('=>');
  $orig.subst(/\s/,'',:g) => $over.trim;
}


sub format-description($d) {
    my $d2 = %enum-override{$d.subst(/\s/,'',:g)} // $d;
    $d2.subst(/(<< <:Ll>)/, {$0.uc},:g)   # capitalize initial words
       .subst(/    <:P>  /,      '',:g)   # remove punctuation
       .subst(/    <:Z>  /,      '',:g);  # remove spacing
}


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
  $record ~~ / 'Prefix: '(\S+)/;
  my $prefix = $0 ?? $0.Str !! '';
  $record ~~ / 'Macrolanguage: '(\S+)/;
  my $macro = $0 ?? $0.Str !! '';
  my $deprecated = ?($record ~~ / 'Deprecated'/);


  my @codes;
  if $code ~~ /(\S+)'..'(\S+)/ {
    @codes = $0.Str .. $1.Str;
  } else {
    @codes = $code;
  }


  for @codes -> $code {
    given $type {
      when 'language' {
        $languages-file.say: "$code,$script,$macro,$preferred" ~ ( '!' if $deprecated);
        unless $deprecated {
            for @descriptions -> $description is rw {
                $description = %enum-override{$description.subst(/\s/,'',:g)} // $description;
                my $description-enum = $description
                        .subst(/(<< <:Ll>)/, {$0.uc},:g)   # capitalize initial words
                        .subst(/    <:P>  /,      '',:g)   # remove punctuation
                        .subst(/    <:Z>  /,      '',:g);
                # remove whitespace
                $languages-enum-file.say: "$description-enum,$code" unless $description-enum eq 'PrivateUse';
                #say "$code = LanguageTag::$description-enum";
            }
        }
      }
      when 'extlang' {
        $extlangs-file.say: "$code,$prefix,$script,$preferred" ~ ('!' if $deprecated);
      }
      when 'script' {
        $scripts-file.say: "$code"; # no deprecated ones, even though CLDR lists as such
        unless $deprecated {
           for @descriptions {
             my $description-enum = format-description $_;
             $scripts-enum-file.say("$description-enum,$code") unless $description-enum eq 'PrivateUse'
           }
        }
      }
      when 'region' {
        $regions-file.say: "$code,$preferred" ~ ('!' if $deprecated);
        unless $deprecated {
            for @descriptions {
                my $description-enum = format-description $_;
                $regions-enum-file.say("$description-enum,$code") unless $description-enum eq 'PrivateUse'
            }
        }
      }
      when 'variant' {
        # TODO it is possible for there to be multiple prefixes !
        $variants-file.say: "$code,$prefix,$preferred" ~ ( '!' if $deprecated);
        #unless $deprecated {
        #    $variants-enum-file.say: "{format-description $_},$code" for @descriptions
        #}
      }
      when 'redundant' {
        $redundancies-file.say: "$tag,$preferred" ~ ( '!' if $deprecated)
      }
      when 'grandfathered' {
        $grandfathered-file.say: "$tag,$preferred" ~ ( '!' if $deprecated);
      }
      default  {
        # The only record not processed should contain the date.
        $record ~~ /(\d+\-\d+\-\d+) /;
        print "Processing language subtag registry dated ", $0.Str, "...";
      }
    }
  }
}
say " OK.";

close $languages-file;
close $extlangs-file;
close $scripts-file;
close $regions-file;
close $variants-file;
close $redundancies-file;
close $grandfathered-file;
