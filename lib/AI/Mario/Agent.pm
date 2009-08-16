package AI::Mario::Agent;
use Moose::Role;

requires qw( reset update name );

has left => (
    is       => 'rw',
    isa      => 'Bool',
    required => 1,
    default  => 0,
);

has right => (
    is       => 'rw',
    isa      => 'Bool',
    required => 1,
    default  => 0,
);

has duck => (
    is       => 'rw',
    isa      => 'Bool',
    required => 1,
    default  => 0,
);

has jump => (
    is       => 'rw',
    isa      => 'Bool',
    required => 1,
    default  => 0,
);

has run => (
    is       => 'rw',
    isa      => 'Bool',
    required => 1,
    default  => 0,
);

sub actions {
    return map { $_[0]->$_ } qw( left right duck jump run );
}

1;
