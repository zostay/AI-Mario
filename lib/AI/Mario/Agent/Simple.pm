package AI::Mario::Agent::Simple;
use Moose;

with 'AI::Mario::Agent';

sub name { 'Simple' }

sub reset {}

sub update {
    my ($self, $o) = @_;

    $self->right(1);
    $self->run(1);

    if ($self->jump and $o->is_grounded) {
        print "Ending jump.\n";
        $self->jump(0);
    }
    elsif ($o->may_jump) {
        print "Starting jump.\n";
        $self->jump(1);
    }
    else {
        print "Running.\n";
    }
}

1;
