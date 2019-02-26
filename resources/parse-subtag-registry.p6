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
#  No this file isn't efficient Perl code.  It probably won't ever be.

my $registry = slurp "language-subtag-registry";
my @records = $registry.split(/\%\%\n/);
my $languages-file     = open "languages.bcp47data",    :w;
my $extlangs-file      = open "extlangs.bcp47data",     :w;
my $scripts-file       = open "scripts.bcp47data",      :w;
my $regions-file       = open "regions.bcp47data",      :w;
my $variants-file      = open "variants.bcp47data",     :w;
my $redundancies-file  = open "redundancies.bcp47data", :w;
my $grandfathered-file = open "grandfathered.bcp47data", :w;



for @records -> $record {
  $record ~~ / 'Type: ' (\S+)/;
  my $type = $0 ?? $0.Str !! '';
  $record ~~ / 'Subtag: ' (\S+)/;  # Currently allows a range syntax
  my $code = $0 ?? $0.Str !! '';   # which this script doesn't handle

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
      }
      when 'extlang' {
        $extlangs-file.say: "$code,$prefix,$script,$preferred" ~ ('!' if $deprecated);
      }
      when 'script' {
        $scripts-file.say: "$code"; # no deprecated ones, even though CLDR lists as such
      }
      when 'region' {
        $regions-file.say: "$code,$preferred" ~ ('!' if $deprecated);
      }
      when 'variant' {
        # TODO it is possible for there to be multiple prefixes !
        $variants-file.say: "$code,$prefix,$preferred" ~ ( '!' if $deprecated);
      }
      when 'redundant' {
        $redundancies-file.say: "$code,$preferred" ~ ( '!' if $deprecated)
      }
      when 'grandfathered' {
        $grandfathered-file.say: "$code,$preferred" ~ ( '!' if $deprecated);
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
