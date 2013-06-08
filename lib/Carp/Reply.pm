package Carp::Reply;
use strict;
use warnings;
# ABSTRACT: get a repl on exceptions in your program

use Reply;
use Reply::Config;

sub import {
    my $package = shift;

    $SIG{__DIE__} = sub { print $_[0]; repl() };
}

sub repl {
    my $repl = Reply->new(
        config  => Reply::Config->new,
        plugins => ['CarpReply']
    );
    $repl->run_one('#bt');
    $repl->run;
}

1;
