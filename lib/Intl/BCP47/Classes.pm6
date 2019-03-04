class Language is export {
  # Import %languages and %deprecated-languages whose keys
  # are language codes and values are defined thus:
  # [0] = suppressed script, [1] = macro language, [2] = preferred code
  use Intl::BCP47::Subtag-Registry :languages;

  has $.code is rw;

  multi method gist (::?CLASS:D:) { '[Language:' ~ $.code ~ ']' }
  multi method gist (::?CLASS:U:) { '[Language]'                }

  # The canonical form for languages is to be lower-cased
  method canonical { $.code.lc }

  # There are three types defined in most data, regular, deprecated, but also
  # some data sets separate out mis, mul, zxx which have special meanings
  # (for unidentified, multiple, etc).  No reason, I don't think, to
  # be so discriminating.
  method type {
    given $.code {
      when %languages{$_}:exists            { return 'regular'      }
      when %deprecated-languages{$_}:exists { return 'deprecated'   }
      when ''                               { return 'blank'        }
      default                               { return 'unregistered' }
    }
  }
}

class IrregularLanguage is Language is export {
  has $.code is rw;
  multi method gist (::?CLASS:D:) { '[Irr.Lang.:' ~ $.code ~ ']' }
  multi method gist (::?CLASS:U:) { '[Irr.Lang.]'                }
  # The canonical form for languages is to be lower-cased
  # Note that this method SHOULD cause failure for most codes, because most of
  # them have been fully deprecated.  That handling should be taken care of in
  # the other GrandfatheredLanguageTag code, though.
  method canonical { $.code.lc }
  # Technically, they should be "irregular", but they are technically valid.
  method type { 'regular' }
}

class Region is export {
  # Import %languages and %deprecated-languages whose keys
  # are language codes and values are defined thus:
  # [0] = suppressed script, [1] = macro language, [2] = preferred code
  use Intl::BCP47::Subtag-Registry :regions;
  has $.code is rw;
  multi method gist (::?CLASS:D:) { '[Region:' ~ $.code ~ ']' }
  multi method gist (::?CLASS:U:) { '[Region]'                }

  # The canonical form for a region code is all caps (except numbers, which
  # are in standard form.
  method canonical { $.code.uc }

  # There are some special region types but they do not require any special work
  # to be handled.  Perhaps if a use for them appears it may be germane to
  # discriminate them.
  method type {
    given $.code {
      when %regions{$_}:exists            { return 'regular'      }
      when %deprecated-regions{$_}:exists { return 'deprecated'   }
      when ''                             { return 'blank'        }
      default                             { return 'unregistered' }
    }
  }

}

class Script {
  # There are a few other script codes other than the ones that are included in
  # IANA's database.  They can be used so long as :strict isn't enabled.
  use Intl::BCP47::Subtag-Registry :scripts;

  has Str $.code is rw;

  multi method gist (::?CLASS:D:) { '[Script:' ~ $.code ~ ']' }
  multi method gist (::?CLASS:U:) { '[Script]'                }
  # The canonical form of scripts is an initial cap and three lowercase
  method canonical { $.code.tclc }
  # There are a few special script types, name the provite use Qa* and the ones
  # with special meaning Zmth, Zsye, Zsym, Zxxx and Zzzz.  At the moment, no
  # need to distinguish them as they are all valid.  Interestingly, although
  # in many places Qaai is listed as deprecated, in the formal IANA registry, it
  # is *not* so designated.
  method type {
    given $.code {
      when %scripts{$_}:exists            { return 'regular'      }
      when ''                             { return 'blank'        }
      default                             { return 'unregistered' }
    }
  }
}


class Variant is export {
  # Grants use of %variants and %deprecated-variants.  Keys are the variant
  # subtag code, and the values are two value array with [0] a prefix (which
  # canonically must precede the tag) and [1] a preferred code.
  use Intl::BCP47::Subtag-Registry :variants;

  has $.code is rw;

  multi method gist (::?CLASS:D:) { '[Variant:' ~ $.code ~ ']' }
  multi method gist (::?CLASS:U:) { '[Variant]'                }

  method canonical { $.code.lc }

  method type {
    given $.code {
      when %variants{$_}:exists            { return 'regular'      }
      when %deprecated-variants{$_}:exists { return 'deprecated'   }
      when ''                              { return 'blank'        }
      default                              { return 'unregistered' }
    }
  }
}

class Extension is export {
  has $.singleton is rw;
  has @.subtags is rw;
  multi method new(:$singleton, :@subtags) {
    # Uncomment out this code once the extensions are finished.
    given $singleton {
      # This elegant solution of ::('Class') for cyclic dependencies is thanks
      # to #perl6 user vrurg.  Placing it in CHECK means it might
      when 'u' { (CHECK ::('UnicodeLocaleExtension')).new: @subtags }
    #  when 't' { return TransfordContentExtension.new: @subtags }
      default  {
        self.bless(:$singleton, :@subtags);
      }
    }
  }
  multi method gist (::?CLASS:D:) { '[Extension:' ~ $.singleton ~ ':' ~ @.subtags.join(',') ~ ']' }
  multi method gist (::?CLASS:U:) { '[Extension]' }
  method type {
    'unregistered'
  }
}

class TransformedContentExtension is Extension is export {
  # This class implements the transformed content extension defined by RFC6497.
  # Between it and UTS35, there is not extension information available about
  # what should be considered valid (theoretically, the RFC says only valids
  # listed in the data files should be considered valid, but then some reference
  # vendors, etc, without including them).  For canonicity we hold strictly
  # to that definition and do not attempt to apply logic or reason to the
  # subtags.
  #
  # Dates can be used, but must be the final subtag and will be in the format of
  # YYYY, YYYYMM, or YYYYMMDD.
  use Intl::BCP47::Extension-Registry :t;
  has $.singleton = 't';
  has @.subtags       = ();  # fallback for all keys/types in order, to be extension agonistic
  has @.language-tags = ();  # could be kept as a LanguageTag as well
  has @.mechanisms    = ();  # array to maintain input order, canonical is alphabetical
  class Mechanism {
    has $.id;        # Alpha + num, always.
    has @.tags = (); # All tags allow for multiple; tags are order sensitive, so
                     # in the canonization process, they should not be sorted.
    multi method gist (::?CLASS:D:) { '[' ~ $.id ~ ':' ~ @.types.join(',') ~ ']' }
    multi method gist (::?CLASS:U:) { '[Mechanism]' }
  }
  proto new (|) {*}
  multi method new(Str $text) {
    samewith $text.substr((2 if $text.starts-with: 't-')).split('-', :skip-empty);
  }
  multi method new(@subtags) {
    # Defined as a bcp-like tag -- with some restrictions! TODO
    # that only includes a language, script, region, variant, but NOT subtags.
    my @language-tags.push(@subtags.shift)
        while (@subtags.head && @subtags.head !~~ /^<[a..zA..Z]><[0..9]>$/);

    my @mechanisms = ();
    for @subtags -> $tag {
      if $tag ~~ /^<[a..zA..Z]><[0..9]>$/ {
          push @mechanisms, Mechanism.new(:id($tag));
      }else{
        push @mechanisms.tail.types, $tag;
      }
    }
    self.bless(:@language-tags, :@subtags, :@mechanisms)
  }
  multi method gist (::?CLASS:D:) { '[Extension|T:' ~ @.subtags.join(',') ~ ']' }
  multi method gist (::?CLASS:U:) { '[Extension|T]' }
  method canonical {
    # cannonical should check that it is valid and canonical first!  This is
    # naïve and only makes sure things are lowercase
    '-t' ~ @.mechanisms.sort(*.id).map({'-' ~ .id ~ '-' ~ .types.join('-')}).lc
  }


  method check-valid {
    # First check that the language tag is valid, TODO : revisit when full
    # validator methods are implemented
    return False unless ::('LanguageTag').new(@.language-tags.join: '-');
    # Next cycle through each mechanism, verifying that all of its tags are
    # defined and there are no duplicated values.  There are two special cases:
    # (1) if the mechanism is x0, we only check for well formedness, and
    # (2) if the subtag is not found, but is the final element, it must match
    #        a calendar date format of YYYY[MM[DD]].
    # TODO: fully validate dates
    for @.mechanisms -> $mechanism {
      given $mechanism.id {
        when 'x0' {
          # Valid if and only if all subtags are between 3 and 8 alphanumerical
          # characters.  Theoretically, our grammar should enforce the alpha-
          # numerica nature.  Never hurts, I 'spose, to double check unless we
          # can prove it's always enforced elsewhere.
          return False unless $mechanism.tags.map(* ~~ /^<[a..zA..Z0..9]>**3..8$/).all;
        }
        default {
          # All elements must be found in the tag data base EXCEPT the final one
          # which should EITHER be in the database OR be a date.
          # The first step is to check all elements BUT the last one.
          return False unless $mechanism.types[0..^*-1] ∈ %t-data{$mechanism.id};
          # Then see check the dual status of the next one.  Either it's a valid
          # year, a valid year + month, or a
          return False unless
            # Valid registered subtag
            $mechanism.type.tail ∈ %t-data{$mechanism.id}
            # Year only
            || $mechanism.type.tail ~~ /^<[0..9]>**4$/
            # Year and month
            || $mechanism.type.tail ~~ /^<[0..9]>**4
                 [01||02||03||04||05||06||07||08||09||10||11||12]$/
            # Year month and day, and that day is valid for the month/year
            || ($mechanism.type.tail ~~ /^<[0..9]>**6$/
                &&
                  DateTime.new(
                    year  => $mechanism.type.tail.substr(0,4),
                    month => $mechanism.type.tail.substr(4,2),
                    day   => $mechanism.type.tail.substr(6,2),
                  )
                )
          ;
        }
      }
    }
    True;
  }

  ########## ASSOCIATIVE ROLE METHODS ##########
  multi method AT-KEY (::?CLASS:D: $mechanism) { return-rw @.mechanisms.grep(*.id eq $mechanism).head }
  multi method EXISTS-KEY (::?CLASS:D: $mechanism) {return-rw ?(@.mechanisms.grep(*.id eq $mechanism).elems) }
  multi method ASSIGN-KEY (::?CLASS:D: $mechanism, Str @vals) {push @.mechanisms, Mechanism.new(:id($mechanism), :tags(@vals))}
  multi method ASSIGN-KEY (::?CLASS:D: $mechanism, Mechanism $val where {$val.id eq $mechanism}) { push @.mechanisms, $val }
  multi method DELETE-KEY (::?CLASS:D: $mechanism) {
    my $return = @.mechanisms.grep(*.id eq $mechanism).head;
    @.mechanisms = @.mechanisms.grep(*.id ne $mechanism);
    $return;
  }
}

class UnicodeLocaleExtension is Extension does Associative is export {
  # This class requires foreknowledge of the overall language tag to verify
  # its validity and canonicity.  As such, for the region keys, we (at the
  # moment) only check for well-formedness.

  use Intl::BCP47::Extension-Registry :u;
  has $.singleton = 'u'; # fallback to be extension agnostic
  has @.subtags   = ();  # fallback for all keys/types in order, to be extension agonistic
  has @.keys      = ();  # array to maintain input order, canonical is alphabetical
  class Key {
    has $.id;
    has @.types = (); # not all keys allow for multiple types.
    multi method gist (::?CLASS:D:) { '[' ~ $.id ~ ':' ~ @.types.join(',') ~ ']' }
    multi method gist (::?CLASS:U:) { '[Key]' }
  }
  proto new (|) {*}
  multi method new(Str $text) {
    samewith $text.substr((2 if $text.starts-with: 'u-')).split('-', :skip-empty);
  }
  multi method new(@subtags) {
    my @keys = ();
    for @subtags -> $tag {
      if $tag.chars == 2 {
          push @keys, Key.new(:id($tag));
      }else{
        push @keys.tail.types, $tag;
      }
    }
    self.bless(:@subtags, :@keys)
  }
  multi method gist (::?CLASS:D:) { '[Extension|U:' ~ @.subtags.join(',') ~ ']' }
  multi method gist (::?CLASS:U:) { '[Extension|U]' }
  method canonical {
    # Warning, this is a naïve implementation and only currently makes things
    # lowercase, check valid should be run first.
    '-u' ~ @.keys.sort(*.id).map({'-' ~ .id ~ '-' ~ .types.join('-')})
  }

  method check-valid {
    for @.keys -> $key {
      given $key.id {
        when 'ca' { # CA ('calendar') allows for two tags, which are stored merged ATM
          return False unless $key.types.join ∈ %u-data<ca>;
        }
        default {
          return False unless $key.types == 1; # all keys other than CA have one
                                               # (and only) one type tag.
          return False unless $key.types.head ∈ %u-data{$key.id};
        }
      }
    }
    True;
  }

  ########## ASSOCIATIVE ROLE METHODS ##########
  multi method AT-KEY     (::?CLASS:D: $key) { return-rw @.keys.grep(*.id eq $key).head }
  multi method EXISTS-KEY (::?CLASS:D: $key) {return-rw ?(@.keys.grep(*.id eq $key).elems) }
  multi method ASSIGN-KEY (::?CLASS:D: $key, Str @vals) {push @.keys, Key.new(:id($key), :types(@vals))}
  multi method ASSIGN-KEY (::?CLASS:D: $key, Key $val where {$val.id eq $key}) { push @.keys, $val }
  multi method DELETE-KEY (::?CLASS:D: $key) {
    my $return = @.keys.grep(*.id eq $key).head;
    @.keys = @.keys.grep(*.id ne $key);
    $return;
  }

}

class PrivateUse is export {
  has $.code is rw;
  multi method gist (Any:D:) { '[PrivateUse:' ~ $.code ~ ']' }
  multi method gist (Any:U:) { '[PrivateUse]' }
}


########################################
# Wildcard role to smart match cleaner #
########################################
role Wildcard {
  method type { 'wildcard' }
}
class WildcardLanguage is Language does Wildcard is export {
  has Str $.code = '*';
  method gist { '[Language:*]' }
}
class WildcardScript is Script does Wildcard is export {
  has Str $.code = '*';
  method gist { '[Script:*]' }
}
class WildcardRegion is Region does Wildcard is export {
  has $.code = "*" ;
  method gist { '[Region:*]' }
}
class WildcardVariant is Variant does Wildcard is export {
  has $.code = "*" ;
  method gist { '[Variant:*]' }
}
