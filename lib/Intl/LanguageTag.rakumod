sub EXPORT(*@types) {
    use Intl::LanguageTag::BCP47 <tools>;
    my %export;
    %export<LanguageTag>                                = LanguageTag::BCP47;
    %export<LanguageTag::Extension::TransformedContent> = TransformedContent    if @types.any eq 'ext-t';
    %export<LanguageTag::TransformedContent>            = TransformedContent    if @types.any eq 't';
    %export<LanguageTag::Extension::UnicodeLocale>      = UnicodeLocale         if @types.any eq 'ext-u';
    %export<LanguageTag::UnicodeLocale>                 = UnicodeLocale         if @types.any eq 'u';
    %export<&filter-language-tags>                      = &filter-language-tags if @types.any eq 'tools';
    %export<&lookup-language-tags>                      = &lookup-language-tags if @types.any eq 'tools';
    %export.Map
}