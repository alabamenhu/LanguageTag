class LanguageTag::BCP47 {
    use Intl::LanguageTaggish;
    also does LanguageTaggish;

    class Language         { … }
    class Script           { … }
    class Region           { … }
    class Variant          { … }
    class Variants         { … }
    class Extension        { … }
    class Extensions       { … }
    class PrivateUse       { … }

    has Language    $.language;              #= The language of the tag
    has Script      $.script;                #= The script of the tag
    has Region      $.region;                #= The region of the tag
    has Variants    $.variants;              #= The variants associated with the tag
    has Extensions  $.extensions;            #= The extensions associated with the tag
    has PrivateUse  $.private-use;           #= Any private use tags

    proto method new(|) {*}
    multi method new(Str $tag) {
        nextwith $tag.lc.split('-');
    }

    multi method new(*@list is raw) is implementation-detail {
        my $offset = 1;
        my $language    = Language.new:   @list[0];
        my $script      = Script.new:     @list, $offset;
        my $region      = Region.new:     @list, $offset;
        my $variants    = Variants.new:   @list, $offset;
        my $extensions  = Extensions.new: @list, $offset;
        my $private-use = PrivateUse.new: @list, $offset;

        self.bless: :$language, :$script, :$region, :$variants, :$extensions, :$private-use;
    }

    method WHICH { ValueObjAt.new: "Intl::LanguageTag|" ~ self.Str }
    multi method COERCE (LanguageTaggish:D $tag --> ::?CLASS ) {
        self.new: $tag.bcp47
    }
    multi method COERCE (Str:D $tag --> ::?CLASS ) {
        self.new: $tag
    }

    method       bcp47 (            --> Str) {  self.Str       }
    multi method gist  (::?CLASS:D: --> Str) {  self.Str       }
    multi method Str   (::?CLASS:U: --> Str) { '(LanguageTag)' }
    multi method Str   (::?CLASS:D: --> Str) {
        my $s = $!script.Str;
        my $r = $!region.Str;
        my $v = $!variants.Str;
        my $e = $!extensions.Str;
        my $p = $!private-use.Str;

        # Each of the strings must exist.
        # By pre-storing the .Strs, we only call the string formation once
        ~ $!language
        ~ ("-" if $s) ~ $s
        ~ ("-" if $r) ~ $r
        ~ ("-" if $v) ~ $v
        ~ ("-" if $e) ~ $e
        ~ ("-" if $p) ~ $p
    }

    #| Represents a language
    class Language {
        has $!code is built;
        method WHICH { ValueObjAt.new: "Intl::LanguageTag::Language|" ~ $!code }

        method       new   (Str $code   --> ::?CLASS:D) { self.bless: code => $code.lc }
        multi method gist  (::?CLASS:D: -->      Str:D) { '[Language:' ~ $!code ~ ']'  }
        multi method gist  (::?CLASS:U: -->      Str:D) { '(Language)'                 }
        method       Str   (            -->      Str:D) { $!code }

        my %valid          := BEGIN %?RESOURCES<languages-valid>.lines.Set;
        my %deprecated     := BEGIN %?RESOURCES<languages-deprecated>.lines.Set;
        my %macrolanguage  := BEGIN %?RESOURCES<languages-macro>.lines.Map;
        my %default-script := BEGIN %?RESOURCES<languages-script>.lines.Map;
        my %preferred      := BEGIN %?RESOURCES<languages-preferred>.lines.Map;

        #| A well formed language code is 2-3 letters or numbers
        method well-formed    ( --> Bool ) { so $!code ~~ /<[a..zA..Z0..9]> ** 2..3/ }
        #| A valid language code is a code that is well-formed and in the IANA languages database.
        method valid          ( --> Bool ) { %valid{         $!code}:exists }
        #| A deprecated code should be avoided, or converted to a preferred value.
        method deprecated     ( --> Bool ) { %deprecated{    $!code}:exists }
        #| A macrolanguage encompasses several other languages (e.g. Arabic vs MSA, etc).
        method macrolanguage  ( --> Str  ) { %macrolanguage{ $!code} // ''  }
        #| The script to be used if not otherwise specified.
        method default-script ( --> Str  ) { %default-script{$!code} // ''  }
        #| The code that is preferred for this language (for instance, when deprecated)
        method preferred      ( --> Str  ) { %preferred{     $!code} // ''  }
    }

    #| Represents a script
    class Script {
        has $!code is built;
        method WHICH { ValueObjAt.new: "Intl::LanguageTag::Script|" ~ $!code }

        #| Creates a new Script object
        multi method new (Str $code   --> ::?CLASS:D) { self.bless: code => $code.tc }
        multi method new (@subtags is raw, $offset is rw --> ::?CLASS:D) {
            self.bless:
                    code =>
                        @subtags > $offset &&
                        @subtags[$offset].chars == 4
                            ?? @subtags[$offset++].tc
                            !! ''
        }
        multi method gist  (::?CLASS:D: -->      Str:D) { '[Script:' ~ $!code ~ ']'  }
        multi method gist  (::?CLASS:U: -->      Str:D) { '(Script)'                 }
        method       Str   (            -->      Str:D) { $!code }

        my %valid          := BEGIN %?RESOURCES<scripts-valid>.lines.Set;
        my %deprecated     := BEGIN %?RESOURCES<scripts-deprecated>.lines.Set;

        #| A well-formed script consists of four alphanumeric characters
        method well-formed    ( --> Bool ) { so $!code ~~ /<[a..zA..Z0..9]> ** 4/ }
        #| A valid script is found in the IANA registry
        method valid          ( --> Bool ) { %valid{         $!code}:exists }
        #| A deprecated script should be avoided
        method deprecated     ( --> Bool ) { %deprecated{    $!code}:exists }
    }

    #| Represents a region
    class Region {
        has $!code is built;
        method WHICH { ValueObjAt.new: "Intl::LanguageTag::Region|" ~ $!code }

        multi method new (Str $code   --> ::?CLASS:D) { self.bless: code => $code.uc }
        multi method new (@subtags is raw, $offset is rw --> ::?CLASS:D) {
            self.bless:
                code =>
                    @subtags > $offset &&
                    (@subtags[$offset].chars == 2 || @subtags[$offset].chars == 3)
                        ?? @subtags[$offset++].uc
                        !! ''
        }
        multi method gist  (::?CLASS:D: -->      Str:D) { '[Region:' ~ $!code ~ ']'  }
        multi method gist  (::?CLASS:U: -->      Str:D) { '(Region)'                 }
        method       Str   (            -->      Str:D) { $!code }

        my %valid          := BEGIN %?RESOURCES<regions-valid>.lines.Set;
        my %deprecated     := BEGIN %?RESOURCES<regions-deprecated>.lines.Set;
        my %preferred      := BEGIN %?RESOURCES<regions-preferred>.lines.Map;
        #| A well-formed script consists of two alphabetic or three numeric characters
        method well-formed    ( --> Bool ) { so $!code ~~ /<[a..zA..Z]> ** 2 | <[0..9]> ** 3/ }
        #| A valid region is found in the IANA registry
        method valid          ( --> Bool ) { %valid{         $!code}:exists }
        #| A deprecated region should be avoided
        method deprecated     ( --> Bool ) { %deprecated{    $!code}:exists }
        #| The preferred region code (empty string means there is not a more preferred code)
        method preferred      ( --> Str  ) { %preferred{     $!code} // ''  }
    }

    #| A variant
    class Variant {
        has $!code is built;

        method       WHICH { ValueObjAt.new: "Intl::LanguageTag::Variant|" ~ $!code }
        method       new   ( Str $code  --> ::?CLASS:D) { self.bless: :$code }
        multi method gist  (::?CLASS:D: -->      Str:D) { '[Variant:' ~ $!code ~ ']'  }
        multi method gist  (::?CLASS:U: -->      Str:D) { '(Variant)'                 }
        method       Str   (            -->      Str:D) { $!code // '' }

        my %valid          := BEGIN %?RESOURCES<variants-valid>.lines.Set;
        my %deprecated     := BEGIN %?RESOURCES<variants-deprecated>.lines.Set;
        my %prefixes       := BEGIN %?RESOURCES<variants-prefixes>.lines.Map;
        method well-formed ( --> Bool ) { so $!code ~~ /<[a..zA..Z0..9]> ** 5..8 | <[0..9]> <[a..zA..Z]> ** 3/}
        #| Checks that the variant is valid (recognized by the IANA registry).  Use valid-for-language to ensure it's also valid for the language
        method valid       ( --> Bool ) { %valid{         $!code}:exists }
        #| Checks that the variant is valid for the language
        multi method valid-for-language(LanguageTag::BCP47 $tag) { samewith $tag.language}
        #| Checks that the variant is valid for the language
        multi method valid-for-language(Str(Language)     $lang) {
            my @prefixes = %prefixes{self.Str}.split(',');
            for @prefixes -> $prefix {

            }
            False
        }
        #| A deprecated variant should be avoided
        method deprecated  ( --> Bool ) { %deprecated{    $!code}:exists }
        #| The prefix(es) that are valid with this language
        method prefixes    ( --> Seq  ) { %prefixes{$!code}.split(',') }
    }

    #| A container holding one or more variants
    class Variants is Positional {
        has Variant @!variants is built;
        method      WHICH        { ValueObjAt.new: "Intl::LanguageTag::Variants|" ~ self.Str }
        multi method gist  (::?CLASS:D: -->      Str:D) { '[Variants:' ~ @!variants.join(',') ~ ']'  }
        multi method gist  (::?CLASS:U: -->      Str:D) { '(Variants)'                 }
        method        Str        { @!variants.join: '-'       }
        method     AT-POS (\pos) { @!variants.AT-POS(pos)     }
        method EXISTS-POS (\pos) { @!variants.EXISTS-POS(pos) }
        multi method new (Str:D $s) {
            self.bless:
                variants => $s.split('-').map( {Variant.new($_)} )
        }
        multi method new (@subtags is raw, $offset is rw --> ::?CLASS:D) is implementation-detail {
            my Variant @variants;
            @variants.push: Variant.new(@subtags[$offset++])              #   Technically, they should be 5..8
                while @subtags > $offset && @subtags[$offset].chars != 1; # ← characters, but we'll consider them
            self.bless: :@variants                                        #   irregular / poorly formed if requested.
        }

        #| All variants are well-formed
        method well-formed { @!variants.all.well-formed }
        #| Any variant is deprecated
        method deprecated  { @!variants.any.deprecated  }
        #| All variants are valid
        method valid       { @!variants.all.deprecated  }
        #| All variants are valid for the given language
        multi method valid-for-language(Str(Language) $lang) { @!variants.all.valid-for-language($lang)  }
        multi method valid-for-language(LanguageTag::BCP47 $lang) { samewith $lang.language  }
    }
    subset Letter of Str where /<[a..wyz]>/;

    class Extension {
        has    Letter      $.singleton;
        has    Str         @.subtags;
        my     Extension:U %extensions{Letter:D};

        method WHICH { ValueObjAt.new: "Intl::LanguageTag::Extension|{self.Str}" }
        method REGISTER (Letter:D $id, Extension:U $class ) { %extensions{$id} = $class }

        multi method gist  (::?CLASS:D: -->      Str:D) { '[Extension:' ~ self.Str ~ ']'  }
        multi method gist  (::?CLASS:U: -->      Str:D) { '(Extension)'                 }
        method       Str   (            -->      Str:D) { $!singleton ~ (('-' ~ @!subtags.join('-')) if @!subtags) }

        multi method new (@src-subtags is raw, $offset is rw --> ::?CLASS:D) is implementation-detail {
            my Str $singleton = @src-subtags[$offset++];
            my Str @subtags;
            @subtags.push: @src-subtags[$offset++]
                while @src-subtags > $offset && @src-subtags[$offset].chars != 1;
            %extensions{$singleton}.new: :$singleton, :@subtags
        }

        #| Well-formed extensions have subtags of 2..8 alphanumeric characters each
        method well-formed    ( --> Bool ) { so @!subtags ~~ /^ <[a..zA..Z0..9]> ** 2..8 $/}
        #| Valid extensions are simply well-formed
        method valid          ( --> Bool ) { self.well-formed }
        #| Deprecated extensions should be avoided (presently always returns false)
        method deprecated     ( --> Bool ) { False }
    }

    class Extensions is Associative {
        has Extension %!extensions is built;
        method      WHICH        { ValueObjAt.new: "Intl::LanguageTag::Variants|" ~ self.Str }
        method        Str        { %!extensions.values.sort(*.singleton).join: '-'       }
        method     AT-KEY (\key) { %!extensions.AT-KEY(key)     }
        method EXISTS-KEY (\key) { %!extensions.EXISTS-KEY(key) }
        multi method gist (::?CLASS:D: --> Str) { '[Extensions:' ~ %!extensions.values.join(',') ~ ']' }
        multi method gist (::?CLASS:U: --> Str) { '(Extensions)' }
        multi method new(@subtags, $offset is rw --> ::?CLASS:D) is implementation-detail {
            my Extension %extensions;
            while @subtags > $offset && @subtags[$offset] ne 'x' {
                %extensions{@subtags[$offset]} = Extension.new: @subtags, $offset
            }
            self.bless: :%extensions
        }
        #| All extensions are well-formed
        method well-formed { %!extensions.all.well-formed }
        #| Any extension is deprecated
        method deprecated  { %!extensions.any.deprecated  }
        #| All extensions are valid
        method valid       { %!extensions.all.deprecated  }
    }

    class PrivateUse {
        has    Str    @.subtags;
        method WHICH { ValueObjAt.new: "Intl::LanguageTag::PrivateUse|{self.Str}" }

        multi method gist  (::?CLASS:D: -->      Str:D) { '[PrivateUse:' ~ @!subtags.join(',') ~ ']'  }
        multi method gist  (::?CLASS:U: -->      Str:D) { '(PrivateUse)'                 }
        method       Str   (            -->      Str:D) { @!subtags ?? 'x-' ~ @!subtags.join('-') !! '' }

        multi method new(@src-subtags is raw, $offset is rw --> ::?CLASS:D) is implementation-detail {
            my Str @subtags;
            @subtags.push: $_ for @src-subtags[$offset + 1 .. *];
            self.bless: :@subtags
        }

        #| Are the subtags well-formed?
        method well-formed ( --> Bool ) { so @!subtags.all ~~ /<[a..zA..Z0..9]> ** 1..8 /}
        #| All private use tags are valid by definition
        method valid { True  }
    }
}

class UnicodeLocale is LanguageTag::BCP47::Extension does Associative {
    class Type {
        has Str $.id;                     #= ID matches [a..z0..9] ** 2
        has Str @.subtags is default(''); #= Tags are order sensitive

        multi method new(*$id, *@tags) { self.bless: :$id, :@tags}
        multi method new(Str $s) { self.new: $s.split('-') }
        multi method new(\subtags is raw, $offset is rw --> ::?CLASS:D) is implementation-detail {
            my $id = subtags[$offset++];
            my @subtags;
            @subtags.push: subtags[$offset++]
                until $offset == subtags || subtags[$offset].chars < 3;
            self.bless: :$id, :@subtags, :singleton<t>;
        }

        method       WHICH               { ValueObjAt.new: "Intl::LanguageTag::Extension::u|" ~ self.Str  }
        multi method gist  (::?CLASS:D:) { '[' ~ $!id ~ ':' ~ @!subtags.join(',') ~ ']' }
        multi method gist  (::?CLASS:U:) { '(Type)' }
        method       Str                 { $!id ~ '-' ~ @!subtags.join('-') }
    }

    my constant blank-type = Type.new: :id(''), :subtags[];
    has  Type %.types      is default(blank-type);
    has  Str  @.attributes is default('');

    has  LanguageTag::BCP47  $!origin is built;
    #TODO: don't do initial bit if only has x0
    method Str {
        ~ 't'
        ~ ("-" ~ @!attributes.join("-") if @!attributes)
        ~ ("-" ~ %!types.values.sort(*.id).join("-") if %!types)
    }

    proto new (|) { {*} }
    multi method new(:$singleton, :@subtags) {
        # The internal order is
        # (1)  a language tag representing the transformation origin [optional]
        # (2)  a series of attributes (3-8 chars)
        # (3a) a mechanism identifier (2 chars)
        # (3b) one or more mechanism tags (3-8 chars)
        # The sequence 3a/3b may be repeated, although only a handful are defined.

        my Type %types;
        my Str  @attributes;

        my $offset = 0;

        # Calculate the attributes (3-8 characters)
        @attributes.push: @subtags[$offset++] while @subtags > $offset && @subtags[$offset].chars > 2;

        # The rest of the tags are key/[multi]value, which is 2, [3..8]*
        while @subtags > $offset && @subtags[$offset].chars > 1 {
            %types{@subtags[$offset]} = Type.new: @subtags, $offset
        }

        self.bless: :@attributes, :$singleton, :%types
    }
    multi method new(Str $text) {
        # Break up the text and try again
        samewith $text.lc.substr((2 if $text.starts-with: 't-')).split('-', :skip-empty);
    }

    # Named access to different types, for convenience
    method calendar           (--> Type) { self<ca> }
    method currency-format    (--> Type) { self<cf> }
    method collation          (--> Type) { self<co> }
    method currency           (--> Type) { self<cu> }
    method dict-break-exclude (--> Type) { self<dx> }
    method emoji-style        (--> Type) { self<em> }
    method first-day          (--> Type) { self<fw> }
    method hour-cycle         (--> Type) { self<hc> }
    method line-break         (--> Type) { self<lb> }
    method word-break         (--> Type) { self<lw> }
    method measurement-system (--> Type) { self<ms> }
    method numbers            (--> Type) { self<nu> }
    method region-override    (--> Type) { self<rg> }
    method subdivision        (--> Type) { self<sd> }
    method sentence-break     (--> Type) { self<ss> }
    method timezone           (--> Type) { self<tz> }
    method variant            (--> Type) { self<va> }

    multi method gist (::?CLASS:D:) { '[Extension|U:' ~ @.subtags.join(',') ~ ']' }
    multi method gist (::?CLASS:U:) { '[Extension|U]'                             }
    method     AT-KEY (  \key     ) { %!types.AT-KEY:     key                     }
    method EXISTS-KEY (  \key     ) { %!types.EXISTS-KEY: key                     }
}

class TransformedContent is LanguageTag::BCP47::Extension does Associative {
    class Field {
        has Str $.id;                     #= ID matches [a..z][0..9]
        has Str @.subtags is default(''); #= Tags are order sensitive

        multi method new(*$id, *@tags) { self.bless: :$id, :@tags}
        multi method new(Str $s) { self.new: $s.split('-') }
        multi method new(\subtags is raw, $offset is rw --> ::?CLASS:D) is implementation-detail {
            my $id = subtags[$offset++];
            my @subtags;

            if $id eq 'x0' | 'X0' {
                @subtags.push: subtags[$offset++]
                    until $offset == subtags || subtags[$offset].chars == 1;
            } else {
                @subtags.push: subtags[$offset++]
                    until $offset == subtags || subtags[$offset].chars < 3;
            }
            self.bless: :$id, :@subtags, :singleton<t>;
        }

        method       WHICH               { ValueObjAt.new: "Intl::LanguageTag::Extension::t|" ~ self.Str  }
        multi method gist  (::?CLASS:D:) { '[' ~ $!id ~ ':' ~ @!subtags.join(',') ~ ']' }
        multi method gist  (::?CLASS:U:) { '(Type)' }
        method       Str                 { $!id ~ '-' ~ @!subtags.join('-') }
    }

    my constant blank-field = Field.new: :id(''), :subtags[];
    has  Field              %.fields      is default(blank-field);
    has  LanguageTag::BCP47 $!origin is built;

    #TODO: don't do initial bit if only has x0
    method Str {
        ~ 't'
                ~ ("-" ~ $!origin if $!origin)
                ~ ("-" ~ %!fields.values.sort(*.id).grep(*.id ne 'x0').join("-") if %!fields)
                ~ ("-" ~ %!fields<0> if %!fields<x0>:exists)
    }

    proto new (|) { {*} }
    multi method new(:$singleton, :@subtags) {
        # The internal order is
        # (1)  a language tag representing the transformation origin [optional]
        # (2)  a series of attributes (3-8 chars)
        # (3a) a mechanism identifier (2 chars)
        # (3b) one or more mechanism tags (3-8 chars)
        # The sequence 3a/3b may be repeated, although only a handful are defined.

        my Field              %fields;
        my LanguageTag::BCP47 $origin;

        my $offset = 0;

        # Calculate the language (3-8 characters)
        $offset++ while @subtags > $offset && @subtags[$offset] !~~ /^ <[a..zA..Z]> <[0..9]>? $/;

        $origin = LanguageTag::BCP47.new: @subtags[^$offset];

        # The rest of the tags are key/[multi]value, which is 2, [3..8]*
        while @subtags > $offset && @subtags[$offset].chars > 1 {
            %fields{@subtags[$offset]} = Field.new: @subtags, $offset
        }

        self.bless: :$singleton, :$origin, :%fields
    }
    multi method new(Str $text) {
        # Break up the text and try again
        samewith $text.lc.substr((2 if $text.starts-with: 't-')).split('-', :skip-empty);
    }

    # Named access to different types, for convenience
    method hybrid             (--> Field) { self<h0> }
    method source             (--> Field) { self<s0> }
    method destination        (--> Field) { self<d0> }
    method mechanism          (--> Field) { self<m0> }
    method keyboard           (--> Field) { self<k0> }
    method input-method       (--> Field) { self<i0> }
    method translation        (--> Field) { self<t0> }
    method private-use        (--> Field) { self<h0> }

    multi method gist (::?CLASS:D:) { '[Extension|U:' ~ @.subtags.join(',') ~ ']' }
    multi method gist (::?CLASS:U:) { '[Extension|U]'                             }
    method     AT-KEY (  \key     ) { %!fields.AT-KEY:     key                    }
    method EXISTS-KEY (  \key     ) { %!fields.EXISTS-KEY: key                    }
}

LanguageTag::BCP47::Extension.REGISTER: 't', TransformedContent;
LanguageTag::BCP47::Extension.REGISTER: 'u', UnicodeLocale;




#multi sub filter-language-tags(@available where { @available.all ~~ LanguageTag}, $wants, :$basic = False) is export {
#    filter-language-tags(@available, ($wants,), :$basic);
#}

# Note that in general, the SOURCE language is expected to have a larger/longer
# language tag than the filter.  If the filter is longer, it can never match.
# TODO: We really should use multi dispatch here
#| Implements RFC 4647
multi sub filter-language-tags(
        LanguageTag::BCP47() @source, #= The language tags to be filtered (generally longer)
        LanguageTag::BCP47() \filter, #= The language tags to use as a filter (generally shorter)
        Bool :$basic = False,       #= Use basic filtering mode (faster, but potentially less accurate)
) is export {
    return filter-language-tags-basic(@source, filter) if $basic;
    #my @extended-filters = do for @filter { $_ ~~ Str ?? LanguageTagFilter.new: $_ !! $_};
    filter-language-tags-extended(@source, filter);
}

# Basic filtering, according to RFC4647 § 3.3.1
sub filter-language-tags-basic(
        LanguageTag::BCP47() @source, # expect language tag
        LanguageTag::BCP47() \filter,
        --> Seq
) {
    my Str $filter = ~filter;
    do gather for @source -> $source-tag {
        take $source-tag if (
            || $source-tag.Str.lc eq $filter                 # exact match
            || $source-tag.Str.lc.starts-with($filter ~ '-') # prefix match, ending on a tag
           #|| $filter eq '*'                                # wildcard matches all
        )
    }
}

sub filter-language-tags-extended(
        LanguageTag::BCP47() @source, # filter or tag
        LanguageTag::BCP47() \filter, # filter
        --> Seq
) {
    die "NYI";
    do gather for @source -> $source-tag {
        take $source-tag if $source-tag ~~ filter
    }
}



my constant english = LanguageTag::BCP47.new('en');

#| Implements RFC4647 § 3.4 Lookup
sub lookup-language-tags(
        LanguageTag::BCP47  @available-tags,
        LanguageTag::BCP47  @preferred-tags,
        LanguageTag::BCP47  $default = english,
        Bool               :$single  = False
        #--> Seq
) {
    # NOTE: The following is a description of the previous algorithm.
    #       It was perhaps more accurate, but more complicated and will
    #       require some extra rewriting to be performant with the new
    #       language tag format.  In the meantime, a simple version is done
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

    my $available = @available-tags>>.Str>>.split('-').any;
    my @preferred = @preferred-tags>>.Str;

    my @results;
    for @preferred -> $preferred {
        my @subtags = $preferred.split("-");
        while @subtags {
            @subtags.pop if @subtags.tail.chars == 1;
            @results.push: LanguageTag::BCP47.new(@subtags)
                if @subtags ~~ $available;
            @subtags.pop;
        }
    }
    @results.push: $default;
    return @results.head if $single;
    @results;
}


sub EXPORT(*@types) {
    my %export;
    %export<LanguageTag::BCP47>                                = LanguageTag::BCP47;
    %export<LanguageTag::BCP47::Extension::TransformedContent> = TransformedContent    if @types.any eq 'ext-t';
    %export<LanguageTag::BCP47::TransformedContent>            = TransformedContent    if @types.any eq 't';
    %export<LanguageTag::BCP47::Extension::UnicodeLocale>      = UnicodeLocale         if @types.any eq 'ext-u';
    %export<LanguageTag::BCP47::UnicodeLocale>                 = UnicodeLocale         if @types.any eq 'u';
    %export<&filter-language-tags>                             = &filter-language-tags if @types.any eq 'tools';
    %export<&lookup-language-tags>                             = &lookup-language-tags if @types.any eq 'tools';
    %export.Map
}