use Intl::BCP47;
use Test;

# NOTE: More tests should be provided here once the canonicalization of
# unicode extensions is provided.

# The first round of tests checks for already canonically ordered tags
# that need their capitalization to be checked.
# Currently, canonicalization is not implemented for -t- and -u- extensions
# so they are not modified at all, and returned as is.
is LanguageTag.new('en').canonical, 'en';
is LanguageTag.new('eN').canonical, 'en';
is LanguageTag.new('En-lAtN').canonical, 'en-Latn';
is LanguageTag.new('eN-LAtn-us-u-ca-gregory').canonical, 'en-Latn-US-u-ca-gregory';

# Extensions should be ordered alphabetically, so if a -u- tag comes first,
# it should canonically be moved to after the -t- tag.
is LanguageTag.new('en-Latn-us-u-ca-gregory-t-es-ES').canonical, 'en-Latn-US-t-es-ES-u-ca-gregory';
# but everything after an -x- tag is part of the private use, so stays in order
is LanguageTag.new('en-Latn-us-x-foo-u-ca-gregory-t-es-ES').canonical, 'en-Latn-US';

done-testing();
