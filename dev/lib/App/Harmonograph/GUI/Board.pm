use v5.18;
use warnings;
use Wx;

package App::Harmonograph::GUI::Board;
my $VERSION = 0.03;
use base qw/Wx::Panel/;
use Wx::Event qw(EVT_PAINT);
my $TAU = 6.283185307;

sub new {
    my ( $class, $parent, $x, $y ) = @_;
    my $self = $class->SUPER::new( $parent, -1, [-1,-1], [$x, $y] );
    $self->{'size'}{'x'} = $x;
    $self->{'size'}{'y'} = $y;
    $self->{'center'}{'x'} = $x / 2;
    $self->{'center'}{'y'} = $y / 2;
    $self->{'radius'} = ($x > $y ? $self->{'center'}{'y'} : $self->{'center'}{'x'}) - 20;

    # Wx::InitAllImageHandlers();
    EVT_PAINT( $self, \&paint );
    return $self;
}

sub set_data {
    my( $self, $data ) = @_;
    return unless ref $data eq 'HASH';
    $self->{'data'} = $data;
}

sub paint {
    my( $self, $event ) = @_;
    my $dc = Wx::PaintDC->new( $self );
    my $gct = Wx::GraphicsContext::Create( $dc );
    #my $path = $gct->CreatePath;
    my $bgb = Wx::Brush->new( Wx::Colour->new( 255, 255, 255 ), &Wx::wxBRUSHSTYLE_SOLID );
#    my $fgb = Wx::Brush->new( Wx::Colour->new( 120,  20,  20 ), &Wx::wxBRUSHSTYLE_SOLID );
#    $dc->SetBrush( $fgb );
    $dc->SetBackground( $bgb );
    $dc->Clear();

    if (ref $self->{'data'} and ref $self->{'data'}{'x'}) {
        my $gridcol = Wx::Colour->new( $self->{'data'}{'color'}{'r'}, $self->{'data'}{'color'}{'g'}, $self->{'data'}{'color'}{'b'});
        $dc->SetPen( Wx::Pen->new( $gridcol, $self->{'data'}{'ps'}, &Wx::wxPENSTYLE_SOLID) );
        
        my $step_in_circle = $self->{'data'}{'dt'};
        my $t_iter = $self->{'data'}{'t'} * $TAU * $step_in_circle;
        my $damp = $self->{'data'}{'dr'} ? 1 - ($self->{'data'}{'dr'}/1000/$step_in_circle) : 0;
        my $r = $self->{'radius'};
        
        my $dtx =   $self->{'data'}{'x'}{'f'} / $step_in_circle;
        my $dty = - $self->{'data'}{'y'}{'f'} / $step_in_circle;
        my $dtz =   $self->{'data'}{'z'}{'f'} / $step_in_circle;
        $dtx = - $dtx if    $self->{'data'}{'x'}{'dir'};
        $dty = - $dty if    $self->{'data'}{'y'}{'dir'};
        $dtz = - $dtx if    $self->{'data'}{'z'}{'dir'};
        $dtx =      0 unless $self->{'data'}{'x'}{'on'};
        $dty =      0 unless $self->{'data'}{'y'}{'on'};
        $dtz =      0 unless $self->{'data'}{'z'}{'on'};
        $r /= 1.5     if     $self->{'data'}{'z'}{'on'};
        my $tx = my $ty = my $tz = 0;
        $tx += $TAU * $self->{'data'}{'x'}{'offset'} if $self->{'data'}{'x'}{'offset'} ;
        $ty += $TAU * $self->{'data'}{'y'}{'offset'} if $self->{'data'}{'y'}{'offset'};
        $tz += $TAU * $self->{'data'}{'z'}{'offset'} if $self->{'data'}{'z'}{'offset'};
        my ($x, $y);
        for (1 .. $t_iter){
            ($x, $y) =      ( cos $tx,          sin $ty );                  # Wave func
            ($x, $y) = (($x * cos($tz) ) - ($y * sin($tz) ),                # Rot Matrix
                        ($x * sin($tz) ) + ($y * cos($tz) ) ) if $dtz;
            $dc->DrawPoint( $self->{'center'}{'x'} + $r * $x, 
                            $self->{'center'}{'y'} + $r * $y );
            $tx += $dtx;
            $ty += $dty;
            $tz += $dtz;
            $r *= $damp if $damp;
        }
    }
    #$dc->SetPen(Wx::Pen->new( $gridcol, 3, &Wx::wxPENSTYLE_SOLID));
    #$dc->DrawCircle() # x y r
    #$dc->DrawLine( $_, 13, $_,527) for 10, 169, 327, 486;
    #$dc->DrawLine( 11, $_,484, $_) for 13, 186, 359, 528;
    #$dc->SetPen(Wx::Pen->new( Wx::Colour->new(20, 20, 110), 1, &Wx::wxPENSTYLE_DOT));
    #$dc->DrawLine( $_, 12, $_,527) for 65, 115, 223, 273, 381, 431;
    #$dc->DrawLine( 10, $_,484, $_) for 72, 127, 245, 300, 418, 473;

    #my $os = Wx::wxMAC() ? 1 : Wx::wxMSW() ? 3 : 2;
    #my $candfond = Wx::Font->new(($os == 1 ? 12 : 10), &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_NORMAL, 0, 'Helvetica');
    #$gct->SetFont( $gct->CreateFont( $candfond , Wx::Colour->new( 120, 120, 120 )));
    #my $solfond = Wx::Font->new(($os == 1 ? 25 : 22), &Wx::wxFONTFAMILY_DEFAULT,&Wx::wxFONTSTYLE_NORMAL,&Wx::wxFONTWEIGHT_NORMAL,0,'Arial' );
    #$gct->SetFont( $gct->CreateFont( $solfond , $gridcol));
    $self->Refresh if $self->{'data'}{'new'};
    1;
}

sub save_file {
    my( $self, $file_name ) = @_;
    
}



1;
