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
    ~ ('-' ~ $.script.code unless $.script.type eq 'blank')
    ~ ('-' ~ $.region.code unless $.region.type eq 'blank')
    ~ ('…' if ?@.extensions || ?@.variants || ?@.privateuses)
    ~ ']'
  }

  # The string method does not make any changes to the underlying codes.
  # It will not canonicalize or anything of the sort.  This is the expected
  # behavior for most uses.
  method Str {
    $.language.code
    ~ ('-' ~ $.script.code unless $.script.type eq 'blank')
    ~ ('-' ~ $.region.code unless $.region.type eq 'blank')
    ~ @.variants.map('-' ~ *.code.lc).join
    ~ @.extensions.map({'-' ~ $_.singleton ~ '-' ~ $_.subtags.join('-')}).join
    ~ ('-x' if @.privateuses)
    ~ @.privateuses.map('-' ~ *.code).join; # don't sort privateuses
  }
  method canonical (Any:D:) {
    # Warning: the T extension does not currently handle canonical forms (it is
    # more complex, but will eventually be supported in the .canonical method
    # once it is fully subclassed).
    # For now, extensions are alphabetized by singleton, with all subtags passed
    # through as is.
    $.language.canonical
    ~ ('-' ~ $.script.canonical unless $.script.type eq 'blank')
    ~ ('-' ~ $.region.canonical unless $.region.type eq 'blank')
    ~ @.variants.map('-' ~ *.canonical).sort.join
    ~ @.extensions.sort(*.singleton).map({'-' ~ $_.singleton ~ '-' ~ $_.subtags.join('-')}).join
    ~ ('-x' if @.privateuses)
    ~ @.privateuses.map('-' ~ *.code).join; # don't sort privateuses
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

class GrandfatheredLanguageTag is LanguageTag {
  # These are strictly interpreted BCP47 § 2.2.8, that means that they are
  # contemplated as a language code unto themselves with the exception of one:
  # en-GB-oed, seen as en-GB.  Then again, no one should be actively using these
  # codes either, so ideally this code will never be run in production.

  use Intl::BCP47::Subtag-Registry :old-languages;
  # This module gives access to %grandfathered-languages and %redundant-languages.
  # These two consist of two simple items, .[0], a preferred language tag (as a
  # string), and .[1], a boolean flag for being deprecated.

  has Language $.language;
  has Language $.original;           # ⬅︎ Only used because of how I think
  has LanguageTag $.preferred;       #    en-GB-oed needs to be handled.
  has Region $.region;
  has Variant @.variants = ();       # ⬅︎ These tags are kept only so that the
  has Extension @.extensions = ();   #    the language tags can be passed to
  has PrivateUse @.privateuses = (); #    anything that takes a LanguageTag and
                                     #    not cause error.

  # Per BCP47 § 2.2.8, each code in its entirety constitutes a language.
  # However, one exception is made for en-GB-oed, so in that case, it appears
  # that for access to .region and .language we ought to provide GB for the
  # region and en for the language. (If incorrect, modify, but the docs aren't
  # particular clear on that)

  method new (Str $text) {
    die unless %grandfathered-languages{$_}:exists;
    my $preferred = %grandfathered-languages{$_}.head eq ''
                      ?? Nil
                      !! LanguageTag.new(%grandfathered-languages{$_}.head);
    my $deprecated = %grandfathered-languages{$_}.tail;
    my $language = $text eq 'en-GB-oed'
                     ?? Language.new(:code('en'))
                     !! IrregularLanguage(:code($text));
    my $original = $text;
    my $region   = Region.new(:code($text eq 'en-GB-oed' ?? 'GB' !! ''));
    self.bless(:$preferred,:$deprecated,:$language, :$original, :$region,)
  }
  method type {
    given $.original {
      when %grandfathered-languages{$_}.tail { return 'deprecated' }
      default                                { return 'regular'    }
    }
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
      :script(  %base<script> // WildcardScript.new),
      :region(  %base<region> // WildcardRegion.new),
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
    push @regions,    $region    if $region.defined   && $region.type  ne "blank";
    push @scripts,    $script    if $script.defined   && $script.type  ne "blank";
    push @variants,   $variant   if $variant.defined  && $variant.type ne "blank";

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
    # routine could be made later. Each variant is checked between the tag and the
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


# Implements RFC4647 § 3.4 Lookup
# Singular returns top match, plural returns an ordered list
sub lookup-language-tag(@available-tags, @preferred-tags, $default = LanguageTag.new('en') --> LanguageTag) is export {
  lookup-language-tags(@available-tags, @preferred-tags, $default) :single;
}
sub lookup-language-tags(@available-tags, @preferences-tags, $default = LanguageTag.new('en'), :$single = False) is export {
  # The general assumption is that the PREFERENCES are longer than what is
  # AVAILABLE.  Anything that is available but is more specific than the
  # preferences will fail never match.
  #
  # WARNING: this is a first attempt, I do not guarantee how well it works, but
  #          it seems accurate enough.  It does NOT handle wildcards yet, sorry.
  #
  # RFC4647 specifically indicates that subtags are to be progressively shed
  # until a match is found, and the "best match" is the longest possible match.
  # The exact process for comparing a best match between two or more stated
  # preferences is not provided.  Imagine the following:
  #    AVAILABLE      PREFERRED
  #    ar             en-UK
  #    en             en-US
  #    en-US          en
  #    es             es-ES
  # In practice, this combination might not happen but it must be contemplated.
  # A naïve approach is to test if en-UK exists (it doesn't), then strip it of
  # the UK and then match "en".  But the user has explicitly also preferred
  # en-US over bare en, so we cannot test "en" until we have tried en-US.
  # The approach used instead (and, incidentally, faster) is to check for which
  # preferred values does each available begin, and store the longest at each pass.
  # 1. Check that @preferred starts with "ar".
  #     -> (en-UK => "", en-US => "", en => "", es-ES => "")
  # 2. Check that @preferred starts with "en".
  #     -> (en-UK => en, en-US => en, en => en, es-ES => ())
  # 3. Check that @preferred starts with "en-US"
  #     -> (en-UK => en, en-US => en-US, en => en, es-ES => "")
  #                               ^^^^^ longer match than just en
  # 4. Check that @preferred starts with "es"
  #     -> (en-UK => en, en-US => en-US, en => en, es-ES => es)
  # TODO: finish documenting the algorithm
  #
  # NOTE: this does not currently handle wildcards, which will make the logic
  # substantially more complicated, reduce speed/efficiency, and probably not
  # be used.  When such a routine is coded, it may be a good idea to detect
  # a wildcard presence and use an alternate algorithm.

  # Initially stringify and add a hyphen to avoid potentially overlapping tags
  # of different lengths (otherwise "es" [Spanish] might match "est" [Estonian],
  # and the same can happen with extension/variant tags)
  my @available = @available-tags.map(*.Str ~ '-');
  my @preferences = @preferences-tags.map(*.Str ~ '-');
  #say "Available languages are ", @available;
  #say "User would prefer ", @preferences;
  my %matches;
  %matches{@preferences} = '' xx ∞;
  for @available -> $tag is rw {
    %matches.map({
      .value = $tag if .key.starts-with($tag) && $tag.chars > .value.chars;
    });
  }
  #say "Initial matches are ", %matches;

  # We call this naïve because it does not contemplate partial matches, and
  # needs to be paired down still.
  my @naïve-order = lazy gather {
    for @preferences {
      take %matches{$_} unless %matches{$_} eq '';
    }
  }
  #say "Naïve order is ", @naïve-order[0..10];
  my @smart-order;

  # if there is nothing in naïve-order, then there were no matches at all
  if @naïve-order {
    @smart-order = lazy gather {
      for @naïve-order -> $naïve {
        # We need to sort into the longest -> shortest tags (because longest
        # matches are best).
        my @long-matches = %matches.values.grep(*.starts-with: $naïve).unique.sort(*.comb('-').chars).reverse;
        my @small-add = (); # these have the lowest priority
        for @long-matches -> $tag is rw {
          take LanguageTag.new($tag.substr(0,*-1)); # immediately take a long tag when we get there
          while $tag = $tag.substr(0,$tag.rindex("-", $tag.chars - 2) // 0) { # remove a tag
            # Now that we have an ever shortening tag, there are three possibilities.
            #   1. The tag is already in the long list (ignore to avoid jumping the gun)
            #   2. The tag does not prefix anything (take immediately)
            #   3. The tag prefixes something (add to the short list to take later)
            next if $tag (elem) @long-matches; # (1)
            if @long-matches.any.starts-with($tag) || @small-add.any.starts-with($tag) {
              push @small-add, $tag; # (3)
            }else{
              take LanguageTag.new($tag.substr(0,*-1)); # (2)
            }
          }
        }
        take LanguageTag.new($_.substr(0,*-1)) for @small-add;
      }
    }
  }else{
    @smart-order = $default;
  }
  #say "Smart order is ", @smart-order.unique( as => Str, with => &[eq])[0..10];

  $single ?? @smart-order.head !! @smart-order.unique( as => Str, with => &[eq]);
}
