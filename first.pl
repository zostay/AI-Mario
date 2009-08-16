#!/usr/bin/perl
use strict;
use warnings;

use constant LEFT  => 0;
use constant RIGHT => 1;
use constant DUCK  => 2;
use constant JUMP  => 3;
use constant RUN   => 4;

use POE qw(Component::Client::TCP Filter::Stream);
use POE::Declarative;

use Observation;

my $client_name = 'FirstPerl';
my $need_reset  = 1;
my $server_config 
    = '-maxFPS on -ld 0 -lt 0 -mm 2 -ls 1 -tl 100 -pw off -vis on';

on _start => run {
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

sub tell_mario_to_go(@) {
    my @instructions = (0) x 5;
    $instructions[$_] = 1 for @_;
    tell_mario(@instructions);
}

on connected => sub {
    print "Connected $client_name\n";
    tell_mario($client_name);
};

my $jumping = 0;

on received => sub {
    if ($need_reset) {
        print "Sending reset... [$server_config]\n";
        tell_mario("reset $server_config");
        $need_reset = 0;
    }

    my $o = Observation->new($_[ARG1]);

    if ($jumping and $o->is_grounded) {
        print "Ending jump.\n";
        tell_mario_to_go(RIGHT, RUN);

        $jumping = 0;
    }
    elsif ($jumping) {
        print "Continuing jump.\n";
        tell_mario_to_go(RUN, JUMP, RIGHT);
    }
    elsif ($o->may_jump) {
        print "Starting jump.\n";
        tell_mario_to_go(RUN, JUMP, RIGHT);

        $jumping = 1;
    }
    else {
        print "Running.\n";
        tell_mario_to_go(RIGHT, RUN);
    }
};

POE::Declarative->setup;
POE::Kernel->run();
