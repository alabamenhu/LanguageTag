unit module Exception;

# Defined as such so that CATCH can go more or less general
# TODO: Redefine as subclass of X::Intl so that International issues can be generalized
role X::Intl::LanguageTag { }


class X::Intl::LangaugeTag::Invalid does X::Intl::LanguageTag {
    method message { "Not possible to create language tag: \n"
                     ~ "‘{$!tag}’ is an invalid tag." }
}

#| The canonicalization process cannot occur because only registered subtags
#| are allowed, except in the case of private use tags.
class X::Intl::LanguageTag::UnregisteredSubtag does X::Intl::LanguageTag {
    has $.subtag;
    has $.where;
    has $.tag;

    method message {
        ~ "Unable to canonicalize language tag {$.tag.Str}: \n"
        ~ "Subtag ‘$!subtag’ it is not a valid registered subtag for $!where"
    }
}

class X::Intl::LanguageTag::InvalidOrder does X::Intl::LanguageTag {
    enum Location <before after unknown>;

    has $.subtag;
    has $.where;
    has $.incompatible-with;

    method new (:$subtag, :$incompatible-with, :$before, :$after) { 
       self.bless(
               :$subtag,
               :where($before ?? $after ?? unknown !! before !! $after ?? after !! unknown)
               :$incompatible-with
               )
    }

    method message {
        ~ "Subtag ‘$!subtag’ cannot appear { %(before=>'before','after'=>'after'=>'in this order with'){$!where}} $!incompatible-with. \n"
        ~ "Strict mode is on.  Disable it to use any preferred order"
    }
}

class X::Intl::LanguageTag::Incompatible does X::Intl::LanguageTag {
    has $.subtag;
    has $.with;

    method message {
        ~ "Subtag ‘$!subtag’ it incompatible with {$!with.gist} \n"
                ~ "Strict mode is on.  Disable it to use non-registered subtags"
    }
}