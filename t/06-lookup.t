use Test;
use Intl::LanguageTag;

done-testing();
#`«
my @preferred = <en-UK en-US en    es-ES>.map({LanguageTag.new: $_});
my @available = <ar    en    en-US es   >.map({LanguageTag.new: $_});
is lookup-language-tag(@available, @preferred).Str, "en-US";
is lookup-language-tags(@available, @preferred)[0..2].map(*.Str).join(';'), "en-US;en;es";
                                              # ^^^^ The value returned is a lazy
                                              # list which doesn't like having
                                              # map called on it directly :-(

@preferred = <es-ES pt-PT pt-BR>.map({LanguageTag.new: $_});
@available = <en es pt-PT>.map({LanguageTag.new: $_});
is lookup-language-tag(@available, @preferred).Str, "es";
is lookup-language-tags(@available, @preferred)[0..1].map(*.Str).join(';'), "es;pt-PT";

done-testing();
»