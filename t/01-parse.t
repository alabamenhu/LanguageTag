use Intl::LanguageTag::Grammar;
use Test;

# these test basic styles of filtering, for what should be fairly easy
ok  BCP47-Grammar.parse('en', :args(\(:filter)));
ok  BCP47-Grammar.parse('en-Latn');
ok  BCP47-Grammar.parse('en-Latn-US');
ok  BCP47-Grammar.parse('en-US');
ok  BCP47-Grammar.parse('en-Latn-US-ukoed');
ok  BCP47-Grammar.parse('en-US-ukoed');
ok  BCP47-Grammar.parse('en-Latn-US-ukoed-t-es-ES');
ok  BCP47-Grammar.parse('en-US-ukoed-t-es-ES');
ok  BCP47-Grammar.parse('en-t-es-ES');
ok  BCP47-Grammar.parse('en-Latn-t-es-ES');
ok  BCP47-Grammar.parse('en-Latn-US-ukoed-t-es-ES-x-foo-bar');
ok  BCP47-Grammar.parse('en-Latn-us-u-ca-gregory'); # gregory meets the 8 char limit
ok  BCP47-Grammar.parse('en-u-ca-gregory');
nok BCP47-Grammar.parse('en-Latn-us-u-ca-gregorian'); # gregorian does not

# However, for some reason, when there is no regional tag, the variants don't
# get picked up.  Not sure the best way to solve this.
ok BCP47-Grammar.parse('en-Latn-ukoed');
ok BCP47-Grammar.parse('en-Latn-ukoed-t-es-ES');
ok BCP47-Grammar.parse('en-ukoed');
ok BCP47-Grammar.parse('en-ukoed-t-es-ES');
# test with EN-ShAw-cA-newFoUnD-u-ca-gregory-t-he-Arab-ES-1800-x-foo

done-testing();
