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
my $config   = 'AI::Mario::Config::Basic';
my (@agent_options, @config_options);

GetOptions(
    'host=s'              => \$hostname,
    'port=i'              => \$port,
    'agent=s'             => \$agent,
    'p|agent-options=s@'  => \@agent_options,
    'config=s'            => \$config,
    'o|config-options=s@' => \@config_options,
);

my %agent_options  = map { split /=/ } @agent_options;
my %config_options = map { split /=/ } @config_options;

my $client = AI::Mario::Client->new(
    hostname       => $hostname,
    port           => $port,
    agent_class    => $agent,
    agent_options  => \%agent_options,
    config_class   => $config,
    config_options => \%config_options,
);
$client->connect;
