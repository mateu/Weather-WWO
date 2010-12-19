package Weather::WWO;
use Moose;
use namespace::autoclean;
use LWP::Simple;
use JSON;
use Regexp::Common qw/ zip net /;

use Data::Dumper::Concise;

=head1 Synopsis

my $wwo = Weather::WWO->new( api_key        => $my_api_key,
                             zip            => 47401,
                             units          => 'F',);
my ($highs, $lows) = $wwo->forecast_temp_by_zip;

=cut

has 'api_key' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);
has 'source_URL' => (
    is         => 'ro',
    isa        => 'Any',
    lazy_build => 1,
);
has 'num_of_days' => (
    is        => 'ro',
    isa       => 'Int',
    'default' => 5,
);
has 'format' => (
    is        => 'ro',
    isa       => 'Str',
    'default' => 'json',
);
has 'zip' => (
    is  => 'ro',
    isa => 'Str',
);
has 'units' => (
    is        => 'ro',
    isa       => 'Str',
    'default' => 'F',
);
has 'data' => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);
has 'current_conditions' => (
    is         => 'ro',
    isa        => 'ArrayRef[HashRef]',
    lazy_build => 1,
);
has 'weather_forecast' => (
    is         => 'ro',
    isa        => 'ArrayRef[HashRef]',
    lazy_build => 1,
);
has 'request' => (
    is         => 'ro',
    isa        => 'ArrayRef[HashRef]',
    lazy_build => 1,
);
has 'query' => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);
has 'query_type' => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);

sub _build_query_type {
    my $self = shift;

    # Are we an IP address (v4)
    if ( $self->query =~ /$RE{net}{IPv4}/ ) {
        return 'IP';
    }
    elsif ( $self->query =~ /$RE{zip}{US}{-extended => 'no'}/ ) {
        return 'zip';
    }
    elsif ( $self->is_lat_long_query ) {
        return 'lat/long';
    }
}

sub is_lat_long_query {
    my ($self, $lat, $long) = @_;
    return;
}

sub forecast_temp_by_zip {
    my ($self) = @_;

    my $forecast = $self->weather_forecast;
    my $high_key = 'tempMax' . $self->units;
    my $low_key  = 'tempMin' . $self->units;
    my @highs    = map { $_->{$high_key} } @{$forecast};
    my @lows     = map { $_->{$low_key} } @{$forecast};

    return ( \@highs, \@lows );
}

sub _build_data {
    my $self = shift;

    my $content = get( $self->query_URL );
    die "Couldn't get URL: ", $self->query_URL unless defined $content;

    my $data_href = decode_json($content);
    return $data_href->{data};
}

sub _build_current_conditons {
    my $self = shift;
    return $self->data->{current_condition};
}

sub _build_weather_forecast {
    my $self = shift;
    warn Dumper $self->data->{weather}->[0];
    return $self->data->{weather};
}

sub _build_source_URL {
    my $self = shift;
    return 'http://www.worldweatheronline.com/feed/weather.ashx';
}

sub query_string {
    my $self = shift;

    my $query_pieces = {
        q           => $self->zip,
        format      => $self->format,
        num_of_days => $self->num_of_days,
        key         => $self->api_key,
    };

    my @query_parts =
      map { $_ . '=' . $query_pieces->{$_} } keys %{$query_pieces};
    my $query_string = join '&', @query_parts;

    return $query_string;
}

sub query_URL {
    my $self = shift;

    return $self->source_URL . '?' . $self->query_string;
}

__PACKAGE__->meta->make_immutable;
1
