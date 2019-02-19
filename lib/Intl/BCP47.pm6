use Intl::BCP47::Grammar;
use Intl::BCP47::Actions;
use Intl::BCP47::Classes;

class LanguageTag is export {
  has Language   $.language;
  has Script     $.script;
  has Region     $.region;
  has Variant    @.variants;
  has Extension  @.extensions;
  has PrivateUse @.privateuses;
  multi method new(Str $string, :$strict, :$autopreferred) {
    my %base = BCP47-Grammar.parse($string, :actions(BCP47-Actions)).made;
    my @privateuses = %base<privateuses><>;
    @privateuses = () if @privateuses[0].WHAT ~~ Any; # not sure why this is happening
    self.bless(
      :language(%base<language>),
      :script(%base<script>  // Script.new(:code(''))),
      :region(%base<region>  // Region.new(:code(''))),
      :variants(%base<variants><>),
      :extensions(%base<extensions><>),
      :@privateuses,
    )
  }

  multi method gist (Any:U:) { '(LanguageTag)' }
  multi method gist (Any:D:) {
    '['
    ~ $.language.code
    ~ ('-' ~ $.script.code unless $.script.type eq 'undefined')
    ~ ('-' ~ $.region.code unless $.region.type eq 'undefined')
    ~ ('…' if ?@.extensions || ?@.variants || ?@.privateuses)
    ~ ']'
  }
  method canonical (Any:D:) {
    # Warning: extensions do not currently handle canonical forms (they are
    # more complex, but will eventually be supported in the .canonical method
    # once the two defined types are subclassed (singletons -u and -t).
    # For now, extensions are alphabetized by singleton, with all subtags passed
    # through as is.
    $.language.code.lc
    ~ ('-' ~ $.script.canonical unless $.script.type eq 'undefined')
    ~ ('-' ~ $.region.canonical unless $.region.type eq 'undefined')
    ~ @.variants.map('-' ~ *.code.lc).sort.join
    ~ @.extensions.sort(*.singleton).map({'-' ~ $_.singleton ~ '-' ~ $_.subtags.join('-')}).join
    ~ ('-x' if @.privateuses)
    ~ @.privateuses.map('-' ~ *.code).join; # don't sort privateuses
  }
}
