use Intl::LanguageTag;
use Test;
use Intl::LanguageTag::Filter-Grammar;

# Fix once subs are reenabled

                     # should match filters A B C D E F
my @tags-init = ('de-DE',                #  a b c
                 'de-de',                #  a b
                 'de-Latn-DE',           #  a b c d
                 'de-Latf-DE',           #  a b c
                 'de-DE-x-goethe',       #  a b c
                 'de-Latn-DE-1996',      #  a b c d   f
                 'de-Deva-DE',           #  a b c   e
                 'de',                   #    b
                 'de-x-DE',              #    b c
                 'de-Deva');             #    b     e
my @tags = do for @tags-init { LanguageTag.new: $_ }

ok my $filter-a = LanguageTagFilter.new('de-DE');
ok my $filter-b = LanguageTag.new('de').LanguageTagFilter; # alternate formation
ok my $filter-c = LanguageTagFilter.new('*-DE');
ok my $filter-d = LanguageTagFilter.new('*-Latn');
ok my $filter-e = LanguageTagFilter.new('*-Deva');

# There seems to be a bug in the Grammar that prevents this from matching.
# This is common to both filters are regular tags.
# my $filter-f = LanguageTagFilter.new('*-1996');
# ok LanguageTagFilter.new('*-1996');


# These should not make valid filters and die.
dies-ok {LanguageTagFilter.new('Latn')};
dies-ok {LanguageTagFilter.new('de-DE-x-goethe')};

is ([+] do for @tags { $_ ~~ $filter-a }), 7;  # begin with de, have DE region
is ([+] do for @tags { $_ ~~ $filter-b }), 10; # all tags begin with de
is ([+] do for @tags { $_ ~~ $filter-c }), 7;  # any language, have DE region
is +filter-language-tags(@tags,$filter-c), 7;  # any language, have DE region
is ([+] do for @tags { $_ ~~ $filter-d }), 2;  # any explicit Latn
is ([+] do for @tags { $_ ~~ $filter-e }), 2;  # any explicit Latn
# is ([+] do for @tags { $_ ~~ $filter-f }), 1;  # any 1996 orthography, buggy
done-testing();
