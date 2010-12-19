use strict;
use warnings;
use Test::More;
use Weather::WWO;
use Data::Dumper::Concise;

my $api_key = 'faa2489de6022450101712';
my $wwo     = Weather::WWO->new(
    api_key => $api_key,
    zip => '59802',
);
my ( $highs, $lows ) = $wwo->forecast_temp_by_zip;
print Dumper $highs;
print Dumper $lows;

done_testing();
