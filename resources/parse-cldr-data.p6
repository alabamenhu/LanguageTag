use XML;

sub elems-for-tag($xml, $name) {
  my $node = $xml.lookfor(:$name).first;
  set (.<name>.Str for $node.lookfor(:TAG('type')));
}

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
%data<kr> = elems-for-tag($collation, 'kr'); # extra work needed
%data<ks> = elems-for-tag($collation, 'ks');
#my $kt = elems-for-tag($collation, 'kt'); # extra work needed
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

my $file = open "extension-u.bcp47data", :w;
$file.say(.key ~ ':' ~ .value.keys.join(',')) for %data;
close $file;


################################################################
# CLEAR THE DATA, REPEAT WITH FILES NEEDED FOR THE T EXTENSION #
################################################################

%data = ();
