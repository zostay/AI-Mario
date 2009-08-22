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
    lazy      => 1,
    default   => sub {
        my $self = shift;
        my $meta = eval { Class::MOP::load_class($self->agent_class) };
        if (not $meta and $self->agent_class !~ /::/) {
            $meta = Class::MOP::load_class('AI::Mario::Agent::' . $self->agent_class);
        }
        return $meta->new_object($self->agent_options);
    },
);

has agent_class => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    default   => 'AI::Mario::Agent::Simple',
);

has agent_options => (
    is        => 'ro',
    isa       => 'HashRef',
    required  => 1,
    default   => sub { {} },
);

has config => (
    is        => 'rw',
    does      => 'AI::Mario::Config',
    lazy      => 1,
    default   => sub {
        my $self = shift;
        my $meta = eval { Class::MOP::load_class($self->config_class) };
        if (not $meta and $self->config_class !~ /::/) {
            $meta = Class::MOP::load_class('AI::Mario::Config::' . $self->config_class);
        }
        return $meta->new_object($self->config_options);
    },
);

has config_class => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    default   => 'AI::Mario::Config::Basic',
);

has config_options => (
    is        => 'ro',
    isa       => 'HashRef',
    required  => 1,
    default   => sub { {} },
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

sub tell_mario(@) {
    get(ARG0)->put(join '', @_, "\r\n");
}

on _start => run {
    my $self = get(OBJECT);

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

    # Send a reset to update the server config
    if ($self->need_reset or $_[ARG1] =~ /^FIT\b/) {
        my $config = $self->config;
        $config->reset;

        my $agent = $self->agent;
        $agent->reset;

        my $string = $config->as_string;
        print "Sending reset... [$string]\n";
        tell_mario("reset $string");

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
