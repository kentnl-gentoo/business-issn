package Business::ISSN;

use strict;
use subs qw(_common_format _checksum is_valid_checksum);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $debug);

use Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(is_valid_cheksum);

$VERSION = '0.90';
# Version numbers below 1.0 are considered as beta versions.

sub new {
        my $class       = shift;
        my $common_data = _common_format shift;
        
        my $self = {};

        return undef unless $common_data;

        bless $self, $class;

        $self->{'issn'} = $common_data;
        $self->{'positions'} = [7];

        $common_data =~m/(\d{7,7})([\dxX])$/;
        $self->{'checksum'} = $2;
        $self->{'code'} = $1;


        if ( is_valid_checksum $self->{'issn'}) {
          $self->{'valid'} = 1;
        } else {
          $self->{'valid'} = 0;
        } 

        return $self;
        }


sub issn             { my $self = shift; return $self->{'issn'} }
sub is_valid         { my $self = shift; return $self->{'valid'} }
sub checksum         { my $self = shift; return $self->{'checksum'} }
sub hyphen_positions { my $self = shift; return @{$self->{'positions'}} }


sub fix_checksum
        {
        my $self = shift;
        my $debug = 1;
        
        my $last_char = substr($self->{'issn'}, 7, 1);
        my $checksum = _checksum $self->issn;
        substr($self->{'issn'}, 7, 1) = $checksum;
       
        $self->_check_validity;
        
        return 0 if $last_char eq $checksum;
        return 1;
        }

sub as_string
        {
        my $self      = shift;
        
        
        return "" unless ($self->is_valid() == 1);
        # return undef unless ($self->is_valid() == 1);
        my $issn = $self->issn;
        
        substr($issn, 4, 0) = '-';
        return $issn;
        }

sub as_ean
        {
        my $self = shift;
        
        my $issn = ref $self ? $self->as_string([]) : _common_format $self;
        
        my $ean = '97700' . substr($issn, 0, 7);;
        
        my $sum = 0;
        foreach my $index ( 0, 2, 4, 6, 8, 10 )
                {
                $sum +=     substr($ean, $index, 1);
                $sum += 3 * substr($ean, $index + 1, 1);
                }
                        
        $ean .= 10 - ( $sum % 10 );
        
        return $ean;
        }

sub is_valid_checksum
        {
        my $data = _common_format shift;
        return 0 unless $data;        
        return 1 if substr($data, 7, 1) eq _checksum $data;
        return 0;
        }


# ean_to_issn and issn_to_ean are not documented funtions.
# You may use them if you wish. At the moment it's not clear
# into which ean,if any, issns are converted in the real world, 
# I've have found magazines that use ean-13, ean-9 but
# most magazines don't print out their issn as an ean at all. 

sub ean_to_issn
        {
        my $ean = shift;
        
        $ean =~ s/[^0-9]//g;
        
        #return undef unless length $ean == 13;
        #return undef unless substr($ean, 0, 3) eq '977';
                
        my $issn = new Business::ISSN( substr($ean, 5, 7) . '1' );
        
        $issn->fix_checksum;

        return $issn->as_string(); # if $issn->is_valid;
        
        return undef;
        }

sub issn_to_ean
        {
        my $issn = _common_format shift;
        
        #return undef unless is_valid_checksum($issn);
        
        return as_ean($issn);
        }       
        
# end of undocumented ean

sub _check_validity
        {
        my $self = shift;
       
          
        if( is_valid_checksum ($self->issn() ))
        {
          $self->{'valid'} = 1;
        } else
        {
          $self->{'valid'} = 0;
        }
        }

sub _checksum
        {
        my $data = _common_format shift;
        
        return undef unless $data;
        
        my @digits = split //, $data;
        my $sum    = 0;         

        foreach( reverse 2..8 ) # oli 10
                {
                $sum += $_ * (shift @digits);
                }
        
        #return what the check digit should be
        my $checksum = (11 - ($sum % 11))%11;
        
        $checksum = 'X' if $checksum == 10;
        
        return $checksum;
        }

sub _common_format
        {
        #we want uppercase X's
        my $data = uc shift;
        
        #get rid of everything except decimal digits and X
        $data =~ s/[^0-9X]//g;
        
        return $data if $data =~ m/
                          ^             #anchor at start  
                                        \d{7}[0-9X]
                          $                     #anchor at end
                          /x;
                          
        return undef;
        }







1;
__END__

=head1 NAME

Business::ISSN - Perl extension for International Standard Serial Numbers

=head1 SYNOPSIS

  use Business::ISSN;
  $issn_object = new Business::ISSN('1456-5935');
  $issn_object = new Business::ISSN('14565935');
  
  # print the ISSN with hyphens
  print $issn_object->as_string;

  # check to see if the ISSN is valid
  $issn_object->is_valid;
 
  #fix the ISSN checksum.  BEWARE:  the error might not be
  #in the checksum!
  $issn_object->fix_checksum;

  #EXPORTABLE FUNCTIONS
        
  use Business::ISSN qw( is_valid_checksum );
        
  #verify the checksum
  if( is_valid_checksum('01234567') ) { ... }




=head1 DESCRIPTION

=head2 new($issn)

The constructor accepts a scalar representing the ISSN.

The string representing the ISSN may contain characters
other than [0-9xX], although these will be removed in the
internal representation.  The resulting string must look
like an ISSN - the first seven characters must be digits and
the eighth character must be a digit, 'x', or 'X'.

The string passed as the ISSN need not be a valid ISSN as
long as it superficially looks like one.  This allows one to
use the C<fix_checksum()> method. 

One should check the validity of the ISSN with C<is_valid()>
rather than relying on the return value of the constructor. 

If all one wants to do is check the validity of an ISSN, 
one can skip the object-oriented  interface and use the
c<is_valid_checksum()> function which is exportable on demand.

If the constructor decides it can't create an object, it
returns undef.  It may do this if the string passed as the
ISSN can't be munged to the internal format.

=head2 $obj->as_string()

Return the ISSN as a string. 

A terminating 'x' is changed to 'X'.


=head2  $obj->is_valid()

Returns 1 if the checksum is valid.

Returns 0 if the ISSN does not pass the checksum test.  
The constructor accepts invalid ISSN's so that
they might be fixed with C<fix_checksum>.  

=head2  $obj->fix_checksum()

Replace the eighth character with the checksum the
corresponds to the previous seven digits.  This does not
guarantee that the ISSN corresponds to the product one
thinks it does, or that the ISSN corresponds to any product
at all.  It only produces a string that passes the checksum
routine.  If the ISSN passed to the constructor was invalid,
the error might have been in any of the other nine positions.

=head1 EXPORTABLE FUNCTIONS

Some functions can be used without the object interface.  These
do not use object technology behind the scenes.

=head2 is_valid_checksum('01234567')

Takes the ISSN string and runs it through the checksum
comparison routine.  Returns 1 if the ISSN is valid, 0 otherwise.

=head1 AUTHOR

Sami Poikonen <sp@iki.fi>

Copyright 1999, Sami Poikonen.

This module is released under the terms of the Perl Artistic License.

This module is a derived work from brian d foy's Business::ISBN.

=head1 SEE ALSO

Business::ISBN and its documentation.

=cut
