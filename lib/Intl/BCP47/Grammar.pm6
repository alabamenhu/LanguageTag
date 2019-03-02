unit grammar BCP47-Grammar;

token TOP {
  || <grandfathered> # Must check grandfathered first, because some variants are
                     # otherwise perfectly regular.
  || <langtag>
  || <privateuse>    # Check last, because x- is not otherwise a valid start.
}

token alpha     {     <[a..zA..Z]>      }
token digit     {       <[0..9]>        }
token alphanum  {   <[a..zA..Z0..9]>    }
token singleton { <[a..zA..Z0..9]-[xX]> }

token langtag {
    <language>   [$||'-']     # only obligatory element
  [ <script>     [$||'-'] ]?
  [ <region>     [$||'-'] ]?
  [ <variant>    [$||'-'] ]*
  [ <extension>  [$||'-'] ]*
  [ <privateuse> [$||'-'] ]?
}

token language {
  || <alpha> ** 2..3 <extlang>  # ISO 639 + optional extended subtag
  || <alpha> ** 4               # Not actively used, reserved.
  || <alpha> ** 5..8            # Not actively used, registered subtag.
}

token extlang {
  [ '-' <alpha> ** 3 <?after $||'-'> ] ** 0..3
}
token script {
  <alpha> ** 4
}
token region {
  || <alpha> ** 2
  || <digit> ** 3
}
token variant {
  || <alphanum> ** 5..8
  || <digit> <alphanum> ** 3
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
  | <irregular>
  |   <regular>
}

token irregular {
  || 'en-GB-oed'   || 'i-ami'       || 'i-bnn'
  || 'i-default'   || 'i-enochian'  || 'i-hak'
  || 'i-klingon'   || 'i-lux'       || 'i-mingo'
  || 'i-navajo'    || 'i-pwn'       || 'i-tao'
  || 'i-tay'       || 'i-tsu'       || 'sgn-BE-FR'
  || 'sgn-BE-NL'   || 'sgn-CH-DE'
}

token regular {
  || 'art-lojban'  || 'cel-gaulish' || 'no-bok'
  || 'no-nyn'      || 'zh-guoyu'    || 'zh-hakka'
  || 'zh-min'      || 'zh-min-nan'  || 'zh-xiang'
}
