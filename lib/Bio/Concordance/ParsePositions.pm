package Bio::Concordance::ParsePositions;

# ABSTRACT: parse positions from alignment

=head1 SYNOPSIS

Given an alignment file and a file of positions of interest, return an array ref
of the sites

=cut

use Moose;
use Bio::SeqIO;

has 'alignment' => ( is => 'ro', isa => 'Str', required => 1 );
has 'positions' => ( is => 'ro', isa => 'Str', required => 1 );

has '_aln_obj'   => ( is => 'rw', isa => 'Bio::Seq', lazy_build => 1 );
has '_pos_data'  => ( is => 'rw', isa => 'ArrayRef', lazy_build => 1 );

sub _build__pos_data {
	my $self = shift;

	open( POS, '<', $self->positions );
	my @ps;
	while( my $line = <POS> ) {
		chomp $line;
		my $p = int($line) or die ( "Invalid input from " . $self->positions . ": $line is not an integer\n" );
		push( @ps, $p );
	}
	return \@ps;
}

sub _build__aln_obj {
	my $self = shift;

	my $seqio = Bio::SeqIO->new( -file => $self->alignment , -format => 'Fasta' );
	return $seqio;
}

sub parse_positions_from_alignment {
	my $self = shift;

	my $aln = $self->_aln_obj;
	my @p_list = @{ $self->_pos_data };

	my @sites;
	while( my $seq = $seqio->next_seq() ) {
		my $c = 0;
		foreach my $i ( @pos ){
			push( @{ $sites[$c] }, substr( $seq->seq, $i-1, 1 )); # assuming positions will be 1 indexed...
			$c++;
		}
	}
	return \@sites;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;