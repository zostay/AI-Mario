package AI::Mario::Client;
use Moose;

use POE qw(Component::Client::TCP Filter::Stream);
use POE::Declarative;

use AI::Mario::Fitness;
use AI::Mario::Observation;

has hostname => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    default   => 'localhost',
);

has port => (
    is        => 'ro',
    isa       => 'Int',
    required  => 1,
    default   => 4242,
);

has agent => (
    is        => 'rw',
    does      => 'AI::Mario::Agent',
    predicate => 'has_agent',
);

has agent_class => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    default   => 'AI::Mario::Agent::Simple',
);

has need_reset => (
    is        => 'rw',
    isa       => 'Bool',
    required  => 1,
    default   => 1,
);

has server_config => (
    is        => 'rw',
    isa       => 'Str',
    required  => 1,
    default   => '-maxFPS on -ld 0 -lt 0 -mm 2 -ls 1 -tl 100 -pw off -vis on',
);

sub setup_agent {
    my $self = shift;

    my $meta = Class::MOP::load_class($self->agent_class);
    $self->agent($meta->new_object);
}

sub tell_mario(@) {
    get(ARG0)->put(join '', @_, "\r\n");
}

on _start => run {
    my $self = get(OBJECT);
    $self->setup_agent;

    get(KERNEL)->alias_set('agent');

    POE::Component::Client::TCP->new(
        Alias         => 'mario',
        RemoteAddress => $self->hostname,
        RemotePort    => $self->port,
        Filter        => 'POE::Filter::Stream',
        Connected     => sub { 
            post(agent => 'connected', $_[HEAP]{server}) 
        },
        ServerInput   => sub { 
            post(agent => 'received', $_[HEAP]{server}, $_[ARG0]) 
        },
        Disconnected  => sub {
            post(agent => 'disconnected');
        },
    );
};

on connected => sub {
    my $self = get(OBJECT);
    my $agent_name = $self->agent->name;

    print "Connected $agent_name\n";
    tell_mario($agent_name);
};

on received => sub {
    my $self = get(OBJECT);
    my $config = $self->server_config;

    return if $self->is_disconnected;

    # Send a reset to update the server config
    if ($self->need_reset or $_[ARG1] =~ /^FIT\b/) {
        print "Sending reset... [$config]\n";
        tell_mario("reset $config");
        $self->need_reset(0);
    }

    my $agent = $self->agent;

    # Hello message from server
    if ($_[ARG1] =~ /^Server:/) {
        print $_[ARG1], "\n";
        return;
    }

    # Final message from the server
    elsif ($_[ARG1] =~ /^FIT\b/) {
        my $f = AI::Mario::Fitness->new($_[ARG1]);
        $agent->report_fitness($f);
        return;
    }

    my $o = AI::Mario::Observation->new($_[ARG1]);

    $agent->update($o);
    tell_mario(join '', $agent->actions);
};

on disconnected => sub {
    my $self = get(OBJECT);

    print "Reconnecting.\n";
    $self->need_reset(1);
    yield(reconnect => 1);
};

sub connect {
    my $self = shift;
    POE::Declarative->setup($self);
    POE::Kernel->run();
}

1;
