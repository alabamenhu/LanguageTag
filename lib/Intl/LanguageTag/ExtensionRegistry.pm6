unit module ExtensionRegistry;

our %t-data is export(:t) = INIT {
  my %data = ();
  my @entries = %?RESOURCES<extension-t.bcp47data>.lines;
#  my @entries = slurp('../../../resources/extension-t.bcp47data').lines;
  %data{.substr(0,2)} = set .substr(3).split(',', :skip-empty) for @entries;
  %data;
}

our %u-data is export(:u) = INIT {
  my %data = ();
  my @entries = %?RESOURCES<extension-u.bcp47data>.lines;
#  my @entries = slurp('../../../resources/extension-t.bcp47data').lines;
  %data{.substr(0,2)} = set .substr(3).split(',', :skip-empty) for @entries;
  %data;
}
