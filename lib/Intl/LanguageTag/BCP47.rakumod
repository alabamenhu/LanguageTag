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
    has Str         $!str-cache;             #= Stringified version of this tag

    subset Letter of Str where /<[a..wyz]>/; #= A single, unaccented, lowercase Latin letter; excludes x

    my Callable %shortcuts;                  #= Shortcuts that are registered in FALLBACK

    # Legacy tags are historical tags that do not conform to modern
    # language tag syntax.  In the current era (2000) it is rare
    my constant %legacy = Map.new: <
         en-GB-oed     en-GB-oxendict      i-ami         ami
         i-bnn         bnn                 i-hak         hak
         i-klingon     tlh                 i-lux         lb
         i-navajo      nv                  i-pwn         pwn
         i-tao         tao                 i-tay         tay
         i-tsu         tsu                 sgn-BE-FR     sfb
         sgn-BE-NL     vgt                 sgn-CH-DE     sgg
         art-lojban    jbo                 no-bok        nb
         no-nyn        nn                  zh-guoyu      cmn
         zh-hakka      hak                 zh-min-nan    nan
         zh-xiang      hsn                 i-default     ?
         i-enochian    ?                   i-mingo       ?
         cel-gaulish   ?                   zh-min        ?
    >;
    my constant %legacy-unmappable = Map.new: (
        i-mingo     => "The tag ‘i-mingo’ should be avoided.  \nPerhaps you meant to use ‘see’ (for the virtually identical Senecan language)",
        zh-min      => "The tag ‘zh-min’ should be avoided.  \nPerhaps you meant to use ‘cdo’ (Min Dong), ‘cpx’ (Pu-Xian), ‘czo’ (Min Zhong), \n‘mnp’ (Min Bei), or ‘nan’ (Min Nan)?",
        cel-gaulish => "The tag ‘cel-gaulish’ should be avoided.  \nPerhaps you meant to use ‘xcg’ (Cisalpine), ‘xga’ (Galatian), or ‘xtg’ (Transalpine)?",
        i-enochian  => "The tag ‘enochian’ should be avoided.  \nPerhaps you meant to use ‘mis-x-enochian’ (uncoded, with private use indication)?",
        i-default   => "The tag ‘i-default’ should be avoided.  \nPerhaps you meant to use ‘und’ (undefined)?"
    );

    proto method new(|) {*}
    multi method new(Str $tag) {
        if %legacy{$tag}:exists {
            if %legacy-unmappable{$tag}:exists {
                warn %legacy-unmappable{$tag};
                nextwith $tag.list
            } else {
                nextwith %legacy{$tag}.split('-')
            }
        } else {
            nextwith $tag.lc.split('-')
        }
    }
    multi method new(*@list is raw) is implementation-detail {
        my $offset = 1;

        # In a canonical tag, these are partially interconnected.
        # In this method, we handle the interconnectedness for language, script, region, variants.
        # Extensions are out of our purview, so are sent L/S/R for creation.
        my $language    = Language.new:   @list, $offset;
        my $script      = Script.new:     @list, $offset;
        my $region      = Region.new:     @list, $offset;
        my $variants    = Variants.new:   @list, $offset;
        my $extensions  = Extensions.new: @list, $offset, $language, $script, $region;
        my $private-use = PrivateUse.new: @list, $offset;

        # Data clean up
        #
        # Script should *always* be defined for introspection by internationalization
        # frameworks -- we'll remove it during stringification if it can be implied.
        $script = Script.new: $language.default-script if $script eq '';

        # Next, when a subdivision is present, it's recommended to either
        #   (a) set $region based on it (if $region eq '')
        #   (b) do nothing (if $region eq .subdivision.substr(0,2).lc)
        #   (c) remove subdivision (if ne $region) -- this will be handed in the $extensions creation
        if '' ne my $sd = $extensions<u>.subdivision {
            $region = Region.new: code => $sd.Str.substr(0,2)
        }

        self.bless: :$language, :$script, :$region, :$variants, :$extensions, :$private-use;
    }

    method WHICH {
        ValueObjAt.new: "Intl::LanguageTag|" ~ self.Str
    }
    multi method COERCE (LanguageTaggish:D $tag --> ::?CLASS ) {
        self.new: $tag.bcp47
    }
    multi method COERCE (Str:D $tag --> ::?CLASS ) {
        self.new: $tag
    }
    method REGISTER-SHORTCUT (::?CLASS:U: Str:D \indicator, Callable:D \route) {
        %shortcuts{indicator} := route;
    }
    method FALLBACK (Str:D $want) {
        return .(self)
            with %shortcuts{$want};
        ''; # blank string per LanguageTaggish standard
    }

    method       bcp47 (            --> Str) {  self.Str       }
    multi method gist  (::?CLASS:D: --> Str) {  self.Str       }
    multi method Str   (::?CLASS:U: --> Str) { '(LanguageTag)' }
    multi method Str   (::?CLASS:D: --> Str) {
        .return with $!str-cache;

        # Each of the strings must exist (but may be empty and falsey).
        # By pre-storing the .Strs, we only call the string formation once
        my $script      = $!script.Str;
        my $region      = $!region.Str;
        my $variants    = $!variants.Str;
        my $extensions  = $!extensions.Str;
        my $private-use = $!private-use.Str;

        my Str $tag = ~$!language;

        $tag ~= "-$script"
            if $script ne $!language.default-script;

        $!str-cache =
            ~ $tag
            ~ ("-" if $region     ) ~ $region
            ~ ("-" if $variants   ) ~ $variants
            ~ ("-" if $extensions ) ~ $extensions
            ~ ("-" if $private-use) ~ $private-use
    }

    #| Represents a language
    class Language {
        has $!code is built;
        method WHICH { ValueObjAt.new: "Intl::LanguageTag::Language|" ~ $!code }

        my %valid          := BEGIN %?RESOURCES<languages-valid>.lines.Set;
        my %deprecated     := BEGIN %?RESOURCES<languages-deprecated>.lines.Set;
        my %macrolanguage  := BEGIN %?RESOURCES<languages-macro>.lines.Map;
        my %default-script := BEGIN %?RESOURCES<languages-script>.lines.Map;
        my %preferred      := BEGIN %?RESOURCES<languages-preferred>.lines.Map;
        my %extended       := BEGIN %?RESOURCES<languages-extended>.lines.map(-> $pfx, $exts { $pfx => $exts.split(',').List }).Map;

        proto method new (|) { * }
        multi method new (Str $code   --> ::?CLASS:D) {
            self.bless: code => $code.lc
        }
        multi method new (@codes is raw, $offset is rw --> ::?CLASS:D) is implementation-detail {
            if %extended{@codes[0]}:exists && @codes[1] (elem) %extended{@codes[0]} {
                $offset = 2;
                return self.bless: code => @codes[0] ~ "-" ~ @codes[1]
            }else{
                $offset = 1;
                return self.bless: code => @codes[0]
            }
        }
        multi method gist  (::?CLASS:D: -->      Str:D) { '[Language:' ~ $!code ~ ']'  }
        multi method gist  (::?CLASS:U: -->      Str:D) { '(Language)'                 }
        method       Str   (            -->      Str:D) { $!code }

        #| A well formed language code is 2-3 letters or numbers
        method well-formed ( --> Bool ) { so $!code ~~ /<[a..zA..Z0..9]> ** 2..3/ }

        #| A valid language code is a code that is well-formed and in the IANA languages database.
        method valid ( --> Bool ) { %valid{$!code}:exists }

        #| A deprecated code should be avoided, or converted to a preferred value if it exists.
        method deprecated ( --> Bool ) { %deprecated{$!code}:exists }

        #| A macrolanguage encompasses several other languages (e.g. Arabic vs MSA, etc).
        method macrolanguage ( --> Str  ) { %macrolanguage{$!code} // '' }

        #| The script to be used if not otherwise specified.
        method default-script ( --> Str  ) { %default-script{$!code} // '' }

        #| The code that is preferred for this language (for instance, when deprecated)
        method preferred ( --> Str  ) { %preferred{$!code} // '' }
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
        method well-formed ( --> Bool ) { so $!code ~~ /<[a..zA..Z0..9]> ** 4/ }

        #| A valid script is found in the IANA registry
        method valid ( --> Bool ) { %valid{$!code}:exists }

        #| A deprecated script should be avoided
        method deprecated ( --> Bool ) { %deprecated{$!code}:exists }
    }

    #| Represents a region
    class Region {
        has $!code is built;
        method WHICH { ValueObjAt.new: "Intl::LanguageTag::Region|" ~ $!code }

        multi method new (Str $code --> ::?CLASS:D) { self.bless: code => $code.uc }
        multi method new (@subtags is raw, $offset is rw --> ::?CLASS:D) is implementation-detail {
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

        method       WHICH { ValueObjAt.new: "Intl::LanguageTag::Variant|" ~ $!code   }
        method       new   ( Str $code  --> ::?CLASS:D) { self.bless: :$code          }
        multi method gist  (::?CLASS:D: -->      Str:D) { '[Variant:' ~ $!code ~ ']'  }
        multi method gist  (::?CLASS:U: -->      Str:D) { '(Variant)'                 }
        multi method Str   (::?CLASS:D: -->      Str:D) { $!code // ''                }
        multi method Str   (::?CLASS:U: -->      Str:D) {           ''                }

        # Resource files autogenerated from
        my %valid       := BEGIN %?RESOURCES<variants-valid     >.lines.Set;
        my %deprecated  := BEGIN %?RESOURCES<variants-deprecated>.lines.Set;
        my %prefixes    := BEGIN %?RESOURCES<variants-prefixes  >.lines.Map;

        #| Checks that the variant is well form (5 to 8 characters, or 4 if starting with a digit)
        method well-formed ( --> Bool ) {
            so $!code ~~ /<[a..zA..Z0..9]> ** 5..8 | <[0..9]> <[a..zA..Z]> ** 3/
        }

        #| Checks that the variant is valid (recognized by the IANA registry).  Use valid-for-language to ensure it's also valid for the language
        method valid ( --> Bool ) {
            %valid{$!code}:exists
        }

        #| Checks that the variant is valid for the language tag (generally the parent tag of the variant)
        multi method valid-for-tag(LanguageTag::BCP47 $tag) {
            samewith $tag.Str
        }

        #| Checks that the variant is valid for the language tag (generally the parent tag of the variant)
        multi method valid-for-tag(Str $tag) is implementation-detail {
            so $tag.starts-with: any %prefixes{self.Str}.split(',');
        }

        #| A deprecated variant should be avoided
        method deprecated ( --> Bool ) {
            %deprecated{$!code}:exists
        }

        #| The prefix(es) that are valid with this language
        method prefixes ( --> Seq  ) {
            %prefixes{$!code}.split: ','
        }
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

    #| An extension is defined by an external authority which governs its
    #| interpretation.  More specific interpretations are possible if
    #| extensions are registered (U and T extensions are always available)
    class Extension {
        has    Str         @.subtags;
        my     Extension:U %extensions{Letter:D};

        method WHICH { ValueObjAt.new: "Intl::LanguageTag::Extension|{self.Str}" }
        method REGISTER-EXTENSION (::?CLASS:U: Letter:D \id, Extension:U \ext) { %extensions{id} := ext }


        multi method gist  (::?CLASS:D: -->      Str:D) { '[Extension:' ~ self.Str ~ ']'  }
        multi method gist  (::?CLASS:U: -->      Str:D) { '(Extension)'                 }
        method       Str   (            -->      Str:D) { @!subtags.join('-') }

        multi method new ( :$singleton, :@subtags, :$language, :$script, :$region ) {
            self.bless: :@subtags
        }
        # By default, the positional one will be called
        # Subclasses will implement a purely named-arguments approach if they need to
        # handle language/script/region specially.

        multi method new (@src-subtags is raw, $offset is rw, $language, $script, $region --> ::?CLASS:D) is default {
            my Str $singleton = @src-subtags[$offset++];
            my Str @subtags;
            @subtags.push: @src-subtags[$offset++]
                while @src-subtags > $offset && @src-subtags[$offset].chars != 1;
            %extensions{$singleton}.new: :$singleton, :@subtags, :$language, :$script, :$region
        }

        #| Well-formed extensions have subtags of 2..8 alphanumeric characters each
        method well-formed    ( --> Bool ) { so @!subtags ~~ /^ <[a..zA..Z0..9]> ** 2..8 $/}
        #| Valid extensions are simply well-formed
        method valid          ( --> Bool ) { self.well-formed }
        #| Deprecated extensions should be avoided (presently always returns false)
        method deprecated     ( --> Bool ) { False }
    }

    class Extensions is Associative {
        my class EmptyExtension is Extension {
            # This class functions as a sort of Nil,
            # but ensures ultimate stringification
            # always results in any empty string
            method Str          { ''             }
            method AT-KEY       { EmptyExtension }
            method AT-POS       { EmptyExtension }
            method EXISTS-KEY   { False          }
            method EXISTS-POS   { False          }
            method FALLBACK ($) { EmptyExtension }
        }

        has Extension %!extensions is built;
        method      WHICH        { ValueObjAt.new: "Intl::LanguageTag::Variants|" ~ self.Str }
        method        Str        { %!extensions.pairs.sort(*.key).map({.key ~ "-" ~ .value}).join: '-'}
        method     AT-KEY (\key) { %!extensions.AT-KEY(key) // EmptyExtension }
        method EXISTS-KEY (\key) { %!extensions.EXISTS-KEY(key) }
        multi method gist (::?CLASS:D: --> Str) { '[Extensions:' ~ %!extensions.values.join(',') ~ ']' }
        multi method gist (::?CLASS:U: --> Str) { '(Extensions)' }
        multi method new(@subtags is raw, $offset is rw, $language, $script, $region is rw --> ::?CLASS:D) is implementation-detail {
            my Extension %extensions;
            while @subtags > $offset && @subtags[$offset] ne 'x' {
                %extensions{@subtags[$offset]} = Extension.new: @subtags, $offset, $language, $script, $region
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

#| The Unicode extension (U) further refines the language selection
#| using various properties as defined by Unicode (e.g. calendar type,
#| or timezones) needed for proper formatting of textual items in the
#| language.
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
            self.bless: :$id, :@subtags, :singleton<u>;
        }

        method       WHICH               { ValueObjAt.new: "Intl::LanguageTag::Extension::u::Type|" ~ self.Str  }
        multi method gist  (::?CLASS:D:) { '[' ~ $!id ~ ':' ~ @!subtags.join(',') ~ ']' }
        multi method gist  (::?CLASS:U:) { '(Type)' }
        method       Str                 { @!subtags.join('-') }
        multi method Bool  (::?CLASS:U:) { False        }
        multi method Bool  (::?CLASS:D:) { so @!subtags }
    }

    my constant blank-type = Type.new: :id(''), :subtags[];
    has  Type %.types      is default(blank-type);
    has  Str  @.attributes is default(''); #= Attributes are currently reserved, and so always unused

    # The language origin should exclude all singletons (including private use).
    # To preserve default script and variant enforcement, we use the actual LanguageTag::BCP47
    # We can enforce the lack of singletons at creation, but can't guarantee it for others.
    has  LanguageTag::BCP47  $!origin is built;

    method Str {
        # Attributes are currently reserved, so we ignore them for now
        #~ (@!attributes.join("-") if @!attributes)
        my $tag = %!types.pairs.grep(*.key ne 'x0').sort(*.key).map({.key ~ '-' ~ .value}).join("-");
        if %!types<x0>:exists {
            $tag ~= '-' if $tag;
            $tag ~= 'x0-' ~ %!types<x0>.Str;
        }
        $tag
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
        %types{@subtags[$offset]} = Type.new: @subtags, $offset
            while @subtags > $offset
               && @subtags[$offset].chars > 1;

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
    method      WHICH               { ValueObjAt.new: "Intl::LanguageTag::Extension::u|" ~ self.Str  }
}

#| The Transformed Content extension (T) defines how the content should be transformed.
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
            self.bless: :$id, :@subtags;
        }

        method       WHICH               { ValueObjAt.new: "Intl::LanguageTag::Extension::t::Field|" ~ self.Str  }
        multi method gist  (::?CLASS:D:) { '[' ~ $!id ~ ':' ~ @!subtags.join(',') ~ ']' }
        multi method gist  (::?CLASS:U:) { '(Type)' }
        method       Str                 { @!subtags.join: '-' }
    }

    my constant blank-field = Field.new: :id(''), :subtags[];
    has  Field              %.fields is default(blank-field);
    has  LanguageTag::BCP47 $.origin is built;

    method Str {
        my $tag = $!origin.Str.lc; # canonically lowercase in the -t- extension

        $tag ~= '-'
            if  %!fields  > 2                              # Guaranteed at least one is not private use
            || (%!fields == 1 && (%!fields<x0>:!exists)); # If only one, check whether it's x0

        $tag ~= %!fields.pairs.grep(*.key ne 'x0').sort(*.key).map({.key ~ '-' ~ .value}).join("-");
        if %!fields<x0>:exists {
            $tag ~= '-' if $tag;
            $tag ~= 'x0-' ~ %!fields<x0>;
        }
        $tag
    }

    #| Creates a new Transformed Content extension object
    proto new (|) { {*} }
    multi method new(:$singleton, :@subtags) {
        # The internal order is
        #   (1)  a language tag representing the transformation origin [optional]
        #   (2)  a series of attributes (3-8 chars)
        #   (3a) a mechanism identifier (2 chars)
        #   (3b) one or more mechanism tags (3-8 chars)
        # The sequence 3ab may be repeated, although only a handful are defined.

        my Field              %fields;
        my LanguageTag::BCP47 $origin;
        my Int                $offset = 0;

        # Calculate the language.
        # It will terminate on the first mechanism identifier, so the tag is necessarily
        # limited to only language, script, region, and variant.
        $offset++
            while @subtags > $offset
            &&    @subtags[$offset] !~~ /^ <[a..zA..Z]> <[0..9]>? $/;

        $origin .= new: @subtags[^$offset];

        # Calculate the mechanisms.
        # All remaining tags are groups of a 2-char key followed by one or more 3-8-char values
        %fields{@subtags[$offset]} = Field.new: @subtags, $offset
            while @subtags > $offset
            &&    @subtags[$offset].chars > 1;

        self.bless: :$singleton, :$origin, :%fields
    }
    multi method new(Str $text) {
        # Break up the text and try again
        samewith $text.lc.substr((2 if $text.starts-with: 't-')).split('-', :skip-empty);
    }

    # Named access to different types, for convenience
    method hybrid       (--> Field) { self<h0> }
    method source       (--> Field) { self<s0> }
    method destination  (--> Field) { self<d0> }
    method mechanism    (--> Field) { self<m0> }
    method keyboard     (--> Field) { self<k0> }
    method input-method (--> Field) { self<i0> }
    method translation  (--> Field) { self<t0> }
    method private-use  (--> Field) { self<h0> }

    multi method gist (::?CLASS:D:) { '[Extension|U:' ~ @.subtags.join(',') ~ ']' }
    multi method gist (::?CLASS:U:) { '[Extension|U]'                             }
    method     AT-KEY (  \key     ) { %!fields.AT-KEY:     key                    }
    method EXISTS-KEY (  \key     ) { %!fields.EXISTS-KEY: key                    }
}


# Ensure the extensions and shortcuts are registered.
# This code needn't be quite this verbose, but we should probably avoid
# having so too many shortcuts.  Just because we *can* offer a shortcut
# to drill down three levels into an extension doesn't mean we should.
# If the next few lines gets too big to fit on a screen, think twice.
LanguageTag::BCP47::Extension.REGISTER-EXTENSION: 't', TransformedContent;
LanguageTag::BCP47::Extension.REGISTER-EXTENSION: 'u', UnicodeLocale;;

LanguageTag::BCP47.REGISTER-SHORTCUT: 'transform',          *.extensions<t>;
LanguageTag::BCP47.REGISTER-SHORTCUT: 'unicode',            *.extensions<u>;

LanguageTag::BCP47.REGISTER-SHORTCUT: 'calendar',           *.extensions<u><ca>;
LanguageTag::BCP47.REGISTER-SHORTCUT: 'currency-format',    *.extensions<u><cf>;
LanguageTag::BCP47.REGISTER-SHORTCUT: 'collation',          *.extensions<u><co>;
LanguageTag::BCP47.REGISTER-SHORTCUT: 'currency',           *.extensions<u><cu>;
LanguageTag::BCP47.REGISTER-SHORTCUT: 'dict-break-exclude', *.extensions<u><dx>;
LanguageTag::BCP47.REGISTER-SHORTCUT: 'emoji-style',        *.extensions<u><em>;
LanguageTag::BCP47.REGISTER-SHORTCUT: 'first-day',          *.extensions<u><fw>;
LanguageTag::BCP47.REGISTER-SHORTCUT: 'hour-cycle',         *.extensions<u><hc>;
LanguageTag::BCP47.REGISTER-SHORTCUT: 'line-break',         *.extensions<u><lb>;
LanguageTag::BCP47.REGISTER-SHORTCUT: 'word-break',         *.extensions<u><lw>;
LanguageTag::BCP47.REGISTER-SHORTCUT: 'measurement-system', *.extensions<u><ms>;
LanguageTag::BCP47.REGISTER-SHORTCUT: 'numbers',            *.extensions<u><nu>;
LanguageTag::BCP47.REGISTER-SHORTCUT: 'region-override',    *.extensions<u><rg>;
LanguageTag::BCP47.REGISTER-SHORTCUT: 'subdivision',        *.extensions<u><sd>;
LanguageTag::BCP47.REGISTER-SHORTCUT: 'sentence-break',     *.extensions<u><ss>;
LanguageTag::BCP47.REGISTER-SHORTCUT: 'timezone',           *.extensions<u><tz>;
LanguageTag::BCP47.REGISTER-SHORTCUT: 'uni-variant',        *.extensions<u><va>;


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



#my \english = LanguageTag::BCP47.new('en');

#| Implements RFC4647 § 3.4 Lookup
sub lookup-language-tags(
        LanguageTag::BCP47  @available-tags,
        LanguageTag::BCP47  @preferred-tags,
        LanguageTag::BCP47  $default = LanguageTag::BCP47.new('en'),
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