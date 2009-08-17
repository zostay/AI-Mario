package AI::Mario::Config::Random;
use Moose;

with qw( AI::Mario::Config );

sub reset {
    my $self = shift;
    $self->level_seed(1 + int(rand(2**31 - 2)));
    $self->level_type(int(rand(3)));
}

1;
