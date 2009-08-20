package AI::Mario::Agent::NotBlind;
use Moose;

with 'AI::Mario::Agent';

has jump_duration => (
    is       => 'rw',
    isa      => 'Int',
    required => 1,
    default  => 0,
);

sub name { 'NotBlind' }

sub reset {}

sub update {
    my ($self, $o) = @_;

    my $summary = $o->obstacle_summary;
    my @altitude_changes = (@{ $summary->{rises} }, @{ $summary->{drops} });
    my ($next_change) = grep { $_ > 0 } sort @altitude_changes;

    $self->right(1);

    if ($self->jump_duration == 0 and defined $next_change and $next_change <= 2) {
        print "Jumping over wall\n";
        $self->jump_duration(10);
    }

    if (@{ $summary->{bad_guys} }) {
        print "Shoot\n";
        $self->run( $self->run ? 0 : 1 );

        if ($self->jump_duration == 0) {
            $self->jump_duration(10);
        }
    }

    if ($self->jump_duration > 0) {
        $self->jump(1);
        $self->jump_duration( $self->jump_duration - 1 );
        $self->jump(0) if $self->jump_duration <= 0;
    }
}

sub fitness {}

1;
