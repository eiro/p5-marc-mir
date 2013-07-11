#! /usr/bin/perl
use Modern::Perl;
use YAML;
use MARC::MIR;
use Test::More;

my @before =
( [ '001' => 'ID' ]
, [ 994 => [ [qw/I DONT/] ] ]
, [ 995 => [ [qw/I DO/], [qw/A CAKE/] ] ]
, [ 995 => [ [qw/I DO/] ] ]
, [ 995 => [ [qw/I DO/], [qw/A CODE/] ] ]
, [ 996 => [ [qw/I DONT/] ] ]
, [ 995 => [ [qw/I DO/] ] ] );

my $expected =
[ [ '001' => 'ID' ]
, [ 994 => [ [qw/I DONT/] ] ]
, [ 995 =>
    [ [qw/I DO/]
    , [qw/A CAKE/]
    , [qw/I DO/]
    , [qw/I DO/]
    , [qw/A CODE/]
    , [qw/I DO/]
    ] ]
, [ 996 => [ [qw/I DONT/] ] ] ]; 

my $record = [ H =>  [@before] ];
merge_fields 995, $record;
my $got = value $record;

is_deeply $expected, $got
, 'can merge_fields'
    or diag YAML::Dump $got;

done_testing;
