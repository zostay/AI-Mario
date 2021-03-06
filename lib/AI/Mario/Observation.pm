package AI::Mario::Observation;
use Moose;

use Scalar::Util qw( weaken );

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
      '1' => 'guys-good-mario',
      '2' => 'guys-bad-jump-shoot',
      '9' => 'guys-bad-shoot',
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
    my (@floors, @ceilings, @front_walls, @back_walls, @bad_guys, %rises, %drops, %pits);

    my @grid;
    my $grid = sub { $grid[view_extent + $_[0]][view_extent - $_[1]] ||= {} };

    for my $y (reverse - view_extent .. view_extent - 1) {
        for my $x (- view_extent .. view_extent - 1) {
            my $type = $self->get_obstacle($x, $y);

            print "MARIO $x $y\n" if $type eq 'mario';

            # we have a floor
            my $up_type = $self->get_obstacle($x, $y + 1);
            if ($y < view_extent - 2 and $type =~ /wall/ and $up_type !~ /wall/) {
                if ($x > - view_extent and $grid->($x - 1, $y)->{floor}) {
                    $grid->($x, $y)->{floor} = $grid->($x - 1, $y)->{floor};
                    $grid->($x, $y)->{floor}{right} = $x;
                }

                else {
                    my $new_floor = {
                        left  => $x,
                        right => $x,
                        top   => $y,
                    };
                    push @floors, $new_floor;
                    $grid->($x, $y)->{floor} = $new_floor;
                }
            }

            # we have a ceiling
            my $down_type = $self->get_obstacle($x, $y - 1);
            if ($y > - view_extent and $type =~ /hard/ and $down_type !~ /hard/) {
                if ($x > - view_extent and $grid->($x - 1, $y)->{ceiling}) {
                    $grid->($x, $y)->{ceiling} = $grid->($x - 1, $y)->{ceilng};
                    $grid->($x, $y)->{ceiling}{right} = $x;
                }

                else {
                    my $new_ceiling = {
                        left   => $x,
                        right  => $x,
                        bottom => $y,
                    };
                    push @ceilings, $new_ceiling;
                    $grid->($x, $y)->{ceiling} = $new_ceiling;
                }
            }

            # we have a front wall
            my $left_type = $self->get_obstacle($x - 1, $y);
            if ($x > - view_extent and $type =~ /hard/ and $left_type !~ /hard/) {
                if ($y < view_extent - 1 and $grid->($x, $y - 1)->{front_wall}) {
                    $grid->($x, $y)->{front_wall} = $grid->($x, $y - 1)->{front_wall};
                    $grid->($x, $y)->{front_wall}{bottom} = $y;
                }

                else {
                    my $new_front_wall = {
                        left   => $x,
                        top    => $y,
                        bottom => $y,
                    };
                    push @front_walls, $new_front_wall;
                    $grid->($x, $y)->{front_wall} = $new_front_wall;
                }
            }

            # we have a back wall
            my $right_type = $self->get_obstacle($x - 1, $y);
            if ($x < view_extent - 2 and $type =~ /hard/ and $right_type !~ /hard/) {
                if ($y < view_extent - 1 and $grid->($x, $y - 1)->{back_wall}) {
                    $grid->($x, $y)->{back_wall} = $grid->($x, $y - 1)->{back_wall};
                    $grid->($x, $y)->{back_wall}{bottom} = $y;
                }

                else {
                    my $new_back_wall = {
                        right  => $x,
                        top    => $y,
                        bottom => $y,
                    };
                    push @back_walls, $new_back_wall;
                    $grid->($x, $y)->{back_wall} = $new_back_wall;
                }
            }

            if ($type =~ /bad/) {
                push @bad_guys, {
                    x          => $x,
                    y          => $y,
                    jump_kill  => $type =~ /jump/,
                    shoot_kill => $type =~ /shoot/,
                };
            }
        }
    }

    # Look for some more interesting information
    for my $floor (@floors) {
        if ($floor->{left} <= 0 and $floor->{right} >= 0) {
            $floor->{below_mario} = $floor->{top} < 0;
            $floor->{above_mario} = $floor->{top} > 0;
            $floor->{standing_on} = $floor->{top} = -1 and $self->is_grounded;
        }

        else {
            $floor->{below_mario} = $floor->{above_mario} = $floor->{standing_on} = '';
        }
    }

    # Eliminate ceilings that are below us, who cares?
    @ceilings = grep { $_->{bottom} > 0 } @ceilings;

    # Look for some more interesting information
    for my $ceiling (@ceilings) {
        $ceiling->{above_mario} = $ceiling->{bottom} >  0
                               && $ceiling->{left}   <= 0 
                               && $ceiling->{right}  >= 0;
    }

    # Look for some more interesting information
    for my $wall (@front_walls) {
        if ($wall->{left} < view_extent - 1 and $grid->($wall->{left} + 1, $wall->{top})->{floor}) {
            $wall->{floor_rise} = 1;
            $wall->{end} = $grid->($wall->{left} + 1, $wall->{top})->{floor};
            $wall->{end}{begin} = $wall;
            weaken($wall->{end});
            weaken($wall->{end}{begin});
        }
        if ($wall->{left} > - view_extent and $wall->{bottom} > - view_extent and $grid->($wall->{left} - 1, $wall->{bottom} - 1)->{floor}) {
            $wall->{floor_rise} = 1;
            $wall->{begin} = $grid->($wall->{left} - 1, $wall->{bottom} - 1)->{floor};
            $wall->{begin}{end} = $wall;
            weaken($wall->{begin});
            weaken($wall->{begin}{end});
        }

        if ($wall->{left} < view_extent - 1 and $grid->($wall->{left} + 1, $wall->{bottom})->{ceiling}) {
            $wall->{ceiling_drop} = 1;
        }
        if ($wall->{left} > - view_extent and $wall->{top} < view_extent - 1 and $grid->($wall->{left} - 1, $wall->{top} + 1)->{ceiling}) {
            $wall->{ceiling_drop} = 1;
        }
    }

    # Look for some more interesting information
    for my $wall (@back_walls) {
        if ($wall->{right} < view_extent - 1 and $grid->($wall->{right} + 1, $wall->{top})->{floor}) {
            $wall->{floor_drop} = 1;
            $wall->{end} = $grid->($wall->{right} + 1, $wall->{top})->{floor};
            $wall->{end}{begin} = $wall;
            weaken($wall->{end});
            weaken($wall->{end}{begin});
        }
        if ($wall->{right} < view_extent - 1 and $wall->{bottom} > - view_extent and $grid->($wall->{right} + 1, $wall->{bottom} - 1)->{floor}) {
            $wall->{floor_drop} = 1;
            $wall->{begin} = $grid->($wall->{right} + 1, $wall->{bottom} - 1)->{floor};
            $wall->{begin}{end} = $wall;
            weaken($wall->{end});
            weaken($wall->{end}{begin});
        }

        if ($wall->{right} > - view_extent and $grid->($wall->{right} - 1, $wall->{bottom})->{ceiling}) {
            $wall->{ceiling_rise} = 1;
        }
        if ($wall->{right} < view_extent - 1 and $wall->{top} < view_extent - 1 and $grid->($wall->{right} + 1, $wall->{top} + 1)->{ceiling}) {
            $wall->{ceiling_rise} = 1;
        }
    }

    for my $floor (@floors) {
        if ($floor->{begin}) {
            $drops{$floor->{left}}++ if $floor->{begin}{floor_drop};
            $rises{$floor->{left}}++ if $floor->{begin}{floor_rise};
        }
        if ($floor->{end}) {
            $drops{$floor->{right}}++ if $floor->{end}{floor_drop};
            $rises{$floor->{right}}++ if $floor->{end}{floor_rise};
            $pits{$floor->{right}}++  if $floor->{end}{floor_drop} and not $floor->{end}{end};
        }

        if ($floor->{left} == - view_extent) {
            $floor->{begin} = 'EDGE';
        }
        if ($floor->{right} == view_extent - 1) {
            $floor->{end} = 'EGDE';
        }
    }

    my $result = {
        floors      => \@floors,
        ceilings    => \@ceilings,
        front_walls => \@front_walls,
        back_walls  => \@back_walls,
        bad_guys    => \@bad_guys,
        rises       => [ sort keys %rises ],
        drops       => [ sort keys %drops ],
        pits        => [ sort keys %pits ],
    };

    return $result;
}

1;
