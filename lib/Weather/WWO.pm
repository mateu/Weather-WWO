package Weather::WWO;
use Moose;
use namespace::autoclean;
use Weather::WWO::Types;
use LWP::Simple;
use JSON;

use Data::Dumper::Concise;

our $VERSION = '0.02';

=head1 Name

Weather::WWO - API to World Weather Online

=head1 Synopsis

    Get the 5-day weather forecast:
    
    my $wwo = Weather::WWO->new( api_key           => $your_api_key,
                                 location          => $location,
                                 temperature_units => 'F',
                                 wind_units        => 'Miles');
                                 
    Where the $location can be:
    * zip code
    * IP address
    * latitude,longitude
    
    my ($highs, $lows) = $wwo->forecast_temperatures;

NOTE: I<api_key> and I<location> are required parameters to C<new()>

=cut

has 'api_key' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);
has 'location' => (
    is       => 'rw',
    isa      => 'Location',
    required => 1,
    writer   => 'set_location',
);
has 'num_of_days' => (
    is        => 'ro',
    isa       => 'Int',
    'default' => 5,
);

# We are only using the JSON format
has 'format' => (
    is        => 'ro',
    isa       => 'Str',
    'default' => 'json',
    init_arg  => undef,
);
has 'temperature_units' => (
    is        => 'ro',
    isa       => 'Str',
    'default' => 'C',
);
has 'wind_units' => (
    is        => 'ro',
    isa       => 'Str',
    'default' => 'Kmph',
);
has 'data' => (
    is         => 'rw',
    isa        => 'HashRef',
    lazy_build => 1,
);
has 'source_URL' => (
    is         => 'ro',
    isa        => 'Any',
    lazy_build => 1,
);

# When the location changes, we want to clear the data to insure a new data fetch will happen.
# We need this since data is lazily built, and we used a distinct name for the writer
# so we only clear data when we set the location anytime after initial object construction.
after 'set_location' => sub {
    my $self = shift;
    $self->clear_data;
};

=head1 Methods

=head2 forecast_temperatures

Get the high and low temperatures for the number of days specified.

    Returns: Array of two ArrayRefs being the high and low temperatures
    Example: my ($highs, $lows) = $wwo->forecast_temperaures;

=cut

sub forecast_temperatures {
    my $self = shift;
    return ($self->highs, $self->lows);
}

=head2 highs

Get an ArrayRef[Int] of the forecasted high temperatures.

=cut

sub highs {
    my $self = shift;
    
    my $high_key = 'tempMax' . $self->temperature_units;
    return $self->get_forecast_data_by_key($high_key);
}

=head2 lows

Get an ArrayRef[Int] of the forecasted low temperatures.

=cut

sub lows {
    my $self = shift;
    
    my $low_key = 'tempMin' . $self->temperature_units;
    return $self->get_forecast_data_by_key($low_key);
}

=head2 winds

Get an ArrayRef[Int] of the forecasted wind speeds.

=cut

sub winds {
    my $self = shift;
    
    my $wind_key = 'windspeed' . $self->wind_units;
    return $self->get_forecast_data_by_key($wind_key);
}

=head2 get_forecast_data_by_key

Get the values for a single forecast metric.
Examples are: tempMinF, tempMaxC, windspeedMiles etc...

NOTE: One can dump the data attribute to see 
the exact data structure and keys available.

=cut

sub get_forecast_data_by_key {
    my ($self, $key) = @_;
    
    return [ map { $_->{$key} } @{$self->weather_forecast} ];
}

=head2 query_string

Construct the query string based on object attributes.

=cut

sub query_string {
    my $self = shift;

    my $query_pieces = {
        q           => $self->location,
        format      => $self->format,
        num_of_days => $self->num_of_days,
        key         => $self->api_key,
    };

    my @query_parts =
      map { $_ . '=' . $query_pieces->{$_} } keys %{$query_pieces};
    my $query_string = join '&', @query_parts;

    return $query_string;
}

=head2 query_URL

Construct the to URL to get by putting the source URL and query_string together.

=cut

sub query_URL {
    my $self = shift;
    return $self->source_URL . '?' . $self->query_string;
}

=head2 current_conditions

The current conditions data structure.

=cut

sub current_conditons {
    my $self = shift;
    return $self->data->{current_condition};
}

=head2 weather_forecast

The weather forecast data structure.

=cut

sub weather_forecast {
    my $self = shift;
    return $self->data->{weather};
}

=head2 request

Information about the request.

=cut

sub request {
    my $self = shift;
    return $self->data->{request};
}

# Builders

sub _build_data {
    my $self = shift;

    my $content = get( $self->query_URL );
    die "Couldn't get URL: ", $self->query_URL unless defined $content;

    my $data_href = decode_json($content);

    return $data_href->{data};
}

sub _build_source_URL {
    my $self = shift;
    return 'http://www.worldweatheronline.com/feed/weather.ashx';
}

__PACKAGE__->meta->make_immutable;
1

__END__

=head1 Authors

Mateu Hunter C<hunter@missoula.org>

=head1 Copyright

Copyright 2010, Mateu Hunter

=head1 License

You may distribute this code under the same terms as Perl itself.

=cut
