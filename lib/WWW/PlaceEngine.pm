package WWW::PlaceEngine;

use strict;
use vars qw($VERSION);
use Readonly;
use JSON;
use LWP::UserAgent;
use WWW::PlaceEngine::Object;
$VERSION = '0.01';
$JSON::QuotApos = 1;
$JSON::UTF8 = 1;

Readonly my $API_HOST      => 'http://www.placeengine.com/api';
Readonly my $RTAG_DAEMON   => 'http://localhost:5448';
Readonly my $SITE_DEFAULT  => 'http://www.placeengine.com/map';
Readonly my $APKEY_DEFAULT => 'WRO4eQR7vXTLAWHx4wF3ZZWA7TWrfvg0ARkf7VqEdnt9BxcZ2ey7WXa7bbKxtVvaBnYJLsRIXLcBIoi-jdSuZ4uvzSxHHcpjzm4nohQCMTM-Oggcv4px2d6dQUAhZ1E63HvCfA6e-HYyDDjRHDKv2Ur9LjidlfoEhDBCXc0Ek1X3RSXkgLsDMW-6sORBvmW5NHmliaAqkBPRbpmj3o.9PdL2oesjpqt4IZOknqkoYeaoITr8ms25FM89kvJVNef.kA.Vx4yVJEFgQMP.zzIdPWmGj5-UPYFXIbRhyJE-CjVF4NVpTmU-1f9eNEOW4dNuibjxSi0IKuz5GaLRcIpdXw__,aHR0cDovL3d3dy5wbGFjZWVuZ2luZS5jb20_,UGxhY2VFbmdpbmUgTWFw';
Readonly my $ERR_NOT_OCCUR => 0;
Readonly my $ERR_NO_APPKEY => -1;
Readonly my $ERR_NO_RTAGD  => -2;
Readonly my $ERR_WIFI_OFF  => -3;
Readonly my $ERR_WIFI_DENY => -4;
Readonly my $ERR_NO_AP     => -5;
Readonly my $ERR_NO_HOST   => -6;
Readonly my $ERR_NO_LOC    => -7;
Readonly my $ERR_BAD_APKEY => -8;

Readonly my $ERROR_TABLE   => {
                                  $ERR_NOT_OCCUR => '',
                                  $ERR_NO_APPKEY => 'Application key not found.',
                                  $ERR_NO_RTAGD  => 'PlaceEngine client not found or cannot accessible.',
                                  $ERR_WIFI_OFF  => 'WiFi device is turned off.',
                                  $ERR_WIFI_DENY => 'Getting WiFi information is denyed.',
                                  $ERR_NO_AP     => 'No APs are found or WiFi device is turned off.',
                                  $ERR_NO_HOST   => 'PlaceEngine API host cannot accessible.',
                                  $ERR_NO_LOC    => 'AP has no location information.',
                                  $ERR_BAD_APKEY => 'PlaceEngine client should take API key.',
                              };

##############################################################################
# CONSTRCUTOR 
##############################################################################

sub new {
    my $class = shift;
    my %opt   = @_;
    bless {
        host    => $API_HOST      ,
        rtagd   => $RTAG_DAEMON   ,
        site    => $SITE_DEFAULT  ,
        appkey  => $APKEY_DEFAULT ,
        errcode => $ERR_NOT_OCCUR ,
        err     => ''             ,
        # overwrite
        %opt,
    }, $class;
}

##############################################################################
# ACCESSOR
##############################################################################
BEGIN{
    for my $name (qw/host rtagd site appkey err errcode/)
    {
        eval qq{
            sub $name { \$_[0]->{$name} = \$_[1] if(defined \$_[1]); \$_[0]->{$name} }
        };
    }
}

##############################################################################
# METHODS
##############################################################################

sub get_location {
    my $self = shift;
    $self->set_err;
    return $self->set_err($ERR_NO_APPKEY) if !$self->appkey;

    my $ua = LWP::UserAgent->new(timeout => 30);
    my $res = $ua->get($self->rtagd . '/rtagjs?t=' . time . '&appk=' . $self->appkey);
    return $self->set_err($ERR_NO_RTAGD) if !$res->is_success;

    my $cont = $res->content;
    $cont =~ s/^recvRTAG\((.+)\);$/[$1]/;
    my $rtagobj = jsonToObj($cont);

    return $self->recv_rtag(@{$rtagobj});
}

sub recv_rtag {
    my $self = shift;
    my ($rtag,$numap,$time,$k,$tkn) = @_;

    if (($numap == -4) || ($numap == -5) || ($numap == -6)) {
        return $self->set_err($ERR_WIFI_DENY);
    } elsif ($numap < 0) {
        return $self->set_err($ERR_WIFI_DENY);
    } elsif ($numap == 0) {
        return $self->set_err($ERR_NO_AP);
    }

    my $param = 'rtag=' . $rtag . '&key=' . $k . '&t=' . $time . '&tkn=' . $tkn;
    my $site = $self->site;
    $site =~ s/([\W])/"%" . uc(sprintf("%2.2x",ord($1)))/eg;
    $param .= '&appk=' . $self->appkey .'&ref=' . $site . '&fmt=json';

    my $ua = LWP::UserAgent->new();
    $ua->agent("WWW::PlaceEngine/$VERSION");
    $ua->default_header('Referer' => $self->site);
    my $res = $ua->get($self->host . '/loc?' . $param);
    return $self->set_err($ERR_NO_HOST) if !$res->is_success;
    
    my $cont = $res->content;
    my $respobj = jsonToObj($cont);
    my $ret = WWW::PlaceEngine::Object->new($numap,@{$respobj});

    if ($ret->range == -110) {
        return $self->set_err($ERR_BAD_APKEY);
    } elsif ($ret->range == -100) {
        return $self->set_err($ERR_NO_LOC);
    } elsif ($ret->range <= 0) {
        return $self->set_err($ERR_NO_AP);
    }
    return $ret;
}

##############################################################################
# ERROR 
##############################################################################

sub set_err {
    my $self = shift;
    my ($errcode,$err) = @_;

    $self->errcode($errcode || 0);
    $self->err( $err || $ERROR_TABLE->{$errcode} );

    return;
}

1;

__END__

=pod

=head1 NAME

WWW::PlaceEngine - get PC's location information from PlaceEngine.

=head1 SYNOPSIS

 use WWW::PlaceEngine;
 
 my $wpl = WWW::PlaceEngine->new();
 
 my $loc = $wpl->get_location() or die $wpl->errcode;

=head1 DESCRIPTION

This module get PC's location information from PlaceEngine client and API host.
For PlaceEngine, See to http://www.placeengine.com/.

=head1 METHODS

=over 4

=item new()

=item new( %options )

returns a WWW::PlaceEngine object.

 my $wpl = WWW::PlaceEngine->new();

C<new> can take some options.

 my $wpl = WWW::PlaceEngine->new(site => 'http://example.com/', appkey => 'WRO4eQ....UgTWFw');

Following options are supported:

=over 4

=item site

=item appkey

PlaceEngine needs site page URL and appkey for site pair to get location information from host.
By default, site and appkey are set to http://www.placeengine.com/map and its appkey. 
You can change them your own site and appkey pair to by this option.

=item host

URL of PlaceEngine API host.
http://www.placeengine.com/api by default.

=item rtagd
URL of PlaceEngine client daemon.
http://localhost:5448 by default.

=back 

=item site()

=item site( $site )

get or set site page URL by this method.

=item appkey()

=item appkey( $appkey )

get or set appkey for site by this method.

=item host()

=item host( $host )

get or set URL of PlaceEngine API host by this method.

=item rtagd()

=item rtagd( $rtagd )

get or set URL of PlaceEngine client daemon by this method.

=item get_location()

get PC's location information from PlaceEngine client and API host.
This returns WWW::PlaceEngine::Object object for normal value.
If error occurs, this returns undef value.

=item err

returns error string if error occurs.

=item errcode

return error code if error occurs.

=back

=head1 DEPENDENCIES

Readonly
JSON

=head1 SEE ALSO

http://www.placeengine.com/
WWW::PlaceEngine::Object

=head1 AUTHOR

OHTSUKA Ko-hei, E<lt>nene[at]kokogiko.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by OHTSUKA Ko-hei

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
