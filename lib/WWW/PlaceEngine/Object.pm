package WWW::PlaceEngine::Object;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

##############################################################################
# CONSTRCUTOR 
##############################################################################

sub new {
    my $class = shift;
    my ($numap,$long,$lat,$range,$opt) = @_;
    for my $name (qw/numap long lat range/) {
        $opt->{$name} = eval qq{\$$name};
    }  
    bless $opt, $class;
}

##############################################################################
# ACCESSOR
##############################################################################
BEGIN{
    for my $name (qw/numap long lat range addr msg floor t/)
    {
        eval qq{
            sub $name { \$_[0]->{$name} }
        };
    }
}

1;

__END__

=pod

=head1 NAME

WWW::PlaceEngine::Object - Result object of WWW::PlaceEngine.

=head1 SYNOPSIS

 use WWW::PlaceEngine;
 
 my $wpl = WWW::PlaceEngine->new();
 
 my $loc = $wpl->get_location() or die $wpl->errcode;

 my ($lat,$long) = ($loc->lat,$loc->long);

=head1 DESCRIPTION

This module is not used directly.
get_location method of WWW::PlaceEngine returns this object.

=head1 METHODS

=over 4

=item lat()

returns latitude of PC's location.

=item long()

returns longitude of PC's location.

=item numap()

returns number of APs, using to survey PC's location.

=item addr()

returns address string of PC's location.

=item floor()

returns floor of PC's location.

=item t()

returns time of surveying PC's location(seconds from Jan/1/1970 0:00:00 UTC).

=item msg()

returns message string from PlaceEngine API host.

=item range()

mean of this value is not clearly known, but maybe information of accuracy.
unit of this value is meter.

=back 

=head1 SEE ALSO

http://www.placeengine.com/
WWW::PlaceEngine

=head1 AUTHOR

OHTSUKA Ko-hei, E<lt>nene[at]kokogiko.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by OHTSUKA Ko-hei

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
