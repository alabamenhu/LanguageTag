#
#    #### ######  ###   ####   ##
#   ##      ##   ## ##  ## ##  ##
#   #####   ##   ## ##  ####   ##   Read the notices below before
#      ##   ##   ## ##  ##          making any changes.
#   ####    ##    ###   ##     ##
#
# WARNING: If changing this file (in particular what is output), you
#          MUST adjust the file in Extension-Registry.pm6 to match.
#
#  The files used by this are those contained in the CLDR common/bcp47
#  directory, with the validity directory thrown in for good measure.
#  In the future I will rework this to take a freshly unpacked CLDR
#  and maybe download the data automatically.
#
#  Yes this file is ugly.  Sorry.

use XML;

sub elems-for-tag($xml, $name) {
  my $node = $xml.lookfor(:$name).first;
  set (.<name>.Str for $node.lookfor(:TAG('type')));
}

# The abbreviations in CLDR are in the format of
#   alnum tilde alnum
# Such that "za~c" = "za", "ab", "zc"
sub expand-abbreviations($text) {
  my @elems = $text.split(/\s+/,:skip-empty);
  gather for @elems -> $elem {
    if $elem ~~ /'~'/ {
      take $_ for $elem.chop(2) .. ($elem.chop(3) ~ $elem.substr(*-1));
    } else {
      take $elem;
    }
  }
}


my %data = ();

my $calendar = open-xml('cldr/calendar.xml');
%data<hc> = elems-for-tag($calendar, 'hc');
%data<fw> = elems-for-tag($calendar, 'fw');
%data<ca> = elems-for-tag($calendar, 'ca');

my $collation = open-xml('cldr/collation.xml');
%data<co> = elems-for-tag($collation, 'co');
%data<ka> = elems-for-tag($collation, 'ka');
%data<kb> = elems-for-tag($collation, 'kb');
%data<kc> = elems-for-tag($collation, 'kc');
%data<kf> = elems-for-tag($collation, 'kf');
%data<kh> = elems-for-tag($collation, 'kh');
%data<kk> = elems-for-tag($collation, 'kk');
%data<kn> = elems-for-tag($collation, 'kn');
%data<kr> = elems-for-tag($collation, 'kr');   # ⬅ extra work needed
%data<ks> = elems-for-tag($collation, 'ks');
#%data<ks> = elems-for-tag($collation, 'kt');  # ⬅ extra work needed
%data<kv> = elems-for-tag($collation, 'kv');

my $currency = open-xml('cldr/currency.xml');
%data<cf> = elems-for-tag($currency, 'cf');
%data<cu> = elems-for-tag($currency, 'cu');

my $variant = open-xml('cldr/variant.xml');
%data<em> = elems-for-tag($variant, 'em');
%data<va> = elems-for-tag($variant, 'va');
# RG values are defined as
#     A region code from idValidity/id[type='region'][idStatus='regular'],
#     suffixed with 'ZZZZ'"
my $regions = open-xml('cldr/validity/region.xml')
              .lookfor(:idStatus('regular'))
              .first
              .contents
              .map(*.text)
              .join('');
%data<rg> = set expand-abbreviations($regions);
# SD values are defined as
#     Valid unicode_subdivision_subtag for the region subtag as specified
#     in LDML, based on subdivisionContainment data in supplementalData,
#     prefixed by the associated unicode_region_subtag
my $subdivisions = open-xml('cldr/validity/subdivision.xml')
              .lookfor(:idStatus('regular'))
              .first
              .contents
              .map(*.text)
              .join('');
%data<sd> = set expand-abbreviations($subdivisions);

my $segmentation = open-xml('cldr/segmentation.xml');
%data<lb> = elems-for-tag($segmentation, 'lb');
%data<lw> = elems-for-tag($segmentation, 'lw');
%data<ss> = elems-for-tag($segmentation, 'ss');

my $measure = open-xml('cldr/measure.xml');
%data<ms> = elems-for-tag($measure, 'ms');

my $number = open-xml('cldr/number.xml');
%data<nu> = elems-for-tag($number, 'nu');

my $timezone = open-xml('cldr/timezone.xml');
%data<tz> = elems-for-tag($timezone, 'tz');

my $file = open "extension-u.data", :w;
$file.say(.key ~ ':' ~ .value.keys.join(',')) for %data;
close $file;


################################################################
# CLEAR THE DATA, REPEAT WITH FILES NEEDED FOR THE T EXTENSION #
################################################################

%data = ();
my $transform = open-xml('cldr/transform.xml');
%data<m0> = elems-for-tag($transform, 'm0'); # strict

my $destination = open-xml('cldr/transform-destination.xml');
%data<d0> = elems-for-tag($destination, 'd0'); # strict
%data<s0> = elems-for-tag($destination, 's0'); # strict

my $mt = open-xml('cldr/transform_mt.xml');
%data<t0> = elems-for-tag($mt, 't0'); # und or anything?

my $keyboard = open-xml('cldr/transform_keyboard.xml');
%data<k0> = elems-for-tag($keyboard, 'k0'); # anything, vendor first preferred

my $hybrid = open-xml('cldr/transform_hybrid.xml');
%data<h0> = elems-for-tag($hybrid, 'h0'); # 'hybrid' + language stuff

my $input = open-xml('cldr/transform_ime.xml');
%data<i0> = elems-for-tag($input, 'i0'); # anything, vendor first preferred



$file = open "extension-t.data", :w;
$file.say(.key ~ ':' ~ .value.keys.join(',')) for %data;
close $file;
