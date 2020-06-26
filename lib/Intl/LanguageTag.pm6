# Implementation note:
# Unfortunately, the LanguageTags are cyclical in nature.
# This isn't per se by design, but one of the defined extensions allows
# for an inner language tag (slightly less capable, but should be expected
# to be usable).  This, effectively, requires the entire module (but for
# grammar) to be placed into a single gigantic file with lots of stubs.

unit module LangTag; # Dummy name, only because LanguageTag is also the main class name

use Intl::LanguageTag::X;

# STUBBED CLASSES
class LanguageTagFilter { … }
class LanguageTagFilterActions { … }

=begin pod

=head1 Language Tag

The C<LanguageTag> class

=end pod

#| Represents a BCP-74 language/locale identifier.
class LanguageTag is export {

    # Stub the inner classes
    class Language           { … }
    class IrregularLanguage  { … }
    class Script             { … }
    class Region             { … }
    class Variant            { … }
    class Extension          { … }
    class PrivateUse         { … }
    class LanguageTagActions { … }

    has Language   $.language;     #= The language of the tag
    has Script     $.script;       #= The script of the tag
    has Region     $.region;       #= The region of the tag
    has Variant    @.variants;     #= The variants associated with the tag
    has Extension  @.extensions;   #= The extensions associated with the tag
    has PrivateUse @.privateuses;  #= Any private use tags


    #| Creates a new language tag from the string
    method new(Str $string, :$strict, :$autopreferred) {
        use Intl::LanguageTag::Grammar;

        my %base = BCP47-Grammar.parse($string, :actions(LanguageTagActions)).made;

        # Zero out private uses if the first one is Any, not sure why this is happening
        my @privateuses = %base<privateuses><>;
        @privateuses = () if @privateuses[0].WHAT ~~ Any;

        self.bless:
                language    =>  %base<language>,
                script      => (%base<script>  // Script.new(:code(''))),
                region      => (%base<region>  // Region.new(:code(''))),
                variants    =>  %base<variants>,
                extensions  =>  %base<extensions><>,
                privateuses =>  @privateuses
    }

    # to be international, maybe use these ⚐✎⇢☺︎☻

    #| The extensions method returns each extension on the C<LanguageTag> as a list
    #| while also permitting indexed look ups of the type C<$tag.extensions<t>>.
    method extensions {
        @!extensions but role {
            # This is the magic that lets us be both associative and positional
            # Perhaps it could be better done at BUILD so that we don't need to do this at each access
            also does Associative;
            method AT-KEY ($key) { self.grep( *.singleton eq $key ).head }
        }
    }

    multi method gist (::?CLASS:U:) { '(LanguageTag)' }
    multi method gist (::?CLASS:D:) {
        ~ '['
        ~   $!language.code
        ~   ('-' ~ $!script.code unless $!script.type eq 'blank')
        ~   ('-' ~ $!region.code unless $!region.type eq 'blank')
        ~   ('…' if ?@!extensions || ?@!variants || ?@!privateuses)
        ~ ']'
    }

    #| The default string method will directly map each entity
    #| to the as it is stored or created.
    method Str {
        $!language.code
                ~ ('-' ~ $!script.code unless $!script.type eq 'blank')
                ~ ('-' ~ $!region.code unless $!region.type eq 'blank')
                ~ @!variants.map('-' ~ *.code.lc).join
                ~ @!extensions.map({'-' ~ .singleton ~ '-' ~ .subtags.join('-')}).join
                ~ ('-x' if @!privateuses)
                ~ @!privateuses.map('-' ~ *.code).join; # don't sort privateuses
    }

    #| The canonical method stringifies the language tag, but unlike `Str()`, it will
    #| create a canonical variant of the tag.  This will eventually error if there are
    #| problems (e.g., the tag cannot be made canonical for some reason)
    method canonical (Any:D: --> Str) {
        # Warning: T extension's canonical not fully implemented.
        # Extensions ordered alphabetically by singleton.
        $.language.canonical
                ~ ('-' ~ $!script.canonical unless $!script.type eq 'blank')
                ~ ('-' ~ $!region.canonical unless $!region.type eq 'blank')
                ~ @!variants.map('-' ~ *.canonical).sort.join
                ~ @!extensions.sort(*.singleton).map('-' ~ *.canonical).join
                ~ ('-x' if @!privateuses)
                ~ @!privateuses.map('-' ~ *.code).join; # don't sort privateuses
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

    class Language {
        # Import %languages and %deprecated-languages whose keys
        # are language codes and values are defined thus:
        # [0] = suppressed script, [1] = macro language, [2] = preferred code
        use Intl::LanguageTag::Subtag-Registry :languages;

        has $.code is rw;

        multi method gist (::?CLASS:D:) { '[Language:' ~ $!code ~ ']' }
        multi method gist (::?CLASS:U:) { '(Language)'                }

        #| A canonical language subtag is lower-cased
        method canonical ( --> Str) { $!code.lc }
        #| A valid language
        method validate ( --> Bool ) {
            # Per 2.2.9, a tag is valid if…
            #   (1) tag is well formed
            #   (2) in the IANA subtag registry
            # Since 2 implies 1…
            %languages{$!code.lc}:exists
            # …is sufficient for validation
        }

        method Str { $!code }

        # The following text and method below are deprecated until a new API can be
        # determined to provide this information
        # There are three types defined in most data, regular, deprecated, but also
        # some data sets separate out mis, mul, zxx which have special meanings
        # (for unidentified, multiple, etc).  No reason, I don't think, to
        # be so discriminating.
        method type {
            given $!code {
                when %languages{$_}:exists            { return 'regular'      }
                when %deprecated-languages{$_}:exists { return 'deprecated'   }
                when ''                               { return 'blank'        }
                default                               { return 'unregistered' }
            }
        }

    }

    class IrregularLanguage is Language {
        has $.code is rw;
        multi method gist (::?CLASS:D:) { '[Irr.Lang.:' ~ $!code ~ ']' }
        multi method gist (::?CLASS:U:) { '[Irr.Lang.]'                }
        # The canonical form for languages is to be lower-cased
        # Note that this method SHOULD cause failure for most codes, because most of
        # them have been fully deprecated.  That handling should be taken care of in
        # the other GrandfatheredLanguageTag code, though.
        method canonical { $!code.lc }
        #| DEPRECATED until new API can be made.
        #| Technically, they should be "irregular", but they are technically valid.
        method type { 'regular' }
    }

    =begin pod

      =head2 Script

      The script class

    =end pod
    #| A writing system
    class Script {
        # There are a few other script codes other than the ones that are included in
        # IANA's database.  They can be used so long as :strict isn't enabled.
        use Intl::LanguageTag::Subtag-Registry :scripts;

        subset ScriptStr of Str where /<[a..zA..Z]>**4/ || '';

        has ScriptStr $.code is rw;

        multi method gist (::?CLASS:D:) { '[Script:' ~ $!code ~ ']' }
        multi method gist (::?CLASS:U:) { '[Script]'                }


        #| A script is canonical is has an initial cap and three lowercase
        method canonical (::?CLASS:D: --> Str) { $!code.tclc }
        #| A canonical script is has an initial cap and three lowercase
        method canonicalize (::?CLASS:D: --> Bool) { $!code = $!code.tclc }

        #| A script is valid if it exists in the IANA database
        method valid (::?CLASS:D: --> Bool) { %scripts{$!code.tclc}:exists }
        #| Scripts will be invalid if they don't exist
        method validate { }

        # There are a few special script types, namely the private-use Qa* and the ones
        # with special meaning Zmth, Zsye, Zsym, Zxxx and Zzzz.  At the moment, no
        # need to distinguish them as they are all valid.  Interestingly, although
        # in many places Qaai is listed as deprecated, in the formal IANA registry, it
        # is *not* so designated.
        method type { # TODO is DEPRECATED('.valid to check if registered') {
            given $!code {
                when %scripts{$_}:exists            { return 'regular'      }
                when ''                             { return 'blank'        }
                default                             { return 'unregistered' }
            }
        }
    }

    class Region {
        # Import %languages and %deprecated-languages whose keys
        # are language codes and values are defined thus:
        # [0] = suppressed script, [1] = macro language, [2] = preferred code
        use Intl::LanguageTag::Subtag-Registry :regions;
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

    class Variant {
        # Grants use of %variants and %deprecated-variants.  Keys are the variant
        # subtag code, and the values are two value array with [0] a prefix (which
        # canonically must precede the tag) and [1] a preferred code.
        # Verifying the canonicity of the variant requires knowledge of the
        # Language/Script/Region.  I am not sure the best way to handle that ATM.

        use Intl::LanguageTag::Subtag-Registry :variants;

        has $.code is rw;

        multi method gist (::?CLASS:D:) { '[Variant:' ~ $!code ~ ']' }
        multi method gist (::?CLASS:U:) { '[Variant]'                }

        method canonical { $!code.lc }

        method type {
            given $!code {
                when %variants{$_}:exists            { return 'regular'      }
                when %deprecated-variants{$_}:exists { return 'deprecated'   }
                when ''                              { return 'blank'        }
                default                              { return 'unregistered' }
            }
        }
    }

    class Extension {
        subset Letter of Str where * ~~ /^<[a..z]>$/;

        my Extension:U %extensions{Letter:D} = ();
        #= List of known extensions.

        method REGISTER (Letter:D $id, Extension:U $class) {
            #= Registers an extension.  use the line ｢Extension.REGISTER('x',::?CLASS)｣
            #= as the final line of any subclass to make it known to Extension.
            %extensions{$id} = $class
        }

        has Letter $.singleton;
        has        @.subtags;

        multi method new(:$singleton, :@subtags) {

            # Return base class if not registered
            %extensions{$singleton}:exists
                ?? %extensions{$singleton}.new(@subtags)
                !! self.bless(:$singleton, :@subtags)


            # Early 2019: This elegantish solution of ::('Class') for cyclic dependencies is thanks
            #             to #perl6 user vrurg.  Placing it in CHECK pushes it to resolve at
            #             runtime.  If possible, find a more elegant way with roles.
            # 1 Dec 2019: The registration method seems to work better, because someone
            #             may want to provide support for new extensions before the module
            #             actually can integrate the support into core, or do not-really-private-use
            #             private use tags.
            #given $singleton {
            #    when 'u' { (CHECK ::('UnicodeLocaleExtension')).new: @subtags }
            #    when 't' { (CHECK ::('TransformedContentExtension')).new: @subtags }
            #    default  {
            #        self.bless(:$singleton, :@subtags);
            #    }
            #}
        }
        multi method gist (::?CLASS:D:) { '[Extension:' ~ $!singleton ~ ']' }
        multi method gist (::?CLASS:U:) { '(Extension)'                     }
        method canonical { $!singleton ~ '-' ~ @!subtags.join('-') }
        method type {
            'unregistered'
        }
    }


    class PrivateUse {
        has $.code is rw;
        multi method gist (Any:D:) { '[PrivateUse:' ~ $!code ~ ']' }
        multi method gist (Any:U:) { '(PrivateUse)' }
    }


    class LanguageTagActions {
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

        method language      ($/)  { make   Language.new(:code($/.Str)) }
        method script        ($/)  { make     Script.new(:code($/.Str)) }
        method region        ($/)  { make     Region.new(:code($/.Str)) }
        method variant       ($/)  { make    Variant.new(:code($/.Str)) }
        method privateusetag ($/)  { make PrivateUse.new(:code($/.Str)) }
        method privateuse    ($/)  { make $<privateusetag>.map(*.made)  }
        method extension     ($/)  {
            make Extension.new:
                    singleton => $<singleton>.Str,
                    subtags   =>   $0.map(*.Str)
        }
    }

}


class LanguageTagFilter is export {

    ########################################
    # Wildcard role to smart match cleaner #
    ########################################
    role Wildcard {
        method code { '*' }
        method type { 'wildcard' }
    }
    class WildcardLanguage is LanguageTag::Language does Wildcard { method gist { '[Language:*]' } }
    class WildcardScript   is LanguageTag::Script   does Wildcard { method gist { '[Script:*]'   } }
    class WildcardRegion   is LanguageTag::Region   does Wildcard { method gist { '[Region:*]'   } }
    class WildcardVariant  is LanguageTag::Variant  does Wildcard { method gist { '[Variant:*]'  } }

    has LanguageTag::Language   @.languages;  #    RFC4647 does not provide for filtering based
    has LanguageTag::Region     @.regions;    #    on extensions.  The behavior is undefined
    has LanguageTag::Variant    @.variants;   #    We accept these because it is possible in
    has LanguageTag::Script     @.scripts;    #    the future to provide a programmatic
    has LanguageTag::Extension  @.extensions; #  ⬅︎ interface for defining both matching and
    has LanguageTag::PrivateUse @.privateuse; #  ⬅︎ wild cards, but a string construction (via
                                              #    a Grammar or otherwise) is not possible.
    proto method new (|) {*}
    multi method new (Str $string) {
        use Intl::LanguageTag::Filter-Grammar;
        my %base = BCP47-Filter-Grammar.parse($string, :actions(LanguageTagFilterActions)).made;
        LanguageTagFilter.new(
                :language(%base<language>),
                :script(  %base<script> // WildcardScript.new),
                :region(  %base<region> // WildcardRegion.new),
                :variants(%base<variants><>),
                )
    }

    multi method new (
            LanguageTag::Language   :$language is copy, :@languages is copy where { @languages.defined || @languages.all ~~ LanguageTag::Language},
            LanguageTag::Region     :$region   is copy, :@regions   is copy where { @regions.defined   || @regions.all   ~~ LanguageTag::Region  },
            LanguageTag::Script     :$script   is copy, :@scripts   is copy where { @scripts.defined   || @scripts.all   ~~ LanguageTag::Script  },
            LanguageTag::Variant    :$variant  is copy, :@variants  is copy where { @variants.defined  || @variants.all  ~~ LanguageTag::Variant },
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
    multi method ACCEPTS(LanguageTagFilter:D : Any $tag) {
        # Easy checks first.  An empty array means a the filter was set with an empty
        # value, and per RFC4647 @ 3.3.2 is equivalent to being a wildcard, although
        # the new() method tries to catch anything that would result in a wildcard
        # here.  That said, these are left here in case someone wishes to
        # modify the LanguageTagFilter after construction.
        return False unless
                @!languages ~~ ()               # implied  wildcard
                || @!languages.any ~~ Wildcard  # explicit wildcard
                || $tag.language.canonical eqv @.languages.map(*.canonical).any;
        # If the script is provided in the filter, but not in the tag, according to
        # RFC4647 we should not match.  This seems a bit odd to me, especially if the
        # the tag’s language’s Suppress-Script property matches any of the filter’s
        # script.  An adverb in the future may allow for non-standard (but fully
        # logical) matching by implementing the default script
        return False unless
                @!scripts ~~ ()               # implied  wildcard
                || @!scripts.any ~~ Wildcard  # explicit wildcard
                || $tag.script.canonical eqv @.scripts.map(*.canonical).any;
        return False unless
                @!regions ~~ ()               # implied  wildcard
                || @!regions.any ~~ Wildcard  # explicit wildcard
                || $tag.region.canonical eqv @.regions.map(*.canonical).any;
        return False unless
                @!variants ~~ ()              # implied  wildcard
                || @!variants.any ~~ Wildcard # explicit wildcard
                || $tag.variants >= @.variants;
        # impossible to match if the
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
        for ^@!variants -> $index {
            return False unless
                    @!variants[$index].code    eq '*'
                    || @!variants[$index].code.lc eq $tag.variants[$index].code.lc
        }
        # We MAY want to later add an option for extended checking.  However, a
        # wildcard tag would be highly ambiguous in a string-based format, although
        # there would be no issue setting it up programmatically.  For the time being,
        # however, we simply return True, as that is the RFC4647 standard.
        True
    }
}

class LanguageTagFilterActions {

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
            when '*' { make LanguageTagFilter::WildcardLanguage.new        }
            default  { make LanguageTag::Language.new(:code($/.Str)) }
        }
    }
    method script ($/)  {
        given $/ {
            when '*' { make LanguageTagFilter::WildcardScript.new        }
            when ''  { make LanguageTagFilter::WildcardScript.new        }
            default  { make LanguageTag::Script.new(:code($/.Str)) }
        }
    }
    method region ($/)  {
        given $/ {
            when '*' { make LanguageTagFilter::WildcardRegion.new        }
            when ''  { make LanguageTagFilter::WildcardRegion.new        }
            default  { make LanguageTag::Region.new(:code($/.Str)) }
        }
    }
    method variant ($/)  {
        given $/ {
            when '*' { make LanguageTagFilter::WildcardVariant.new        }
            default  { make LanguageTag::Variant.new(:code($/.Str)) }
        }
    }

    method privateusetag ($/)  {
        die 'Private use subtags are not usable in filters.'
    }
    method extension     ($/)  {
        die "Extension subtags are not usable in filters."
    }
}

class TransformedContent is LanguageTag::Extension does Associative {
    use Intl::LanguageTag::ExtensionRegistry :t; # data imported into %t-data
    # Hybrid locales, see https://unicode-org.atlassian.net/browse/CLDR-13371
    #                     https://unicode-org.atlassian.net/browse/CLDR-13370
    # Filed by yours truly (regularly check the status to update support)

    method singleton { 't' }
    has    @.subtags;
    has    $.origin;
    has    @.fields = ();  # array to maintain input order, canonical is as entered

    class Field {
        has Str $.id;        #= ID matches [a..z][0..9]
        has Str @.tags = (); #= Tags are order sensitive
        method has-date { @!tags.tail ~~ /<[0..9]>**4[<[0..9]>**2]**0..2/ }
        # in the canonization process, they should not be sorted.
        multi method gist (::?CLASS:D:) { '[' ~ $!id ~ ':' ~ @!tags.join(',') ~ ']' }
        multi method gist (::?CLASS:U:) { '[Field]' }
        method canonical { $!id ~ '-' ~ @!tags.join('-') }
    }

    proto new (|) {*}
    multi method new(Str $text) {
        # Break up the text and try again
        samewith $text.substr((2 if $text.starts-with: 't-')).split('-', :skip-empty);
    }
    multi method new(@subtags is copy) {
        # The internal order is
        # (1)  a language tag representing the transformation origin [optional]
        # (2a) a mechanism identifier (alpha + digit)
        # (2b) one or more mechanism tags (all alpha)
        # (3a) a private use mechanism (x0)
        # (3b) one or more mechanism tags (alpha/digit)
        # The sequence 2a/2b may be repeated, although only a handful are defined.
        my @language-tags.push(@subtags.shift)
                while (@subtags.head && @subtags.head !~~ /^<[a..zA..Z]><[0..9]>$/);
        say "LANGUAGE TAG IS ", @language-tags;
        my $origin = Nil;
           $origin = LanguageTag.new(@language-tags.join: '-') if @language-tags.elems > 0;
        say $origin;

        my @fields = ();
        my $in-private = False;
        for @subtags -> $tag {
            if $tag ~~ /^<[a..zA..Z]><[0..9]>$/ && !$in-private { # field header
                push @fields, Field.new(:id($tag));
                $in-private = True if $tag eq 'x0' | 'X0';
            } else {
                push @fields.tail.tags, $tag;
            }
        }
        self.bless(:$origin, :@subtags, :@fields)
    }

    #| This method allows for direct access to the various fields.
    #| Maintained in order as received, but will alphabetize on canonicalization
    method fields {
        return @!fields but role { also does Associative;
            method AT-KEY ($key) { say self; self.grep( *.id eq $key ).head }
        }
    }


    multi method gist (::?CLASS:D:) { '[Extension|T:' ~ @.subtags.join(',') ~ ']' }
    multi method gist (::?CLASS:U:) { '[Extension|T]' }


    method canonical {
        # Contents of fields aren't checked — yet.  When classes are made for
        # predefined ones, then they can be properly canonicalized.
        ~ 't'
        ~ ($!origin ?? ('-' ~ $!origin.Str) !! '')
        ~ @!fields.sort(*.id).map({'-' ~ .id ~ '-' ~ .tags.join('-')}).join.lc
    }


    method check-valid {
        # First check that the language tag is valid, TODO : revisit when full
        # validator methods are implemented
        #return False unless ::('LanguageTag').new(@.language-tags.join: '-');
        # Next cycle through each mechanism, verifying that all of its tags are
        # defined and there are no duplicated values.  There are two special cases:
        # (1) if the mechanism is x0, we only check for well formed-ness, and
        # (2) if the subtag is not found, but is the final element, it must match
        #        a calendar date format of YYYY[MM[DD]].
        # TODO: fully validate dates
        for @.fields -> $field {
            given $field.id {
                when 'x0' {
                    # Valid if and only if all subtags are between 3 and 8 alphanumerical
                    # characters.  Theoretically, our grammar should enforce the alpha-
                    # numerical nature.  Never hurts, I 'spose, to double check as elements
                    # could be added programmatically.
                    return False unless $field.tags.map(* ~~ /^<[a..zA..Z0..9]>**3..8$/).all;
                }
                default {
                    # All elements must be found in the tag database EXCEPT the final one
                    # which should EITHER be in the database OR be a date.
                    # The first step is to check all elements BUT the last one.
                    return False unless $field.types[0..^*-1] ∈ %t-data{$field.id};
                    # Then see check the dual status of the next one.  Either it's a ...
                    return False unless
                            $field.type.tail ∈ %t-data{$field.id} # Valid registered subtag
                            || $field.type.tail ~~ /^<[0..9]>**4$/       # Date (year only)
                                    || $field.type.tail ~~ /^<[0..9]>**4         # Date (year/month)
                            [01||02||03||04||05||06||07||08||09||10||11||12]$/
                            || ($field.type.tail ~~ /^<[0..9]>**6$/      # Date (year/month/day)
                                    &&
                                    DateTime.new(
                                            year  => $field.type.tail.substr(0,4),
                                            month => $field.type.tail.substr(4,2),
                                            day   => $field.type.tail.substr(6,2),
                                            )
                                    )
                    ;
                }
            }
        }
        True;
    }

    # FIELD DATA

    #| If the -h0-hybrid element is present, then there is no actual source language,
    #| the language that comes after -t- is hybridized with
    method origin { self.fields<h0>:exists ?? Nil !! $!origin }

    #| This method currently returns the tags.  At some point in the future
    #| it may return a specialized object, so for maximum compatibility, use
    #| .List on the result (any returned object will List-ify into the raw tags)
    method mechanism { once warn "Make sure to use .mechanism.List for maximum future compatibility"; self.fields<m0>.tags}

    #| This method currently returns the tags.  At some point in the future
    #| it may return a specialized object, so for maximum compatibility, use
    #| .List on the result (any returned object will List-ify into the raw tags)
    method source { once warn "Make sure to use .source.List for maximum future compatibility"; self.fields<s0>.tags}

    #| This method currently returns the tags.  At some point in the future
    #| it may return a specialized object, so for maximum compatibility, use
    #| .List on the result (any returned object will List-ify into the raw tags)
    method destination { once warn "Make sure to use .destination.List for maximum future compatibility"; self.fields<d0>.tags }

    #| This method currently returns the tags.  At some point in the future
    #| it may return a specialized object, so for maximum compatibility, use
    #| .List on the result (any returned object will List-ify into the raw tags)
    method ime { once warn "Make sure to use .ime.List for maximum future compatibility"; self.fields<i0>.tags }

    class Keyboard is Field {
        #| Per documentation, *usually* the first field will be a platform, but there is no obligation.
        #| Ergo, canonical just checks that
        method canonical  { 'k0' }
        method id         { 'k0' }
    }
    #| This method currently returns the tags.  At some point in the future
    #| it may return a specialized object, so for maximum compatibility, use
    #| .List on the result (any returned object will List-ify into the raw tags)
    method keyboard { once warn "Make sure to use .keyboard.List for maximum future compatibility"; self.fields<k0>.tags }

    #| This method currently returns the tags.  At some point in the future,
    #| it will return a specialized object, so for maximum compatibility, use
    #| .List on the result (any returned object will List-ify into the raw tags)
    method machine-translation { once warn "Make sure to use .machine-translation.List for maximum future compatibility";  self.fields<t0>.tags }

    class Hybrid-Locale is Field {
        method canonical  { 'h0-hybrid' }
        method id         { 'h0' }
        multi method gist { '[Hybrid-Locale]' }
    }
    #| If the hybrid tag is present, then the main language is hybridized with
    #| the origin language, if not, there is no hybrid.
    method hybrid-locale { self.fields<h0>:exists ?? $!origin !! Nil }

    #| The hybrid locale is a limited (no extension) language tag that
    #| follows the h0 subtag OR returns the transform source tag if the
    #| only tag is 'hybrid' TODO
    method private { once warn "Make sure to use .private.List for maximum future compatibility";  self.fields<x0>.tags }


    # ASSOCIATIVE ROLE METHODS
    # Consider these to be experimental at the current time.
    multi method     AT-KEY (::?CLASS:D: $field) { return-rw @!fields.grep(*.id eq $field).head }
    multi method EXISTS-KEY (::?CLASS:D: $field) {return-rw ?(@!fields.grep(*.id eq $field).elems) }
    multi method ASSIGN-KEY (::?CLASS:D: $field, @vals where *.all ~~ Str) {push @!fields, Field.new(:id($field), :tags(@vals))}
    multi method ASSIGN-KEY (::?CLASS:D: $field, Field $val where {$val.id eq $field}) { push @.fields, $val }
    multi method DELETE-KEY (::?CLASS:D: $field) {
        my $return = @!fields.grep(*.id eq $field).head;
        @!fields = @!fields.grep(*.id ne $field);
        $return;
    }
}
# Registering means this class is actually used when calling
# Extension.new() with a 't' singleton.
LanguageTag::Extension.REGISTER('t',TransformedContent);


# 'u' extension (Unicode Locale) is still under development
#`｢｢｢｢
class UnicodeLocale is LanguageTag::Extension does Associative {
    use Intl::LanguageTag::ExtensionRegistry :u;

    # To some extent, this extension needs foreknowledge of the main language tag
    # which makes it impossible to include in a separate file.  Non-core extensions
    # won't have that problem.

    method singleton {'u'} # fallback to be extension agnostic
    has @.subtags   = ();  # fallback for all keys/types in order, to be extension agonistic
    has @.keys      = ();  # array to maintain input order, canonical is alphabetical

    # The Key class is the name by which attributes go
    class Key {
        has Str $.id;
        has Str @.values;
        my %keys;
        multi method gist (::?CLASS:D:) { '[Key|'~$!id~':'~@!values.join(',')~']'}
        multi method gist (::?CLASS:U:) { '[Key]' }
        method REGISTER (Str $key, Any:U $class) { %keys{$key} = $class }
        method new($id, @values) {
            return %keys{$id}.new(@values) if %keys{$id}:exists;
            self.bless(:$id, :@values);
        }
    }
    #class Calendar is Key {
    #    has Str $!type;
    #    method id { 'ca' }
    #    method type
    #}





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
    multi method AT-KEY     (::?CLASS:D: $key) { return-rw   @.keys.grep(*.id eq $key).head   }
    multi method EXISTS-KEY (::?CLASS:D: $key) { return-rw ?(@.keys.grep(*.id eq $key).elems) }
    multi method ASSIGN-KEY (::?CLASS:D: $key, Str @vals) {push @.keys, Key.new(:id($key), :types(@vals))}
    multi method ASSIGN-KEY (::?CLASS:D: $key, Key $val where {$val.id eq $key}) { push @.keys, $val }
    multi method DELETE-KEY (::?CLASS:D: $key) {
        my $return = @.keys.grep(*.id eq $key).head;
        @.keys = @.keys.grep(*.id ne $key);
        $return;
    }

}
LanguageTag::Extension.REGISTER('u',UnicodeLocale);
｣｣｣｣

# EXPORTED ENUMS
# Must pass a hash/map for each enum.  These are preprocessed before distributing
# the module. Code and description
package Language is export(:enums, :language-enum) {
    enum ( BEGIN {
        do for %?RESOURCES<enum/languages.data>.slurp.lines».split(',') { $_[0] => $_[1] }
    });
}

package Region is export(:enums, :region-enum) {
    enum ( BEGIN {
        do for %?RESOURCES<enum/regions.data>.slurp.lines».split(',') { $_[0] => $_[1] }
    });
}

#`｢｢
# These will be enabled once adequate short names have been created for them
package Scripts is export(:enums, :script-enum) {
    enum ( BEGIN {
        do for %?RESOURCES<enum/scripts.bcp47data>.slurp.lines».split(',') { $_[0] => $_[1] }
    });
}
｣｣


#`｢｢
# These will be enabled once adequate short names have been created for them
package Variants is export(:enums, :variant-enum) {
    enum ( BEGIN {
        do for %?RESOURCES<enum/variants.bcp47data>.slurp.lines».split(',') { $_[0] => $_[1] }
    });
}
｣｣






# EXPORTED SUBS

# implements RFC 4647
multi sub filter-language-tags(@available where { @available.all ~~ LanguageTag}, $wants, :$basic = False) is export {
    filter-language-tags(@available, ($wants,), :$basic);
}

#| Note that in general, the SOURCE language is expected to have a larger/longer
#| language tag than the filter.  If the filter is longer, it can never match.
#| Additionally, there could be much better logic here.  If only a filter object
#| is passed, we should ignore :basic.  Likewise, if LanguageTagFilters are
#| passed in with :basic set, they should be reduced as best as possible in
#| to conform to the expected string tag.
multi sub filter-language-tags(
        @source where { @source.all ~~ LanguageTag},
        @filter where { @filter.all.map( { $_ ~~ Str || $_ ~~ LanguageTagFilter}) },
        Bool       :$basic = False,
        # The options below are not yet implemented, but are planned
        Bool       :$suppressed,   # Insert suppressed
        Bool       :$canonical,    # Use canonical forms only.  May fail if any
        #   codes cannot be canonicalized.
        Bool       :$nonpreferred  # Reject preferred forms for deprecated tags when
        #   canonicalizing language tags.
        ) is export {

    return filter-language-tags-basic(@source, @filter, :$canonical, :$nonpreferred, :$suppressed) if $basic;

    my @extended-filters = do for @filter { $_ ~~ Str ?? LanguageTagFilter.new: $_ !! $_};
    filter-language-tags-extended(@source, @filter, :$canonical, :$nonpreferred);
}

# Basic filtering, according to RFC4647 § 3.3.1
sub filter-language-tags-basic(
        @source where { @source.all ~~ LanguageTag },
        Str @filter,
        :$canonical    = False,   # to be implemented
        :$nonpreferred = False,   # to be implemented
        :$suppressed   = False    # to be implemented
        --> Seq
        ) {
    my $filter = @filter.any;
    do gather for @source -> $source-tag {
        take $source-tag if (
                || $source-tag.Str.lc eq $filter.lc                 # exact match
                || $source-tag.Str.lc.starts-with($filter.lc ~ '-') # prefix match, ending on a tag
                || $filter eq '*'                                   # wildcard matches all
                )
    }
}

sub filter-language-tags-extended(
        @source where {@source.all ~~ LanguageTag},
        @filter where {@filter.all ~~ LanguageTagFilter},
        :$canonical    = False,    # to be implemented
        :$nonpreferred = False,    # to be implemented
        :$suppressed   = False     # to be implemented
        --> Seq
        ) {
    do gather for @source -> $source-tag {
        take $source-tag if $source-tag ~~ @filter.any
    }
}





#| Implements RFC4647 § 3.4 Lookup
#| Singular returns top match, plural returns an ordered list
sub lookup-language-tag(@available-tags, @preferred-tags, $default = LanguageTag.new('en') --> LanguageTag) is export {
    lookup-language-tags(@available-tags, @preferred-tags, $default) :single;
}
sub lookup-language-tags(@available-tags, @preferences-tags, $default = LanguageTag.new('en'), :$single = False) is export {
    #=  The general assumption is that the PREFERENCES are longer than what is
    #= AVAILABLE.  Anything that is available but is more specific than the
    #= preferences will fail never match.
    #=
    #= WARNING: this is a first attempt, I do not guarantee how well it works, but
    #=          it seems accurate enough.  It does NOT handle wildcards yet, sorry.
    #=
    #= RFC4647 specifically indicates that subtags are to be progressively shed
    #= until a match is found, and the "best match" is the longest possible match.
    #= The exact process for comparing a best match between two or more stated
    #= preferences is not provided.  Imagine the following:
    #=    AVAILABLE      PREFERRED
    #=    ar             en-UK
    #=    en             en-US
    #=    en-US          en
    #=    es             es-ES
    #= In practice, this combination might not happen but it must be contemplated.
    #= A naïve approach is to test if en-UK exists (it doesn't), then strip it of
    #= the UK and then match "en".  But the user has explicitly also preferred
    #= en-US over bare en, so we cannot test "en" until we have tried en-US.
    #= The approach used instead (and, incidentally, faster) is to check for which
    #= preferred values does each available begin, and store the longest at each pass.
    #= 1. Check that @preferred starts with "ar".
    #=     -> (en-UK => "", en-US => "", en => "", es-ES => "")
    #= 2. Check that @preferred starts with "en".
    #=     -> (en-UK => en, en-US => en, en => en, es-ES => ())
    #= 3. Check that @preferred starts with "en-US"
    #=     -> (en-UK => en, en-US => en-US, en => en, es-ES => "")
    #=                               ^^^^^ longer match than just en
    #= 4. Check that @preferred starts with "es"
    #=     -> (en-UK => en, en-US => en-US, en => en, es-ES => es)
    #= TODO: finish documenting the algorithm
    #=
    #= NOTE: this does not currently handle wildcards, which will make the logic
    #= substantially more complicated, reduce speed/efficiency, and probably not
    #= be used.  When such a routine is coded, it may be a good idea to detect
    #= a wildcard presence and use an alternate algorithm.

    # Initially stringify and add a hyphen to avoid potentially overlapping tags
    # of different lengths (otherwise "es" [Spanish] might match "est" [Estonian],
    # and the same can happen with extension/variant tags)
    my @available = @available-tags.map(*.Str ~ '-');
    my @preferences = @preferences-tags.map(*.Str ~ '-');

    my %matches;
    %matches{@preferences} = '' xx ∞;
    for @available -> $tag is rw {
        %matches.map({
            .value = $tag if .key.starts-with($tag) && $tag.chars > .value.chars;
        });
    }

    # We call this naïve because it does not contemplate partial matches, and
    # needs to be paired down still.
    my @naïve-order = lazy gather {
        for @preferences {
            take %matches{$_} unless %matches{$_} eq '';
        }
    }

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
    } else {
        @smart-order = $default;
    }

    $single ?? @smart-order.head !! @smart-order.unique( as => Str, with => &[eq]);
}