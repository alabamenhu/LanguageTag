# Intl::LanguageTag

> ###⚠︎ Warning ⚠︎ 
> v0.11+ is *mostly* backwards compatible with v.0.10 and prior.  The following is not backwards compatible from v0.10-:**
>  * Heavy extensions introspection (possible in v0.12, but via new API)
>  * Grandfathered / legacy tags (possible in v0.12, but via new API)
>  * Creation by means other than a `Str`
>  * Enums
>  * `LanguageTagFilter` objects
  
Support for all will be addressed in forthcoming updates.

## Usage

```raku
use Intl::LanguageTag;                  # ← Imports as 'LanguageTag'
use Intl::LanguageTag::BCP-47;          # ← Imports as 'LanguageTag::BCP-47'
use Intl::LanguageTag::BCP-47 <enums>;  # ← Include enums
use Intl::LanguageTag::BCP-47 <utils>;  # ← Include lookup-language-tags
                                        #       and filter-language-tags subs

# Create a new LanguageTag from a string
LanguageTag.new: 'en-US';
```

## Which to `use`
Most of the time, `use Intl::LanguageTag` is what you will want (the BCP-47 tag type is set as the default for a reason).
Prefer `use Intl::LanguageTag::BCP-47` when interacting with other language tag types in the same scope to avoid a symbol collision.

## Features

Everything is value typed!  This means you can easily use them in sets, bags, and mixes and routines like `unique` will operate as you'd expect.

Once you've created a language tag, you have the following simple methods to introspect it.

  * **`.language`**  
  The language code.  
  Introspections: *.well-formed, .valid, .preferred, .deprecated, .macrolanguage, .default-script*)
  * **`.script`**  
  The script used, will be omitted if the same as the default script.  
  Introspections: *.well-formed, .valid, .deprecated*)
  * **`.region`**  
  The region code  
  Introspections: *.well-formed, .valid, .deprecated, .preferred*)
  * **`.variants`**  
  The variant codes. This object provides positional access to its subtags.  
  Introspections: *.well-formed, .valid, .valid-for-tag, .deprecated, .prefixes*)
  * **`.extensions`**  
  Any extensions.  This object provides hashy access (currently recognizing `<t>` and `<u>`)
  * **`.private-use`**  
  Any private use tags. This object provides positional access to its subtags.
  
Each of the above will stringify into the exact code, but also has introspective methods. 
For instance, `.language.default-script` tells you what the default script for the language is.

## Canonicalization

Language tags are canonicalized to the extent possible upon creation.  
This is done in accordance with BCP 47, RFC 6067, RFC 6497, and TR 35 and helps to guarantee value typing mechanics.
Most likely, you may notice that a script will disappear.
Less likely, if you use grandfathered tags, tags like `i-navajo` will be automatically converted to their preferred form (`nv`) when those exist.
There are five grandfathered tags without preferred forms which will preserve the entire tag as the “language” (e.g. `i-default`), and issue a warning since those tags should not be used.
Extended languages tags *are* preserved, and with on-demand and automatic conversion to preferred forms planned for a future release.

## Utility functions

If you include `<utils>` in your use statement, you will have access to two subs to aid working with language tags.
They are the following:

 * **`sub filter-language-tags(@source, $filter, :$basic = False)`**  
 This performs a 'filter' operation.  The source is a list of BCP47 objects, and the filter is also a BCP47. 
 When in basic mode, all source tags that are identical to, or begin with tags identical to the filter are returned.
 * **`sub lookup-language-tags(@available, @preferred, $default)`**  
 Performs a 'lookup' operation to return an optimally matching language tag. 
 A common usage might be in an HTML server to receive the client's `@preferred` languages and compare them
 to the `@available` languages on the server.  The `.head` is the best language to use (or use `:single` if you have no need for backup choices).
 
If the names of these functions is too verbose, you can alias them easily by doing `my &filter = filter-language-tags`.

## Todo

In likely order of completion:

  * Restore `enum` access
  * Better introspection of extensions U / T
  * Logical cloning with changes
  * Better validation (`.deprecated`, `.valid`, etc)
  * Extlang and grandfathered tag support (via automatic canonicalization)
  * Improve filtering by enabling wildcards in matches.
  * More exhaustive test files

## Version history
- 0.12.1
  - Fixed an issue with a potentially consumed sequence when accessing extensions
  - Updated to IANA subtag registry dated 2022-08-08
  - Moved to zef ecosystem
- 0.12.0
  - Extensions and their subelements no longer prefix their type in `.Str` (technically not backwards compatible) for more intuitive use
  - Some canonicalization during creation (making `en-Latn-US-u-rg-us` yields `en-US`)
  - Smart introspection (`LanguageTag.new('en').script` yields `Latn`, as it's the specified default)
  - Updated to IANA subtag registry dated 2021-05-11
  - 'Shortcuts' available for introspection to Unicode extensions T / U
    - API makes this available for modules creating custom extensions (although it's unlikely anyone will)
- 0.11.0
  - Internal code overhaul for better long-term maintenance
  - Added `LanguageTaggish` role
  - Tags are now value types 
  - All tags automatically canonicalize upon creation.
- 0.10.0
  - Update to IANA subtag registry dated 2020-12-18
  - Added a `COERCE(Str)` method for Raku's new coercion protocol.
  - **Final update** before near total reworking of the innards for better performance, code cleanliness/maintainability, etc.
- 0.9.1
  - Updated to IANA subtag registry dated 2020-06-10
  - Temporarily removed `is DEPRECATED` from `LanguageTag::Script::type` until more extensive recoding can be done.
- 0.9.0
  - Preliminary Wildcard support
  - Updated to IANA subtag registry dated 2019-09-16
  - Language and Region enums available under Language:: and Region:: namespaces
  - Preliminary semantic support for the T extension (U support still very early)
  - Preliminary creation of POD6 documentation (both inline and separate).
    - Particularly evident for the T extension
- 0.8.5
  - Lookups available (no wildcard support yet)
- 0.8.3
   - Added initial support for parsing -t and -u extensions.
   - Added initial support for grandfathered tags
   - Fixed bug on parsing variants when no region code was present
   - Laid groundwork for various validation and canonicalization options (not fully implemented yet)

## License

All files (unless noted otherwise) can be used, modified and redistributed
under the terms of the Artistic License Version 2. Examples (in the
documentation, in tests or distributed as separate files) can be considered
public domain.

### “Unless noted otherwise”

The resources directory "cldr" contains the contents of the "bcp47" folder
of the Unicode CLDR data.  These files are copyrighted by Unicode, Inc., and
are available and distributed in accordance with
[their terms](http://www.unicode.org/copyright.html).

The resources file “language-subtag-registry” comes from the
[IANA](https://www.iana.org/assignments/language-subtag-registry).  I do not
currently distribute it because I am not aware of its exact license, but it 
will be automatically downloaded when running the parsing script.  Its data
is not needed for distribution, and so is gitignored
