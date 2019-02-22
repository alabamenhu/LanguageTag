unit grammar BCP47-Filter-Grammar;

# This is the same grammar as the main Grammar.pm6, with one key difference:
# wildcards (*) are accepted in the language, script, region, or any variant
# slot.  Per RFC4647, the only one of these that is truly significant is the
# language position, because an EMPTY slot is considered the same as a wildcard
# (in other words, 'de-DE' and 'de-*-DE-*' will generate identically filters).
# The length of the tags means that, but for the first one, all can be
# unambiguously determined (Lang = 4 chars, Region = 2, subtags = 5-8).
#
# Because extensions and privateuse are considered automatically non-matching,
# they are checked for but if they match, they will cause a failure.  It may
# be possible to allow for some special filter syntax later.

token TOP (:$*filter = False){
  || <langtag>
  || <privateuse>
  || <grandfathered>
}

token alpha     {     <[a..zA..Z]>      }
token digit     {       <[0..9]>        }
token alphanum  { <alpha>   |   <digit> }
token singleton { <[a..zA..Z0..9]-[xX]> }
token wildcard  {          '*'          }

token langtag {
  <language>
  [ '-' <script>     ]?
  [ '-' <region>     ]?
  [ '-' <variant>    ]*
  [ '-' <extension>  ]* # These will match, but they will cause a failure.
  [ '-' <privateuse> ]* # Failure is called in Filter-Actions.pm6
}

token language {
  || [ <alpha> ** 2..3 ['-' <extlang>]?]  # ISO 639 + optional extended subtag
  || <alpha> ** 4                         # reserved for future use
  || <alpha> ** 5..8                      # registered language subtag
  || <wildcard>
}
token extlang {
  <alpha> ** 3
  ['-' <alpha> ** 3] 0 ** 2
}
token script {
  || <alpha> ** 4
  || <wildcard>
}
token region {
  || <alpha> ** 2
  || <digit> ** 3
  || <wildcard>
}
token variant {
  || <digit> ** 4
  || <alphanum> ** 5..8
  || <digit> <alphanum> ** 3
  || <wildcard>
}
token extension {
  <singleton>
  ['-' (<alphanum> ** 2..8)]+
}
token privateuse {
  <[xX]> ['-' <privateusetag>]+
}
token privateusetag {
  <alphanum> ** 1..8
}

token grandfathered {
  || <irregular>
  ||   <regular>
}
token irregular {
  | 'en-GB-oed'   | 'i-ami'       | 'i-bnn'
  | 'i-default'   | 'i-enochian'  | 'i-hak'
  | 'i-klingon'   | 'i-lux'       | 'i-mingo'
  | 'i-navajo'    | 'i-pwn'       | 'i-tao'
  | 'i-tay'       | 'i-tsu'       | 'sgn-BE-FR'
  | 'sgn-BE-NL'   | 'sgn-CH-DE'
}
token regular {
  | 'art-lojban'  | 'cel-gaulish' | 'no-bok'
  | 'no-nyn'      | 'zh-guoyu'    | 'zh-hakka'
  | 'zh-min'      | 'zh-min-nan'  | 'zh-xiang'
}
