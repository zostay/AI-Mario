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

my %obstacles = (
    '-10' => 'wall-hard',
    '-11' => 'wall-soft',
      '1' => 'mario',
      '2' => 'bad_guys-jump-shoot',
      '9' => 'bad_guys-shoot',
     '20' => 'wall-hard-metal',
     '16' => 'wall-hard-brick',
     '21' => 'wall-hard-question',
     '25' => 'weapon-fireball',
);

sub obstacle_vectors {
    my $self = shift;

    my @vectors;
    my $center  = observation_size / 2;
    my $grid = $self->obstacles;

    for my $x (0 .. observation_size - 1) {
        for my $y (0 .. observation_size - 1) {
            my $pixel = $grid->[ $x + $y * observation_size ];
            next unless defined $obstacles{ $pixel };

            my $type = $obstacles{ $pixel };
            my $dx   = $x - $center;
            my $dy   = $y - $center;
            my $dv   = sqrt( $dx * $dx + $dy * $dy );

            push @vectors, {
                in_front   => $dx >= 0,
                distance   => $dv,
                distance_x => $dx,
                distance_y => $dy,
                type       => $type,
            };
        }
    }

    # Things near in front first, then near in back
    return [ sort { $b->{in_front} <=> $a->{in_front} 
                 || $a->{distance} <=> $b->{distance} } @vectors ];
}
1;
