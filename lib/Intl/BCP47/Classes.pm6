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

# SUBCLASSED EXTENSIONS:
# These extensions are not yet finished, as they will require a susbtantially
# amount of code to properly validate.  Enable at your own risk.
class TransformedContentExtension is Extension is export {
  #has LanguageTag $.source;
  #has TransformedContentMechanisms @.mechanisms;

  # Unless specified, to be canonical, each tag if present MUST be present in
  # the validation arrays;
  # Dates can be used, but must be the final subtag and will be in the format of
  # YYYY, YYYYMM, or YYYYMMDD.

  # used with tag m0,
  my @mechanism = <alaloc bgn buckwalt din gost iso mcst mns satts ungegn cll
                   css java percent perl plain unicode xml xml10 prprname>;
  # used with tag d0
  my @destination = <ascii accents publish casefold lower upper title digit
                     hwidth hex nfc nfd nfkc nfkd fcd fcc charname npinyin
                     null remove nawgyi>;
  # used with tag s0
  my @source = <accents ascii publish hex npinyin zawgyi>;
  # used with tag i0
  my @ime = <handwrit pinyin wubi und>;
  # used with tag k0
  my @keyboard = <osx windows chromeos android googlevk 101key 102key dvorak
                  dvorak1 dvorakr el220 el319 extended isiri nutaaq legacy
                  lt1205 lt1582 patta qwerty qwertz var viqr ta99 colemak
                  600dpi azerty und>;
  # used with tag t0
  my @translator = <und>;
  # used with tag h0, MUST include hybrid, represents two languages intermingled
  my @hybrid = <hybrid>;


  method new (@subtags) {
    @subtags
  }
  method canonical {
    '-t'
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
          return False unless $key.types.head ∈ %u-data{$key};
        }
      }
    }
    True;
  }

  ########## ASSOCIATIVE ROLE METHODS ##########
  multi method AT-KEY (::?CLASS:D: $key) {
    return-rw @.keys.grep(*.id eq $key).head;
  }
  multi method EXISTS-KEY (::?CLASS:D: $key) {
    return-rw ?(@.keys.grep(*.id eq $key).elems)
  }
  multi method DELETE-KEY (::?CLASS:D: $key) {
    my $return = @.keys.grep(*.id eq $key).head;
    @.keys = @.keys.grep(*.id ne $key);
    $return;
  }
  multi method ASSIGN-KEY (::?CLASS:D: $key, Str @vals) {
    push @.keys, Key.new(:id($key), :types(@vals));
  }
  multi method ASSIGN-KEY (::?CLASS:D: $key, Key $val where {$val.id eq $key}) {
    push @.keys, $val;
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
