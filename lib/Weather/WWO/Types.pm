use strict;
package Weather::WWO::Types;
use Moose::Util::TypeConstraints;
use Regexp::Common qw/ zip net /;

subtype 'Location', 
  as 'Str', 
  where { is_proper_location_type($_) },
  message { "Location: $_ is not of the proper type" };

coerce 'Location',
    from 'Str',
    via { s/\s+//g };

=head1 Methods

=head2 is_proper_location_type

Determine if a given location is of the proper type: an IP, zip code or lat./long.

=cut

sub is_proper_location_type {
    my $location = shift;

    # Are we an IP address (v4)
    if ( $location =~ /$RE{net}{IPv4}/ ) {
        return 'IP';
    }
    elsif ( $location =~ /$RE{zip}{US}{-extended => 'allow'}/ ) {
        return 'zip';
    }
    elsif ( is_lat_long_location($location) ) {
        return 'lat/long';
    }
    else {
        # We ought to be a City, Location set
        # Proper verification would be very useful
        return $location;
    }
}

=head2 is_lat_long_location

Given a location return true if it's a lat/long otherwise return false

=cut

sub is_lat_long_location {
    my $location = shift;

    my ( $lat, $long ) = split '\s*,\s*', $location;
    if ( is_int_or_float($lat) && is_int_or_float($long) ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 is_int_or_float

Does this thing look like a number?

=cut

sub is_int_or_float {
    my $candidate = shift;
    
    $candidate =~ m/\-?\d+(\.\d+)?/;
}

1