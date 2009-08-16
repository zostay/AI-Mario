#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use AI::Mario::Client;

my $client = AI::Mario::Client->new;
$client->connect;
