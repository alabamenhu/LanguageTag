use Intl::BCP47;
use Test;
use Intl::BCP47::Subtag-Registry :languages;
use Intl::BCP47::Subtag-Registry :regions;
use Intl::BCP47::Subtag-Registry :variants;
use Intl::BCP47::Subtag-Registry :scripts;
# incomplete

# This ensures that the deprecated tags were separated.
nok   %regions.keys.List.any ∈ %deprecated-regions.keys.List;
nok %languages.keys.List.any ∈ %deprecated-languages.keys.List;
nok  %variants.keys.List.any ∈ %deprecated-variants.keys.List;

# These check for certain values that ought to remain stable even as the
# IANA registry is updated.
is LanguageTag.new('en-Latn-US').script.type, 'regular';
is LanguageTag.new('en-Wxyz-US').script.type, 'unregistered';
is LanguageTag.new('en-Latn-US').language.type, 'regular';
is LanguageTag.new('iw-Wxyz-US').language.type, 'deprecated'; # check for preferred he
is LanguageTag.new('wxy-Wxyz-US').language.type, 'unregistered';
is LanguageTag.new('en-Latn-US').region.type, 'regular';
is LanguageTag.new('en-Latn-BU').region.type, 'deprecated'; # check for preferred MM
is LanguageTag.new('en-Latn-WX').region.type, 'unregistered'; # check for preferred MM
is LanguageTag.new('en-Latn-UK-oxendict').variants.first.type, 'regular';
# this test cannot pass until parsing is fixed to allow variants/extensions
# without a region code
#is LanguageTag.new('ja-Latn-hepburn-heploc').variants.first.type, 'deprecated'; # check for preferred alalc97


done-testing();
