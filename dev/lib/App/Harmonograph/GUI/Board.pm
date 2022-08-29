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
    $self->{'hard_radius'} = ($x > $y ? $self->{'center'}{'y'} : $self->{'center'}{'x'}) - 20;

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
    my $bgb = Wx::Brush->new( Wx::Colour->new( 255, 255, 255 ), &Wx::wxBRUSHSTYLE_SOLID );
    # $dc->SetBrush( $fgb );
    $dc->SetBackground( $bgb );
    $dc->Clear();

    if (ref $self->{'data'} and ref $self->{'data'}{'x'}) {
        my $start_color = Wx::Colour->new( $self->{'data'}{'start_color'}{'r'}, 
                                           $self->{'data'}{'start_color'}{'g'}, 
                                           $self->{'data'}{'start_color'}{'b'} );
        my $target_color = Wx::Colour->new( $self->{'data'}{'target_color'}{'r'}, 
                                            $self->{'data'}{'target_color'}{'g'}, 
                                            $self->{'data'}{'target_color'}{'b'} );
        $dc->SetPen( Wx::Pen->new( $start_color, $self->{'data'}{'ps'}, &Wx::wxPENSTYLE_SOLID) );

        my $max_freq = $self->{'data'}{'x'}{'freq'};
        $max_freq = $self->{'data'}{'y'}{'freq'} if $max_freq < $self->{'data'}{'y'}{'freq'};
        $max_freq = $self->{'data'}{'z'}{'freq'} if $max_freq < $self->{'data'}{'z'}{'freq'};
        
        my $step_in_circle = $self->{'data'}{'dt'} * 10 * $max_freq;
        my $cx = $self->{'center'}{'x'};
        my $cy = $self->{'center'}{'y'};
        my $t_iter = $self->{'data'}{'time'} * $step_in_circle;
        my $xdamp  = $self->{'data'}{'x'}{'damp'} ? 1 - ($self->{'data'}{'x'}{'damp'}/500/$step_in_circle) : 0;
        my $ydamp  = $self->{'data'}{'y'}{'damp'} ? 1 - ($self->{'data'}{'y'}{'damp'}/500/$step_in_circle) : 0;
        my $zdamp  = $self->{'data'}{'z'}{'damp'} ? 1 - ($self->{'data'}{'z'}{'damp'}/500/$step_in_circle) : 0;

        my $rx = $self->{'data'}{'x'}{'radius'} * $self->{'hard_radius'};
        my $ry = $self->{'data'}{'y'}{'radius'} * $self->{'hard_radius'};
        if ($self->{'data'}{'z'}{'on'}){
            $rx *= 2 * $self->{'data'}{'z'}{'radius'} / 3;
            $ry *= 2 * $self->{'data'}{'z'}{'radius'} / 3;
        }
        
        my $dtx =   $self->{'data'}{'x'}{'freq'} * $TAU / $step_in_circle;
        my $dty = - $self->{'data'}{'y'}{'freq'} * $TAU / $step_in_circle;
        my $dtz =   $self->{'data'}{'z'}{'freq'} * $TAU / $step_in_circle;
        $dtx = - $dtx if    $self->{'data'}{'x'}{'dir'};
        $dty = - $dty if    $self->{'data'}{'y'}{'dir'};
        $dtz = - $dtx if    $self->{'data'}{'z'}{'dir'};
        $dtx =      0 unless $self->{'data'}{'x'}{'on'};
        $dty =      0 unless $self->{'data'}{'y'}{'on'};
        $dtz =      0 unless $self->{'data'}{'z'}{'on'};
        my $tx = my $ty = my $tz = 0;
        $tx += $TAU * $self->{'data'}{'x'}{'offset'} if $self->{'data'}{'x'}{'offset'};
        $ty += $TAU * $self->{'data'}{'y'}{'offset'} if $self->{'data'}{'y'}{'offset'};
        $tz += $TAU * $self->{'data'}{'z'}{'offset'} if $self->{'data'}{'z'}{'offset'};
        my ($x, $y);
        if ($self->{'data'}{'cftype'} eq 'no'){
            if ($dtz){
                for (1 .. $t_iter){ # with Z pendulum
                    ($x, $y) =      ( cos $tx,           sin $ty );                  # Wave func
                    ($x, $y) = (($x * cos($tz) ) - ($y * sin($tz) ),                # Rot Matrix
                                ($x * sin($tz) ) + ($y * cos($tz) ) );
                    $dc->DrawPoint( $cx + $rx * $x, $cy + $ry * $y );
                    $tx += $dtx;
                    $ty += $dty;
                    $tz += $dtz;
                    $rx *= $xdamp if $xdamp;
                    $ry *= $ydamp  if $ydamp;
                    $dtz *= $zdamp  if $zdamp;
                }
            } else {                 # 2 pendulums : X Y
                for (1 .. $t_iter){
                    $dc->DrawPoint( $cx + ($rx * cos $tx), $cy + ($ry * sin $ty ) );
                    $tx += $dtx;
                    $ty += $dty;
                    $rx *= $xdamp if $xdamp;
                    $ry *= $ydamp if $ydamp;
                }
            }
        } else {
            my $color_change_time = $step_in_circle * $self->{'data'}{'stepsize'};
            my @color;
            my $color_index = 0;
            if ($self->{'data'}{'cftype'} eq 'linear'){
                my $color_count = int $self->{'data'}{'time'} / $self->{'data'}{'stepsize'};
                @color = map {[$_->rgb] } 
                    App::Harmonograph::Color->new( @{$self->{'data'}{'start_color'}}{'r', 'g', 'b'} )
                        ->gradient_to( [@{$self->{'data'}{'target_color'}}{'r', 'g', 'b'}], $color_count + 1 );
                shift @color;
            } else {
            }
            if ($dtz){
                for (1 .. $t_iter){ # with Z pendulum
                    ($x, $y) =      ( cos $tx,           sin $ty );                  # Wave func
                    ($x, $y) = (($x * cos($tz) ) - ($y * sin($tz) ),                # Rot Matrix
                                ($x * sin($tz) ) + ($y * cos($tz) ) );
                    $dc->DrawPoint( $cx + $rx * $x, $cy + $ry * $y );
                    $tx += $dtx;
                    $ty += $dty;
                    $tz += $dtz;
                    $rx *= $xdamp if $xdamp;
                    $ry *= $ydamp  if $ydamp;
                    $dtz *= $zdamp  if $zdamp;
                    $dc->SetPen( 
                        Wx::Pen->new( Wx::Colour->new( @{$color[$color_index++]} ), $self->{'data'}{'ps'}, &Wx::wxPENSTYLE_SOLID) 
                    ) unless $_ % $color_change_time;
                }
            } else {                 # 2 pendulums : X Y
                for (1 .. $t_iter){
                    $dc->DrawPoint( $cx + ($rx * cos $tx), $cy + ($ry * sin $ty ) );
                    $tx += $dtx;
                    $ty += $dty;
                    $rx *= $xdamp if $xdamp;
                    $ry *= $ydamp if $ydamp;
                    $dc->SetPen( 
                        Wx::Pen->new( Wx::Colour->new( @{$color[$color_index++]} ), $self->{'data'}{'ps'}, &Wx::wxPENSTYLE_SOLID) 
                    ) unless $_ % $color_change_time;
                }
            }
        }
    }
    1;
}

sub save_file {
    my( $self, $file_name ) = @_;
    
}



1;
