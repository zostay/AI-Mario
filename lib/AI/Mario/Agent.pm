package AI::Mario::Agent;
use Moose::Role;

use Moose::Util::TypeConstraints;

requires qw( reset update name fitness );

subtype Control => as Int => where { $_ eq '0' or $_ eq '1' };

has left => (
    is       => 'rw',
    isa      => 'Control',
    required => 1,
    default  => 0,
);

has right => (
    is       => 'rw',
    isa      => 'Control',
    required => 1,
    default  => 0,
);

has duck => (
    is       => 'rw',
    isa      => 'Control',
    required => 1,
    default  => 0,
);

has jump => (
    is       => 'rw',
    isa      => 'Control',
    required => 1,
    default  => 0,
);

has run => (
    is       => 'rw',
    isa      => 'Control',
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
