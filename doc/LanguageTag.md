NAME
====

Language Tag

AUTHOR
======

Matthew Stephen Stuckwisch

VERSION
=======

0.1

TITLE
=====

Language Tag

The LanguageTag module helps perform many different common operations regarding language identification, filtering, etc. It currently integrates the following standards: [BCP47](https://tools.ietf.org/html/bcp47) (tags), [RFC4647](https://tools.ietf.org/html/rfc4647) (filtering), and, via [UTS35](http://unicode.org/reports/tr35/), [RFC6497](https://tools.ietf.org/html/rfc6497) (extension 't') and [RFC6067](https://tools.ietf.org/html/rfc6067).

Basic Usage
===========

    use Intl::LanguageTag;
    my $tag = LanguageTag.new("oc-Latn-ES-aranes-t-en-UK");

    say $tag.language.code;   #  ↪︎ "oc"
    say $tag.variant[0].code; #  ↪︎ "aranese"

Most users will just want to use the main class, LanguageTag, but a common way to work with language tags is to filter them. There are two ways to do that. For filtering multiple values, you can use the sub `filter-language-tags`

    my @tags = (
      LanguageTag.new('es-ES'),
      LanguageTag.new('es-MX'),
      LanguageTag.new('es-Latn-GQ'),
      LanguageTag.new('pt-GQ'),
    );

    filter-language-tags: @tags, 'es';   #  ↪︎ [es-ES], [es-MX], [es-GQ]
    filter-language-tags: @tags, '*-GQ'; #  ↪︎ [es-GQ], [pt-GQ]

To check a single value, you can smart match on a filter object:

    my $filter = LanguageTagFilter('*-Latf'); # 'in Fraktur script'

    LanguageTag.new('de-Latf-DE') ~~ $filter # ↪︎ True
    LanguageTag.new('de-Latn-AU') ~~ $filter # ↪︎ False

The filtering is based on RFC4647 and is what you might expect in a HTTP request header. However, for the ambitious, the special LanguageTagFilter object provides for a good more flexibility and power than what you get from the basic `.new(Str)` if you create it programmatically.

