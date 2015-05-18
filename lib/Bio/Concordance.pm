package Bio::Concordance;

# ABSTRACT: detect and summarize concordance

=head1 SYNOPSIS

=cut

use Moose;
use Text::CSV;

has 'alignment_file' => ( is => 'ro', isa => 'Str',      required   => 1 );
has 'positions_file' => ( is => 'ro', isa => 'Str',      required   => 1 );
has 'output_prefix'  => ( is => 'ro', isa => 'Str',      required   => 1 );

has 'positions'      => ( is => 'rw', isa => 'ArrayRef', lazy_build => 1 );
has 'sites'          => ( is => 'rw', isa => 'ArrayRef', lazy_build => 1 );

# internals
has '_composition_obj' => ( is => 'rw', lazy_build => 1 );
has '_spreadsheet_obj' => ( is => 'rw', lazy_build => 1 );
has '_alignment_obj'   => ( is => 'rw', lazy_build => 1 );
has '_position_parser' => ( is => 'rw', lazy_build => 1 );

sub _build_positions {
	my $self = shift;
	return $self->_position_parser->_pos_data;
}

sub _build_sites {
	my $self = shift;
	return $self->_position_parser->parse_positions_from_alignment;
}

sub _build__composition_obj {
	my $self = shift;

	return Bio::Concordance::Composition->new(
		sites => 		 $self->sites,
		output_prefix => $self->output_prefix
	);
}

sub _build__spreadsheet_obj {
	my $self = shift;

	return Bio::Concordance::Spreadsheet->new(

	);
}

sub _build__alignment_obj {
	my $self = shift;

	return Bio::Concordance::Alignments->new();
}

sub _build__position_parser {
	my $self = shift;
	return Bio::Concordance::ParsePositions->new(
		alignment => $self->alignment_file,
		positions => $self->positions_file
	);
}



sub run {
	my $self = shift;

	$self->_composition_obj->write_spreadsheet;
	$self->_spreadsheet_obj->write_spreadsheet;
	$self->_alignment_obj->write_alignments;
	1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;