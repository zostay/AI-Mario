package AI::Mario::Observation;
use Moose;

use constant observation_size => 22;
use constant view_extent      => 11;

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

=head2 obstacle_summary

Builds and obstacle summary and then returns a hash of lists describing everything on the screen succinctly.

The keys are as follows:

=over

=item floors 

This is a list of floors currently visible. Any horizontal surface upon which Mario can stand is a floor. The floors are pre-sorted with the floor directly under Mario listed first (either the one he's standing on or the one he's jumping over). Then, all the floors right of Mario are listed sorted left-to-right, bottom-to-top. Then, all the floors left of Mario are listed sorted right-to-left, bottom-to-top.

Each floor may include the following:

  {
      on_floor     => 0|1, # is Mario on this floor
      above_floor  => 0|1, # is Mario above this floor
      below_floor  => 0|1, # is Mario below this floor
      is_left      => 0|1, # is Mario left of this floor
      is_right     => 0|1, # is Mario right of this floor
      left         => -11..11, # delta to reach the right edge of this floor
      right        => -11..11, # delta to reach the left edge of this floor
      top          => -11..11, # delta to reach the top of this floor
  }

=item ceilings 

This is the list of visible ceilings. I ceiling is any horizontal service Mario may bump when jumping, including bricks, question blocks, and hard floors. The ceiling directly above Mario is listed first, then any ceilings to Mario's right ordered left-to-right, top-to-bottom, then any ceilings to Marios left ordered right-to-left, top-to-bottom.

Each ceiling may include the followign:

  {
      above_ce

=item walls 

=item bad_guys 

=item rises 

=item drops 

=back

=cut


sub get_obstacle {
    my ($self, $x, $y) = @_;
    no warnings 'uninitialized'; # I know, shut up

    return '' if $x < - view_extent or $x >= view_extent 
              or $y < - view_extent or $y >= view_extent;
    return $obstacles{ $self->obstacles->[ 
        ($x + view_extent) + (view_extent - $y) * observation_size 
    ] } || '';
}

sub obstacle_summary {
    my $self = shift;
    my (@floors, @ceilings, @walls, @bad_guys, @rises, @drops, @pits);

    my @grid;
    for my $y (reverse - view_extent .. view_extent - 2) {
        for my $x (- view_extent .. view_extent - 1) {
            my $type = $self->get_obstacle($x, $y);

            print "MARIO $x $y\n" if $type eq 'mario';

            next unless $type =~ /hard/;

            # we have a floor
            my $up_type = $self->get_obstacle($x, $y + 1);
            if ($up_type !~ /wall/) {
                if ($x > -view_extent and $grid[view_extent + $x - 1][view_extent - $y]{floor}) {
                    $grid[view_extent + $x][view_extent - $y]{floor} = $grid[view_extent + $x - 1][view_extent - $y]{floor};
                    $grid[view_extent + $x][view_extent - $y]{floor}{right} = $x;
                }

                else {
                    my $new_floor = {
                        left  => $x,
                        right => $x,
                        top   => $y,
                    };
                    push @floors, $new_floor;
                    $grid[$x + view_extent][view_extent - $y]{floor} = $new_floor;
                }
            }
        }
    }

    use Data::Dumper;
    print Dumper(\@floors);
#    return {
#        floors   => \@floors,
#        ceilings => \@ceilings,
#        walls    => \@walls,
#        bad_guys => \@bad_guys,
#        rises    => \@rises,
#        drops    => \@drops,
#    };
}

1;
