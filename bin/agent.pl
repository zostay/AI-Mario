#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use AI::Mario::Client;
use Getopt::Long;

my $hostname = 'localhost';
my $port     = 4242;
my $agent    = 'AI::Mario::Agent::Simple';

GetOptions(
    'host=s'  => \$hostname,
    'port=i'  => \$port,
    'agent=s' => \$agent,
);

my $client = AI::Mario::Client->new(
    hostname    => $hostname,
    port        => $port,
    agent_class => $agent,
);
$client->connect;
