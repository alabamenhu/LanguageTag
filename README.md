# Example

A simple Perl 6 module for processing BCP-74 codes.

    use Intl::BCP47;
    my $tag = LanguageTag.new("oc-Latn-ES-aranes-t-en-UK");

    say $tag.language.code;   # --> "oc"
    say $tag.variant[0].code; # --> "aranese"

    my $not-pretty-tag = LanguageTag.new("eN-lATn-Us-u-ca-gregorian-t-es-MX");
    say $not-pretty-tag.canonical; # --> "en-Latn-US-t-es-MX-u-ca-gregorian"

# Supported Standards

Intl::BCP47 implements BCP47, which defines the structure of language tags.

# To do

Right now the module processes tags and provides handy .gist methods and basic
support for canonicalization, but that can be improved.

Future versions will provide more robust error handling (with warnings for
deprecated or undefined tags), support for irregular grandfathered tags, support
for preferred forms of both standard and grandfathered tags, and, most
importantly, matching (so that, given a list of language tags, you can find the
language tag that most closely matches a given tag), and better documentation.

Additional support will later be given for handling the two defined extensions
because at the moment, their canonical forms merely parrot back the source
form (but placing -t before -u) without adjusting internal order or
capitalization.

Once additional elemnts of the CLDR are integrated into other Perl 6 modules,
then support may be added for more descriptive readouts of the tags (e.g.,
saying

    say LanguageTag.new("en-Shaw-US-t-es-Hebr").description

would say "English from the United States in the Shaw script which was transformed
(translated) from Spanish written in the Hebrew script" (or similar verbiage).
If we get more ambitious (and I plan on it!), given a $LANG environment variable
 set to 'ast', the result would be "inglés de los Estaos Xuníos con
calteres latinos que se tornó de castellanu escritu con calteres hebreos".

# License

All files (unless noted otherwise) can be used, modified and redistributed
under the terms of the Artistic License Version 2. Examples (in the
documentation, in tests or distributed as separate files) can be considered
public domain.
