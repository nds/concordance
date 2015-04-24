#!/usr/bin/env perl

use strict;
use warnings;
use File::Temp;
use File::Slurp;
use Cwd;

BEGIN { unshift( @INC, './lib' ) }
BEGIN {
	use Test::Most;
	use_ok( 'Bio::Concordance::Spreadsheet' );
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

ok(( $obj = Bio::Concordance::Spreadsheet->new( 
	sites         => \@sites,
	positions     => [ 1, 3, 5, 7 ],
	output_prefix => "$tmp/test"
)), 'initialize composition obj');


# TODO : plug in sample data and expected score
my $site1 = [];
my $site2 = [];
$exp = 100;
is( $obj->_concordance_score( $site1, $site2 ), $exp, 'concordance score correct' );

ok( $obj->write_spreadsheet, 'spreadsheet created');
# TODO : plug expected values into t/data/test.concordance.csv
is(
	read_file('t/data/test.concordance.csv'),
	read_file("$tmp/test.concordance.csv"),
	'spreadsheet file correct'
);

done_testing();