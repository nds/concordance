package Bio::Concordance::Alignments;

# ABSTRACT: create alignments with positions edited

=head1 SYNOPSIS

Create 3 new alignments from the given alignment where the positions list has been
replaced with:
1. the most commonly occurring amino acid at that position
2. the least commonly occurring amino acid
3. the most commonly occurring pattern among all provided sites

=cut

use Moose;
use List::Util qw(first);
use Bio::SeqIO;
use Data::Dumper;

has 'alignment_file' => ( is => 'ro', isa => 'Str',      required => 1 );
has 'positions'      => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'sites'          => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'output_prefix'  => ( is => 'ro', isa => 'Str',      required => 1 );

has '_most_common_aa_filename'  => ( is => 'rw', isa => 'Str', lazy_build => 1 );
has '_least_common_aa_filename' => ( is => 'rw', isa => 'Str', lazy_build => 1 );
has '_most_common_pat_filename' => ( is => 'rw', isa => 'Str', lazy_build => 1 );

has '_most_common_aa_obj'  => ( is => 'rw', isa => 'Bio::SeqIO', lazy_build => 1 );
has '_least_common_aa_obj' => ( is => 'rw', isa => 'Bio::SeqIO', lazy_build => 1 );
has '_most_common_pat_obj' => ( is => 'rw', isa => 'Bio::SeqIO', lazy_build => 1 );

sub _build__most_common_aa_filename {
	my $self = shift;
	return $self->output_prefix . ".most_common_aa.fa";
}

sub _build__least_common_aa_filename {
	my $self = shift;
	return $self->output_prefix . ".least_common_aa.fa";
}

sub _build__most_common_pat_filename {
	my $self = shift;
	return $self->output_prefix . ".most_common_pat.fa";
}

sub _build__most_common_aa_obj {
	my $self = shift;

	my $outfile = $self->_most_common_aa_filename;
	return Bio::SeqIO->new( -file => ">$outfile", -format => 'Fasta' );
}

sub _build__least_common_aa_obj {
	my $self = shift;

	my $outfile = $self->_least_common_aa_filename;
	return Bio::SeqIO->new( -file => ">$outfile", -format => 'Fasta' );
}

sub _build__most_common_pat_obj {
	my $self = shift;

	my $outfile = $self->_most_common_pat_filename;
	return Bio::SeqIO->new( -file => ">$outfile", -format => 'Fasta' );
}


sub write_alignments {
	my $self = shift;

	$self->_write_most_common_aa;
	$self->_write_least_common_aa;
	$self->_write_most_common_pat;
}

sub _write_most_common_aa {
	my $self = shift;

	my $i = 0;
	my %most_common_aa;
	foreach my $p ( @{ $self->positions } ){
		my @mcaa = split( '', $self->_most_common_aa( $self->sites->[$i] ) );
		$most_common_aa{$p} = \@mcaa;
		$i++;
	}

	$self->_replace_positions( \%most_common_aa, $self->_most_common_aa_obj );
}

sub _most_common_aa {
	my ( $self, $site ) = @_;

	my %counter;
	$counter{$_} ++ for @{ $site };

	# TODO: how to handle multiple equally frequent amino acids?? 
	my $max = 0;
	my $winner;
	foreach my $x ( keys %counter ){
		$winner = $x if ( $counter{$x} > $max );
		$max = $counter{$x};
	}

	my $new_site = $winner x scalar( @{$site} );
	return $new_site;
}

sub _write_least_common_aa {
	my $self = shift;

	my $i = 0;
	my %least_common_aa;
	foreach my $p ( @{ $self->positions } ){
		my @lcaa = split( '', $self->_least_common_aa( $self->sites->[$i] ));
		$least_common_aa{$p} = \@lcaa;
		$i++;
	}

	$self->_replace_positions( \%least_common_aa, $self->_least_common_aa_obj );
}

sub _least_common_aa {
	my ( $self, $site ) = @_;

	my %counter;
	$counter{$_} ++ for @{ $site };

	# TODO: how to handle multiple equally frequent amino acids?? 
	my $min = 10000000;
	my $winner;
	foreach my $x ( keys %counter ){
		$winner = $x if ( $counter{$x} < $min );
		$min = $counter{$x};
	}

	my $new_site = $winner x scalar( @{$site} );
	return $new_site;
}

sub _write_most_common_pat {
	my $self = shift;

	my $i = 0;
	my $pat = $self->_most_common_pat;
	my %most_common_pat;
	$most_common_pat{$_} = $self->_generate_amino_acid_pattern($pat) for @{ $self->positions };

	$self->_replace_positions( \%most_common_pat, $self->_most_common_pat_obj );
}

sub _generate_amino_acid_pattern {
	my ( $self, $pattern ) = @_;
	# TODO: create a site with amino acids that follows $pattern
	1;
}

sub _most_common_pat {
	my $self = shift;

	my %pats;
	foreach my $s ( @{ $self->sites } ){
		my $pat = $self->_pattern( $s );
		$pats{ $self->_pattern_to_str( $pat ) }++;
	}

	my $max = 0;
	my $winner;
	foreach my $x ( keys %pats ) {
		$winner = $x if ( $pats{$x} > $max );
		$max = $pats{$x};
	}

	return $self->_pattern_from_str( $winner );
}

sub _pattern {
	my ( $self, $site ) = @_;

	my (@bases, @pattern);
	my $x = 0;
	foreach my $base ( @{ $site } ){
		if( grep { $_ eq $base } @bases ){
			my $index = first { $bases[$_] eq $base } 0..$#bases;
			push( @{ $pattern[ $index ] }, $x );
		}
		else {
			push( @bases, $base );
			push( @pattern, [$x] );
		}
		$x++;
	}
	return \@pattern;
}

sub _pattern_to_str {
	my ( $self, $pattern ) = @_;

	my @new_pat;
	foreach my $group ( @{ $pattern } ){
		push( @new_pat, join(',', @{ $group }) );
	}
	return join(';', @new_pat);
}

sub _pattern_from_str {
	my ( $self, $pattern ) = @_;

	my @groups = split(';', $pattern);
	my @new_pat;
	foreach my $g ( @groups ){
		my @spl_g = split( ',', $g );
		push( @new_pat, \@spl_g );
	}

	return \@new_pat;
}

=head2 _replace_positions
	Writes alignment in fasta format with all provided positions replaced with
	given site

	$pos_data should be a hash with position as key and replacement site as value.
	Replacement sites should be an array ref of characters.

	$seq_out should be a Bio::SeqIO writer
=cut

sub _replace_positions {
	my ( $self, $pos_data, $seq_out ) = @_;

	my %pos = %{ $pos_data };
	my $infile = $self->alignment_file;
	my $seq_in = Bio::SeqIO->new( -file => "<$infile", -format => 'Fasta' );

	my $c = 0;
	while ( my $seq = $seq_in->next_seq ) {
		my $seq_str = $seq->seq;
		foreach my $p ( keys %pos ){
			substr( $seq_str, $p-1, 1 ) = $pos{$p}[$c];
		}
		$seq->{primary_seq}->{seq} = $seq_str;
		$seq_out->write_seq( $seq );
		$c++;
	}
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;