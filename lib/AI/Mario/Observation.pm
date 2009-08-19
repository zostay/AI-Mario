package AI::Mario::Observation;
use Moose;

use constant observation_size => 22;

has may_jump => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
);

has is_grounded => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
);

has obstacles => (
    is       => 'ro',
    isa      => 'ArrayRef[Int]',
    required => 1,
);

sub BUILDARGS {
    my $class = shift;

    if ( @_ == 1 && ! ref $_[0] ) {
        return $class->parse_observation_message(@_);
    }
    else {
        return $class->SUPER::BUILDARGS(@_);
    }
}

sub parse_observation_message {
    my ($class, $message) = @_;
    my %args;

    my @data = split /\s+/, $message;

    # Message type, we expect this to always be "O" at this time
    my $prefix = shift @data;
    die "prefix [$prefix] is not understood\n" unless $prefix eq 'O';

    $args{may_jump}    = shift(@data) eq 'true';
    $args{is_grounded} = shift(@data) eq 'true';
    $args{obstacles}   = [ splice @data, 0, observation_size ** 2 ];

    return \%args;
}

sub show_grid {
    my $self = shift;
    
    my $obstacles = $self->obstacles;
    for my $y (0 .. observation_size - 1) {
        for my $x (0 .. observation_size - 1) {
            printf "%4d", $obstacles->[ $x + $y * observation_size ];
        }
        print "\n";
    }
    print "\n";
}
1;
