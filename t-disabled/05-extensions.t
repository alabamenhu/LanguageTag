use lib 'lib';
use Intl::LanguageTag;
use Test;

#`««
This testing is still preliminary and should not be used until the tag semantic structure is
finalized
say my $a = LanguageTag.new("en-t-jp-UK-s0-ascii-h0-es-Latn-ES-x0-fia-asdij-asdioj-b0-asd");
my $t = $a.extensions<t>;
say $t.singleton;
say $t.subtags;
say $t.fields;
say $t.hybrid-locale;
say $t.source;
say $t.origin;
say $a.canonical;
»»

done-testing();
