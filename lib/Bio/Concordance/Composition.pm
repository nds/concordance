package Bio::Concordance::Composition;

# ABSTRACT: summarize composition of sites

=head1 SYNOPSIS

=cut

use Moose;
use Text::CSV;

use Data::Dumper;

has 'sites'         => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'output_prefix' => ( is => 'ro', isa => 'Str',      required => 1 );
has 'output_suffix' => ( is => 'rw', isa => 'Str',      default  => '.composition.csv' );

has '_spreadsheet_header' => ( is => 'rw', isa => 'ArrayRef',  lazy_build => 1 );
has '_spreadsheet_writer' => ( is => 'rw', isa => 'Text::CSV', lazy_build => 1 );
has '_spreadsheet_file'   => ( is => 'rw', isa => 'Str',       lazy_build => 1 );

has '_bases' => ( is => 'rw', isa => 'ArrayRef', lazy_build => 1 );

sub _build__bases {
	my $self = shift;

	my %bases;
	foreach my $site ( @{ $self->sites } ){
		foreach my $base ( @{ $site } ){
			$bases{$base} = 1;
		}
	}

	my @b = sort(keys %bases);
	return \@b;
}

sub _build__spreadsheet_header {
	my $self = shift;
	my @header = ( 'position', 'no. unique characters' );
	push( @header, @{ $self->_bases } );
	return \@header;
}

sub  _build__spreadsheet_writer {
	my $self = shift;
	return Text::CSV->new( { 
		sep_char     => "\t",
		always_quote => 1,
		eol          => "\n"
	} );
}

sub  _build__spreadsheet_file {
	my $self = shift;
	return $self->output_prefix . $self->output_suffix;
}

sub write_spreadsheet {
	my $self = shift;
	my $csv_writer = $self->_spreadsheet_writer;

	open( my $csv_out, '>', $self->_spreadsheet_file );
	$csv_writer->print( $csv_out, $self->_spreadsheet_header );

	foreach my $s ( @{ $self->sites } ) {
		my @row = ( join('', @{$s}) );
		my @content = @{ $self->_site_content( $s ) };
		my $unique = $self->_num_unique( \@content );
		push( @row, $unique );
		push( @row, @content );

		$csv_writer->print( $csv_out, \@row );
	}
	close( $csv_out );
}

sub _num_unique {
	my ( $self, $content ) = @_;

	my $unique = 0;
	foreach my $c ( @{ $content } ) {
		$unique++ if ( $c > 0 );
	}
	return $unique;
}

sub _site_content {
	my ($self, $site) = @_;
	my @bases_detected = @{ $self->_bases };

	my %counts = map { $_ => 0 } @bases_detected;
	for my $base ( @{ $site } ){
		$counts{$base}++;
	}

	my $total;
	foreach my $base ( keys %counts ){
		$total += $counts{$base};
	}

	my @perc;
	foreach my $base ( @bases_detected ){
		my $perc_content = ( $counts{$base}/$total ) * 100;
		push( @perc, $perc_content );
	}
	return \@perc;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;