use Intl::BCP47::Grammar;
use Test;

ok BCP47-Grammar.parse('en');
ok BCP47-Grammar.parse('en-Latn');
ok BCP47-Grammar.parse('en-Latn-US');
ok BCP47-Grammar.parse('en-Latn-US-ukoed');
ok BCP47-Grammar.parse('en-Latn-US-ukoed-t-es-ES');
ok BCP47-Grammar.parse('en-Latn-US-ukoed-t-es-ES-x-foo-bar');
done-testing()
