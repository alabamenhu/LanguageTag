unit class BCP47-Filter-Actions;
use Intl::BCP47::Classes;

method TOP ($/) {
  make $<langtag>.made;
}

method langtag ($/) {
  my $language    = $<language>.made;
  my $script      = $<script>.made;
  my $region      = $<region>.made;
  my @variants    = $<variant>.map(*.made);
  make (
    :$language,
    :$script,
    :$region,
    :@variants,
  );
}

method language ($/)  {
  given $/ {
    when '*' { make WildcardLanguage.new        }
    default  { make Language.new(:code($/.Str)) }
  }
}
method script ($/)  {
  given $/ {
    when '*' { make WildcardScript.new        }
    when ''  { make WildcardScript.new        }
    default  { make Script.new(:code($/.Str)) }
  }
}
method region ($/)  {
  given $/ {
    when '*' { make WildcardRegion.new        }
    when ''  { make WildcardRegion.new        }
    default  { make Region.new(:code($/.Str)) }
  }
}
method variant ($/)  {
  given $/ {
    when '*' { make WildcardVariant.new        }
    default  { make Variant.new(:code($/.Str)) }
  }
}

method privateusetag ($/)  {
  die 'Private use subtags are not usable in filters.'
}
method extension     ($/)  {
  die "Extension subtags are not usable in filters."
}
