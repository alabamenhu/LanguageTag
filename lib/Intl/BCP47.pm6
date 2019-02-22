unit module Intl::BCP47:ver<0.6.0>:auth<Matthew Stephen Stuckwisch (mateu@softastur.org)>;

use Intl::BCP47::Grammar;
use Intl::BCP47::Actions;
use Intl::BCP47::Classes;
use Intl::BCP47::Filter-Grammar;
use Intl::BCP47::Filter-Actions;
class LanguageTagFilter { … }
class LanguageTag is export {
  has Language   $.language;
  has Script     $.script;
  has Region     $.region;
  has Variant    @.variants;
  has Extension  @.extensions;
  has PrivateUse @.privateuses;
  method new(Str $string, :$strict, :$autopreferred) {
    my %base = BCP47-Grammar.parse($string, :actions(BCP47-Actions)).made;
    my @privateuses = %base<privateuses><>;
    @privateuses = () if @privateuses[0].WHAT ~~ Any; # not sure why this is happening
    self.bless(
      :language(%base<language>),
      :script(%base<script>  // Script.new(:code(''))),
      :region(%base<region>  // Region.new(:code(''))),
      :variants(%base<variants><>),
      :extensions(%base<extensions><>),
      :@privateuses,
    )
  }
  # to be international, maybe use these ⚐✎⇢☺︎☻

  multi method gist (::?CLASS:U:) { '(LanguageTag)' }
  multi method gist (::?CLASS:D:) {
    '['
    ~ $.language.code
    ~ ('-' ~ $.script.code unless $.script.type eq 'undefined')
    ~ ('-' ~ $.region.code unless $.region.type eq 'undefined')
    ~ ('…' if ?@.extensions || ?@.variants || ?@.privateuses)
    ~ ']'
  }

  # The string method does not make any changes to the underlying codes.
  # It will not canonicalize or anything of the sort.  This is appropriate in
  # some cases.
  method Str {
    $.language.code
    ~ ('-' ~ $.script.code unless $.script.type eq 'undefined')
    ~ ('-' ~ $.region.code unless $.region.type eq 'undefined')
    ~ @.variants.map('-' ~ *.code.lc).join
    ~ @.extensions.map({'-' ~ $_.singleton ~ '-' ~ $_.subtags.join('-')}).join
    ~ ('-x' if @.privateuses)
    ~ @.privateuses.map('-' ~ *.code).join; # don't sort privateuses
  }
  method canonical (Any:D:) {
    # Warning: extensions do not currently handle canonical forms (they are
    # more complex, but will eventually be supported in the .canonical method
    # once the two defined types are subclassed (singletons -u and -t).
    # For now, extensions are alphabetized by singleton, with all subtags passed
    # through as is.
    $.language.canonical
    ~ ('-' ~ $.script.canonical unless $.script.type eq 'undefined')
    ~ ('-' ~ $.region.canonical unless $.region.type eq 'undefined')
    ~ @.variants.map('-' ~ *.code.lc).sort.join
    ~ @.extensions.sort(*.singleton).map({'-' ~ $_.singleton ~ '-' ~ $_.subtags.join('-')}).join
    ~ ('-x' if @.privateuses)
    ~ @.privateuses.map('-' ~ *.code).join; # don't sort privateuses
    # test with EN-ShAw-cA-newFoUnD-u-ca-gregory-t-he-Arab-ES-1800-x-foo
  }
  method LanguageTagFilter (:$extendable = False) {
    LanguageTagFilter.new(
      :$.language,
      :$.script,
      :$.region,
      :@.variants,
      #:@.extensions,
      #:@.privateuses,
    )
  }
}


class LanguageTagFilter is export {
  has Language   @.languages;  #    RFC4647 does not provide for filtering based
  has Region     @.regions;    #    on extensions.  The behavior is undefined
  has Variant    @.variants;   #    We accept these because it is possible in
  has Script     @.scripts;    #    the future to provide a programmatic
  has Extension  @.extensions; # ⬅︎ interface for defining both matching and
  has PrivateUse @.privateuse; # ⬅︎ wild cards, but a string construction (
                               #    via a Grammar or otherwise) is not possible.
  proto method new (|) {*}
  multi method new (Str $string) {
    my %base = BCP47-Filter-Grammar.parse($string, :actions(BCP47-Filter-Actions)).made;
    LanguageTagFilter.new(
      :language(%base<language>),
      :script(%base<script>  // WildcardScript.new),
      :region(%base<region>  // WildcardRegion.new),
      :variants(%base<variants><>),
    )
  }

  multi method new (
    Language   :$language is copy, :@languages is copy where { @languages.defined || @languages.all ~~ Language},
    Region     :$region   is copy, :@regions   is copy where { @regions.defined   || @regions.all   ~~ Region  },
    Script     :$script   is copy, :@scripts   is copy where { @scripts.defined   || @scripts.all   ~~ Script  },
    Variant    :$variant  is copy, :@variants  is copy where { @variants.defined  || @variants.all  ~~ Variant },
    # Privateuse and extensions are not used in filtering.
  ) {
    push @languages,  $language  if $language.defined;
    push @regions,    $region    if $region.defined   && $region.type  ne "undefined";
    push @scripts,    $script    if $script.defined   && $script.type  ne "undefined";
    push @variants,   $variant   if $variant.defined  && $variant.type ne "undefined";

    # If any field is empty per RFC4647, it is considered a wildcard. Similarly
    # at least for languages/scripts/regions, any wildcard passed will
    # automatically count as a single wildcard, because no tag can have more
    # than one.
    @scripts   =   (WildcardScript.new,) if @scripts   == 0 ||   @scripts.map(*.type).any eq ('undefined'|'wildcard');
    @languages = (WildcardLanguage.new,) if @languages == 0 || @languages.map(*.type).any eq ('undefined'|'wildcard');
    @regions   =   (WildcardRegion.new,) if @regions   == 0 ||   @regions.map(*.type).any eq ('undefined'|'wildcard');
    # If a variant is empty, we will consider it to be a wildcard.
    for @variants <-> $variant {
      $variant = WildcardVariant.new if $variant.type eq ( 'undefined' | 'wildcard' )
    }
    self.bless(
      :@languages,
      :@regions,
      :@scripts,
      :@variants,
    )
  }
  multi method ACCEPTS(LanguageTagFilter:D : LanguageTag $tag) {
    # Easy checks first.  An empty array means a the filter was set with an empty
    # value, and per RFC4647 @ 3.3.2 is equivalent to being a wildcard, although
    # the new() method tries to catch anything that would result in a wildcard
    # here.  That said, these are left here in case someone wishes to
    # modify the LanguageTagFilter after construction.
    return False unless
      @.languages ~~ ()               # implied  wildcard
      || @.languages.any ~~ Wildcard  # explicit wildcard
      || $tag.language.canonical eqv @.languages.map(*.canonical).any;
    # If the script is provided in the filter, but not in the tag, according to
    # RFC4647 we should not match.  This seems a bit odd to me, especially if the
    # the tag’s language’s Suppress-Script property matches any of the filter’s
    # script.  An adverb in the future may allow for non-standard (but fully
    # logical) matching by implementing the default script
    return False unless
      @.scripts ~~ ()               # implied  wildcard
      || @.scripts.any ~~ Wildcard  # explicit wildcard
      || $tag.script.canonical eqv @.scripts.map(*.canonical).any;
    return False unless
      @.regions ~~ ()               # implied  wildcard
      || @.regions.any ~~ Wildcard  # explicit wildcard
      || $tag.region.canonical eqv @.regions.map(*.canonical).any;
    return False unless
      @.variants ~~ ()              # implied  wildcard
      || @.variants.any ~~ Wildcard # explicit wildcard
      || $tag.variants >= @.variants;  # impossible to match if the
                                       # filter has more variants.

    # RFC4647 does not provide for checking the variants in any order than the
    # ones presented in each tag, and so we do not either.  Perhaps a "canonize"
    # routerrineth could be made later. Each variant is checked between the tag and the
    # filter until there is either a filter wildcard variant (proceed) or the
    # tag's last variant is reached.  At that point, we should, per the RFC,
    # be returning True.  The filter does NOT provide for extensions or
    # privateuses and explicitly states in § 3.3.2.3.D, “if the language tag's
    # subtag is a "singleton" (a single letter or digit, which includes the
    # private-use subtag 'x') the match fails.”
    for ^@.variants -> $index {
      return False unless
        @.variants[$index].code    eq '*'
        || @.variants[$index].code.lc eq $tag.variants[$index].code.lc
    }
    # We MAY want to later add an option for extended checking.  However, a
    # wildcard tag would be highly ambiguous in a string-based format, although
    # there would be no issue setting it up programmatically.  For the time being,
    # however, we simply return True, as that is the RFC4647 standard.
    True
  }
}


# implements RFC 4647
multi sub filter-language-tags(@available where { @available.all ~~ LanguageTag}, $wants, :$basic = False) is export {
  filter-language-tags(@available, ($wants,), :$basic);
}

# Note that in general, the SOURCE language is expected to have a larger/longer
# language tag than the filter.  If the filter is longer, it can never match.
# Additionally, there could be much better logic here.  If only a filter object
# is passed, we should ignore :basic.  Likewise, if LanguageTagFilters are
# passed in with :basic set, they should be reduced as best as possible in
# to conform to the expected string tag.
multi sub filter-language-tags(
                @source where { @source.all ~~ LanguageTag},
                @filter where { @filter.all.map( { $_ ~~ Str || $_ ~~ LanguageTagFilter}) },
    Bool       :$basic = False,
    # The options below are not yet implemented, but are planned
    Bool       :$suppressed,   # Insert suppressed
    Bool       :$canonical,    # Use canonical forms only.  May fail if any
                               # codes cannot be canonicalized.
    Bool       :$nonpreferred  # Reject preferred forms for deprecated tags when
                               # canonicalizing language tags.
  ) is export {

  return filter-language-tags-basic(@source, @filter, :$canonical, :$nonpreferred, :$suppressed) if $basic;

  my @extended-filters = do for @filter { $_ ~~ Str ?? LanguageTagFilter.new: $_ !! $_};
  filter-language-tags-extended(@source, @filter, :$canonical, :$nonpreferred);
}

# Basic filtering, according to RFC4647 § 3.3.1
sub filter-language-tags-basic(
    LanguageTag @source,
    Str @filter,
    :$canonical = False,    # to be implemented
    :$nonpreferred = False, # to be implemented
    :$suppressed = False    # to be implemented
    --> Seq
) {
  my $filter = @filter.any;
  do gather {
    for @source -> $source-tag {
      take $source-tag if (
        || $source-tag.Str.lc eq $filter.lc                 # exact match
        || $source-tag.Str.lc.starts-with($filter.lc ~ '-') # prefix match, ending on a tag
        || $filter eq '*'                                   # wildcard matches all
      )
    }
  }
}

sub filter-language-tags-extended(
    @source where {@source.all ~~ LanguageTag},
    @filter where {@filter.all ~~ LanguageTagFilter},
    :$canonical = False,    # to be implemented
    :$nonpreferred = False, # to be implemented
    :$suppressed = False    # to be implemented
    --> Seq
) {
  do gather {
    for @source -> $source-tag {
      take $source-tag if (
        $source-tag ~~ @filter.any
      )
    }
  }
}
