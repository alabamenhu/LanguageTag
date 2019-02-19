unit class BCP47-Actions;
use Intl::BCP47::Classes;

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
  );
}

method language      ($/)  { make   Language.new(:code($/.Str)) }
method script        ($/)  { make     Script.new(:code($/.Str)) }
method region        ($/)  { make     Region.new(:code($/.Str)) }
method variant       ($/)  { make    Variant.new(:code($/.Str)) }
method privateusetag ($/)  { make PrivateUse.new(:code($/.Str)) }
method privateuse    ($/)  { make $<privateusetag>.map(*.made)  }
method extension     ($/)  {
  make Extension.new(
    :singleton( $<singleton>.Str),
    :subtags(   $0.map(*.Str))
  )
}
