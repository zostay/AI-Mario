package AI::Mario::Fitness;
use Moose;

has mario_status => (
    is        => 'ro',
    isa       => 'Bool',
    required  => 1,
);

has distance_passed => (
    is        => 'ro',
    isa       => 'Num',
    required  => 1,
);

has time_left => (
    is        => 'ro',
    isa       => 'Int',
    required  => 1,
);

has mario_mode => (
    is        => 'ro',
    isa       => 'Int',
    required  => 1,
);

has gained_coins => (
    is        => 'ro',
    isa       => 'Int',
    required  => 1,
);

sub BUILDARGS {
    my $class = shift;

    if ( @_ == 1 && ! ref $_[0] ) {
        return $class->parse_fitness_message(@_);
    }
    else {
        return $class->SUPER::BUILDARGS(@_);
    }
}

sub parse_fitness_message {
    my ($self, $message) = @_;
    my %args;

    my @data = split /\s+/, $message;
    
    my $prefix = shift @data;
    die "prefix [$prefix] is not understood\n" unless $prefix eq 'FIT';

    @args{ qw( 
        mario_status distance_passed time_left mario_mode gained_coins
    ) } = @data;

    return \%args;
}

sub mario_status_name {
    my $self = shift;
    return $self->mario_status ? 'WIN' : 'LOSS';
}

my @mario_mode_name = ( 'Little Mario', 'Big Mario', 'Fire Mario' );
sub mario_mode_name {
    my $self = shift;
    return $mario_mode_name[ $self->mario_mode ];
}

sub report {
    my $self = shift;

    my $hr = ('-' x 50);
    return qq{$hr
Mario Status:    @{[$self->mario_status_name]}
Distance Passed: @{[$self->distance_passed]}
Time Left:       @{[$self->time_left]}
Mario Mode:      @{[$self->mario_mode_name]}
Gained Coins:    @{[$self->gained_coins]}
$hr
};
}

1;
