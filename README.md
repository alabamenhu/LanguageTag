# Intl::LanguageTag

**Warning: v0.11.0 is *mostly* backwards compatible.  The following is not currently supported from v0.10-:**
  * Heavy extensions introspection
  * Creation by means other than a `Str`
  * Enums
  * Grandfathered / legacy tags
  * `LanguageTagFilter` objects
  
Support for all will be addressed in forthcoming updates, however extensions introspection may differ in structure.

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

Note that language tags are canonicalized upon creation.  
This is done in accordance with BCP 47, RFC 6067, RFC 6497, and TR 35 and helps to guarantee value typing mechanics.

## Which to `use`
Most of the time, `use Intl::LanguageTag` is what you will want (the BCP-47 tag type is set as the default for a reason).
Prefer `use Intl::LanguageTag::BCP-47` when interacting with other language tag types in the same scope to avoid a symbol collision.

## Features

Everything is value typed!  This means you can easily use them in sets, bags, and mixes and routines like `unique` will operate as you'd expect.

Once you've created a language tag, you have the following simple methods to introspect it.

  * **`.language`**  
  The language code.
  * **`.script`**  
  The script used, will be omitted if the same as the default script.
  * **`.region`**  
  The region code
  * **`.variants`**  
  The variant codes. This object provides positional access to its subtags.
  * **`.extensions`**  
  Any extensions.  This object provides hashy access (currently recognizing `<t>` and `<u>`)
  * **`.private-use`**  
  Any private use tags. This object provides positional access to its subtags.
  
Each of the above will stringify into the exact code, but also have additional methods.
For instance, `.language.default-script` tells you what the default script for the language is.
These will be documented more in a future release.

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
  * Extlang and grandfathered tag support (via automatic canonicalization)
  * Better introspection of extensions U / T
  * Improve filtering by enabling wildcards in matches.
  * More exhaustive test files

## Version history
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

The resources file “language-subtag-registry” is comes from the
[IANA](https://www.iana.org/assignments/language-subtag-registry).  I do not
currently distribute it because I am not aware of its exact license, but it 
will be automatically downloaded when running the parsing script.  Its data
is not needed for distribution, and so is gitignored
