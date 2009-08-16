#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use Class::MOP;
use POE qw(Component::Client::TCP Filter::Stream);
use POE::Declarative;

use lib "$FindBin::Bin/../lib";

use AI::Mario::Observation;

my $agent;
my $agent_class = $ARGV[0] || 'AI::Mario::Agent::Simple';

my $need_reset  = 1;
my $server_config 
    = '-maxFPS on -ld 0 -lt 0 -mm 2 -ls 1 -tl 100 -pw off -vis on';

on _start => run {
    my $meta = Class::MOP::load_class($agent_class);
    $agent = $meta->new_object;

    get(KERNEL)->alias_set('agent');

    POE::Component::Client::TCP->new(
        Alias         => 'mario',
        RemoteAddress => "localhost",
        RemotePort    => 4242,
        Filter        => 'POE::Filter::Stream',
        Connected     => sub { 
            post(agent => 'connected', $_[HEAP]{server}) 
        },
        ServerInput   => sub { 
            post(agent => 'received', $_[HEAP]{server}, $_[ARG0]) 
        },
    );
};

sub tell_mario(@) {
    get(ARG0)->put(join '', @_, "\r\n");
}

on connected => sub {
    print "Connected @{[$agent->name]}\n";
    tell_mario($agent->name);
};

on received => sub {
    if ($need_reset) {
        print "Sending reset... [$server_config]\n";
        tell_mario("reset $server_config");
        $need_reset = 0;
    }

    my $o = AI::Mario::Observation->new($_[ARG1]);
    $agent->update($o);
    tell_mario(join '', $agent->actions);
};

POE::Declarative->setup;
POE::Kernel->run();
