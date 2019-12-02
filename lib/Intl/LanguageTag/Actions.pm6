#`««unit class BCP47-Actions;

method TOP ($/) {
  make $<langtag>.made;
}

method langtag ($/) {
  my $language    = $<language>.made;
  my $script      = $<script>.made;
  my $region      = $<region>.made;
  my @variants    = $<variant>.map(*.made);
  my @extensions  = $<extension>.map(*.made);
  my @privateuses = $<privateuse>.made;
  make (
    :$language,
    :$script,
    :$region,
    :@variants,
    :@extensions,
    :@privateuses
  )
}

method language      ($/)  { use Intl::BCP47::Classes :language; make   Language.new(:code($/.Str)) }
method script        ($/)  { use Intl::BCP47::Classes :script;   make     Script.new(:code($/.Str)) }
method region        ($/)  { use Intl::BCP47::Classes :region;   make     Region.new(:code($/.Str)) }
method variant       ($/)  { use Intl::BCP47::Classes :variant;  make    Variant.new(:code($/.Str)) }
method privateusetag ($/)  { use Intl::BCP47::Classes :private;  make PrivateUse.new(:code($/.Str)) }
method privateuse    ($/)  { make $<privateusetag>.map(*.made)  }
method extension     ($/)  {
  make Any.new(
    :singleton( $<singleton>.Str),
    :subtags(   $0.map(*.Str))
  )
}
»»