unit module Subtag-Registry;

our %languages is export(:languages) = BEGIN {
  my %data = ();
  my @entries = %?RESOURCES<languages.bcp47data>.slurp.lines;
  for @entries -> $entry {
    $entry ~~ /
     (<[a..zA..Z0..9-]>+) ','   # language code
     (<[a..zA..Z0..9-]>*) ','   # supressed script
     (<[a..zA..Z0..9-]>*) ','   # macrolanguage
     (<[a..zA..Z0..9-]>*)       # preferred code
     (  '!'?  )                 # is deprecated
    /;

  %data{$0.Str} = ($1.Str,$2.Str,$3.Str) unless $4.Str eq '!'
  }
  %data;
}

our %deprecated-languages is export(:languages) = BEGIN {
  my %data = ();
  my @entries = %?RESOURCES<languages.bcp47data>.slurp.lines;
  for @entries -> $entry {
    $entry ~~ /
     (<[a..zA..Z0..9-]>+) ','   # language code
     (<[a..zA..Z0..9-]>*) ','   # supressed script
     (<[a..zA..Z0..9-]>*) ','   # macrolanguage
     (<[a..zA..Z0..9-]>*)       # preferred code
     (  '!'?  )                 # is deprecated
    /;
    %data{$0.Str} = ($1.Str,$2.Str,$3.Str) if $4.Str eq '!'
  }
  %data;
}

our %grandfathered-languages is export(:old-languages) = BEGIN {
  my %data = ();
  my @entries = %?RESOURCES<languages.bcp47data>.slurp.lines;
  for @entries -> $entry {
    $entry ~~ /
     (<[a..zA..Z0..9-]>+) ','   # language tag
     (<[a..zA..Z0..9-]>*)       # preferred tag
     (  '!'?  )                 # is deprecated
    /;
    %data{$0.Str} = ($1.Str, $2.Str eq '!')
  }
  %data;
}

our %redundant-languages is export(:old-languages) = BEGIN {
  my %data = ();
  my @entries = %?RESOURCES<languages.bcp47data>.slurp.lines;
  for @entries -> $entry {
    $entry ~~ /
     (<[a..zA..Z0..9-]>+) ','   # language tag
     (<[a..zA..Z0..9-]>*)       # preferred tag
     (  '!'?  )                 # is deprecated
    /;
    %data{$0.Str} = ($1.Str, $2.Str eq '!')
  }
  %data;
}

our %regions is export(:regions) = BEGIN {
  my %data = ();
  my @entries = %?RESOURCES<regions.bcp47data>.slurp.lines;
  for @entries -> $entry {
    $entry ~~ /
     (<[a..zA..Z0..9-]>+) ','   # region code
     (<[a..zA..Z0..9-]>*)       # preferred
     (  '!'?  )                 # is deprecated
    /;
    %data{$0.Str} = $1.Str unless $2.Str eq '!'
  }
  %data;
}

our %deprecated-regions is export(:regions) = BEGIN {
  my %data = ();
  my @entries = %?RESOURCES<regions.bcp47data>.slurp.lines;
  for @entries -> $entry {
    $entry ~~ /
     (<[a..zA..Z0..9-]>+) ','   # region code
     (<[a..zA..Z0..9-]>*)       # preferred
     (  '!'?  )                 # is deprecated
    /;
    %data{$0.Str} = $1.Str if $2.Str eq '!'
  }
  %data;
}

our %scripts is export(:scripts) = BEGIN {
  my %data = ();
  my @entries = %?RESOURCES<scripts.bcp47data>.slurp.lines;
  for @entries -> $entry {
    $entry ~~ /
     (<[a..zA..Z0..9-]>*)       # code
    /;
    %data{$0.Str} = '';
  }
  %data;
}

our %variants is export(:variants) = BEGIN {
  my %data = ();
  my @entries = %?RESOURCES<variants.bcp47data>.slurp.lines;
  for @entries -> $entry {
    $entry ~~ /
    (<[a..zA..Z0..9-]>+) ','   # code
    (<[a..zA..Z0..9-]>*) ','   # prefix
    (<[a..zA..Z0..9-]>*)       # preferred
    (  '!'?  )                 # is deprecated
    /;
    %data{$0.Str} = ($1.Str,$2.Str) unless $3.Str eq '!';
  }
  %data;
}

our %deprecated-variants is export(:variants) = BEGIN {
  my %data = ();
  my @entries = %?RESOURCES<variants.bcp47data>.slurp.lines;
  for @entries -> $entry {
    $entry ~~ /
    (<[a..zA..Z0..9-]>+) ','   # code
    (<[a..zA..Z0..9-]>*) ','   # prefix
    (<[a..zA..Z0..9-]>*)       # preferred
    (  '!'?  )                 # is deprecated
    /;
    %data{$0.Str} = ($1.Str,$2.Str) if $3.Str eq '!';
  }
  %data;
}
