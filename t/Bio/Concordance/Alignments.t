#!/usr/bin/env perl
use File::Temp;
use Cwd;
use Data::Dumper;
use File::Slurp;

BEGIN { unshift( @INC, './lib' ) }
BEGIN {
	use Test::Most;
}

use_ok( 'Bio::Concordance::Alignments' );

my $temp_directory_obj = File::Temp->newdir(DIR => getcwd, CLEANUP => 1 );
my $tmp = $temp_directory_obj->dirname();

my ( @sites, $obj, $exp );

@sites = (
	[ 'T', 'E', 'S', 'T' ],
	[ 'A', 'B', 'C', 'D' ],
	[ 'S', 'T', 'E', 'S' ],
	[ 'C', 'C', 'C', 'S' ]
);

ok(( $obj = Bio::Concordance::Alignments->new( 
	alignment_file => 't/data/aln_20bp.fa',
	sites         => \@sites,
	positions     => [ 1, 3, 5, 7 ],
	output_prefix => "$tmp/test"
)), 'initialize composition obj');


# test detection of most common amino acid in a site
$exp = 'TTTT';
is( $obj->_most_common_aa( $sites[0] ), $exp, 'most common amino acid detected' );

# test detection of least common amino acid
$exp = 'SSSS';
is( $obj->_least_common_aa( $sites[3] ), $exp, 'least common amino acid detected' );

# test pattern creation from site
$exp = [ [0,3], [1], [2] ];
is_deeply( $obj->_pattern( $sites[0] ), $exp, 'pattern correct' );

# test pattern to string method
$exp = "0,3;1;2";
is( $obj->_pattern_to_str( [ [0,3], [1], [2] ] ), $exp, 'stringified pattern correct' );

# test pattern from string method
$exp = [ [0,3], [1], [2] ];
is_deeply( $obj->_pattern_from_str("0,3;1;2"), $exp, 'un-stringed pattern correct' );

# test detection of most common pattern
is_deeply( $obj->_most_common_pat, $exp, 'most common pattern detected' );


# check written alignments are correct
ok( $obj->write_alignments, 'alignments written successfully' );

# TODO: replace expected files when decision has been made re equally frequent
# characters - right now, test pass by sheer luck of the draw
is(
	read_file('t/data/test.most_common_aa.fa'),
	read_file("$tmp/test.most_common_aa.fa"),
	'most common amino acid replaced correctly'
);
is(
	read_file('t/data/test.least_common_aa.fa'),
	read_file("$tmp/test.least_common_aa.fa"),
	'least common amino acid replaced correctly'
);

# TODO: Fill in expected file in t/data/
# is(
# 	read_file('t/data/test.most_common_pat.fa'),
# 	read_file("$tmp/test.most_common_pat.fa"),
# 	'most common pattern replaced correctly'
# );


done_testing();