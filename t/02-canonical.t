use lib '../lib';
use Intl::BCP47;
use Test;

is LanguageTag.new('en').canonical, 'en';
is LanguageTag.new('eN').canonical, 'en';
is LanguageTag.new('En-lAtN').canonical, 'en-Latn';
is LanguageTag.new('en-Latn-us').canonical, 'en-Latn-US';
done-testing()
