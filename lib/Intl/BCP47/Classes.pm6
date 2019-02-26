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
      when %regions{$_}:exists            { return 'normal'       }
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

  multi method gist (Any:D:) { '[Variant:' ~ $.code ~ ']' }
  multi method gist (Any:U:) { '[Variant]'                }

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
  method new(:$singleton, :@subtags) {
    # Uncomment out this code once the extensions are finished.
    #given $singleton {
    #  when 'u' { return UnicodeLocaleExtension.new: @subtags }
    #  when 't' { return TransfordContentExtension.new: @subtags }
    #  default  {
      self.bless(:$singleton, :@subtags);
    #  }
    #}
  }
  multi method gist (Any:D:) { '[Extension:' ~ $.singleton ~ ':' ~ @.subtags.join(',') ~ ']' }
  multi method gist (Any:U:) { '[Extension]' }
  method type {
    given $.singleton {
      when 't' { return 'transformed-content' }
      when 'u' { return 'unicode-locale'      }
      default  { return 'unregistered'        }
    }
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

class UnicodeLocaleExtension is Extension is export {
  #has UnicodeLocaleAttributes @.attributes;
  # from http://www.unicode.org/repos/cldr/tags/latest/common/bcp47/calendar.xml
  # could be automated with a compile phaser
  # ca
  my @calendar = <buddhist chinese coptic dangi ethioaa ethiopic gregory hebrew
                  indian islamic islamic-umalqura islamic-tbla islamic-civil
                  islamic-rgsa iso8601 japanese persian roc islamicc>;
  # fw
  my @first-day = <sun mon tue wed thu fri sat>;
  # hc
  my @hour-cycle = <h12 h23 h11 h24>;
  # cf
  my @cf = <standard account>;
  # cu
  my @cu = < FOO >;

  has $.calendar;

  method new(@subtags) {

  }
  method canonical {
    '-u'
  }
}

class PrivateUse is export {
  has $.code is rw;
  multi method gist (Any:D:) { '[PrivateUse:' ~ $.code ~ ']' }
  multi method gist (Any:U:) { '[PrivateUse]' }
}

role Wildcard {;}
class WildcardLanguage is Language does Wildcard is export {
  has Str $.code = '*';
  method gist { '[Language:*]' }
  method type { 'wildcard'   }
}
class WildcardScript is Script does Wildcard is export {
  has Str $.code = '*';
  method gist { '[Script:*]' }
  method type { 'wildcard'   }
}
class WildcardRegion is Region does Wildcard is export {
  has $.code = "*" ;
  method gist { '[Region:*]' }
  method type { 'wildcard'    }
}
class WildcardVariant is Variant does Wildcard is export {
  has $.code = "*" ;
  method gist { '[Variant:*]' }
  method type { 'wildcard'    }
}
