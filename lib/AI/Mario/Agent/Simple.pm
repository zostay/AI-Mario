package AI::Mario::Agent::Simple;
use Moose;

with 'AI::Mario::Agent';

has jump_duration => (
    is       => 'rw',
    isa      => 'Int',
    required => 1,
    default  => 0,
);

sub name { 'Simple' }

sub reset {}

sub update {
    my ($self, $o) = @_;

    $self->right(1);
    $self->run(1);

    $self->jump_duration( $self->jump_duration - 1 )
        if $self->jump_duration;

    if ($self->jump and $self->jump_duration <= 0) {
        print "Ending jump.\n";
        $self->jump(0);
    }
    elsif ($o->may_jump) {
        print "Starting jump.\n";
        $self->jump_duration(10);
        $self->jump(1);
    }
    else {
        print "Running.\n";
    }
}

1;
