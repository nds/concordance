package Bio::Concordance::Spreadsheet;

# ABSTRACT: create matrix of concordance scores and write to CSV

=head1 SYNOPSIS

=cut

use Moose;

has 'sites'         => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'positions'     => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'output_prefix' => ( is => 'ro', isa => 'Str',      required => 1 );
has 'output_suffix' => ( is => 'rw', isa => 'Str',      default  => '.concordance.csv' );

has '_spreadsheet_header' => ( is => 'rw', isa => 'ArrayRef',  lazy_build => 1 );
has '_spreadsheet_writer' => ( is => 'rw', isa => 'Text::CSV', lazy_build => 1 );
has '_spreadsheet_file'   => ( is => 'rw', isa => 'Str',       lazy_build => 1 );

sub _build__spreadsheet_header {
	my $self = shift;
	my @header = ( 'position' );
	my @positions = @{ $self->positions };
	unshift @positions; # don't need first position in header for triangle matrix
	push( @header, @positions );
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

	my @positions = @{ $self->positions };
	my @sites     = @{ $self->sites };

	open( my $csv_out, '>', $self->_spreadsheet_file );
	$csv_writer->print( $csv_out, $self->_spreadsheet_header );

	# create matrix
	my $i = 0;
	while ( $i < (scalar(@sites)-1) ){ # don't need last position for triangle
		my $j = 0;
		my ($score, @row);
		while ( $j < scalar(@sites) ){
			if ( $j > $i ){
				# compare sites
				$score = $self->_concordance_score( $sites[$i], $sites[$j] );
			}
			else {
				# pad
				$score = " ";
			}
			push( @row, $score );
			$j++;
		}
		$csv_writer->print( $csv_out, \@row );
		$i++;
	}
	close( $csv_out );
}

sub _concordance_score {
	my ( $self, $site1, $site2 ) = @_;

	### TODO: REPLACE WITH CONCORDANCE CALCULATION!! ###
	return int( rand(101) ); # return percentage
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;