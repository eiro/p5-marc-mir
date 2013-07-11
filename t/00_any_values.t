#! /usr/bin/perl
use Modern::Perl;
use YAML;
use MARC::MIR;
use Test::More;

sub must_work { any_values { /M/ } [qw< 328 b >], shift }

my %fake = 
( find =>
    [ 'header', [
        [ 328,
           [ [qw< a haha >]
           , [qw< b M >]
           ] ]
        , [ 328,
           [ [qw< a haha >]
           , [qw< b lol  >]
           ] ]
    ] ]
, dontfind =>
    [ 'header', [
        [ 328,
           [ [qw< a haha >]
           ] ]
        , [ 328,
           [ [qw< a haha >]
           , [qw< b lol  >]
           ] ]
    ] ] );

{ my $got = must_work $fake{find};
    ok $got, 'any_values find something'
        or diag "got means $got";
};

{ my $got = must_work $fake{dontfind};
    ok $got, 'any_values do not find'
        or diag "got means $got";
}

done_testing;
