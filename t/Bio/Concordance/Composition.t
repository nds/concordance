#!/usr/bin/env perl

use strict;
use warnings;
use File::Temp;
use File::Slurp;
use Cwd;

BEGIN { unshift( @INC, './lib' ) }
BEGIN {
	use Test::Most;
	use_ok( 'Bio::Concordance::Composition' );
}

my $temp_directory_obj = File::Temp->newdir(DIR => getcwd, CLEANUP => 1 );
my $tmp = $temp_directory_obj->dirname();

my ( @sites, $obj, $exp );

@sites = (
	[ 'T', 'E', 'S', 'T' ],
	[ 'A', 'B', 'C', 'D' ],
	[ 'S', 'T', 'E', 'S' ],
	[ 'C', 'C', 'C', 'C' ]
);

ok(( $obj = Bio::Concordance::Composition->new( 
	sites => \@sites,
	output_prefix => "$tmp/test"
)), 'initialize composition obj');

$exp = [ 'A', 'B', 'C', 'D', 'E', 'S', 'T' ];
is_deeply( $obj->_bases, $exp, 'bases detected correctly' );

$exp = [ 0, 0, 0, 0, 25, 25, 50 ];
is_deeply( $obj->_site_content( [ 'T', 'E', 'S', 'T' ] ), $exp, 'content correct' );

$obj->write_spreadsheet;
is(
	read_file('t/data/test.composition.csv'),
	read_file("$tmp/test.composition.csv"),
	'spreadsheet file correct'
);

done_testing();