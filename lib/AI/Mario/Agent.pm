package AI::Mario::Agent;
use Moose::Role;

requires qw( reset update name fitness );

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

sub report_fitness {
    my ($self, $f) = @_;

    print $f->report;

    $self->fitness($f);
}

1;
