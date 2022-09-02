use v5.18;
use warnings;
use Wx;

package App::Harmonograph::GUI::Part::Board;
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
    $dc->SetBackground( $bgb );
    $dc->Clear();
    $self->osc( $dc ) if ref $self->{'data'} and ref $self->{'data'}{'x'};
    1;
}

sub osc {
    my( $self, $dc ) = @_;
    my $bgb = Wx::Brush->new( Wx::Colour->new( 255, 255, 255 ), &Wx::wxBRUSHSTYLE_SOLID );
    $dc->SetBackground( $bgb );
    $dc->Clear();

    my $start_color = Wx::Colour->new( $self->{'data'}{'start_color'}{'red'}, 
                                       $self->{'data'}{'start_color'}{'green'}, 
                                       $self->{'data'}{'start_color'}{'blue'} );

    $dc->SetPen( Wx::Pen->new( $start_color, $self->{'data'}{'line'}{'thickness'}, &Wx::wxPENSTYLE_SOLID) );

    my $cx = $self->{'center'}{'x'};
    my $cy = $self->{'center'}{'y'};
    my $max_freq = abs $self->{'data'}{'x'}{'frequency'};
    $max_freq = abs $self->{'data'}{'y'}{'frequency'} if $max_freq < abs $self->{'data'}{'y'}{'frequency'};
    $max_freq = abs $self->{'data'}{'z'}{'frequency'} if $max_freq < abs $self->{'data'}{'z'}{'frequency'};
    
    my $step_in_circle = $self->{'data'}{'line'}{'density'} * 10 * $max_freq;
    my $t_iter = $self->{'data'}{'line'}{'length'} * $step_in_circle;
    my $xdamp  = $self->{'data'}{'x'}{'damp'} ? 1 - ($self->{'data'}{'x'}{'damp'}/10000/$step_in_circle) : 0;
    my $ydamp  = $self->{'data'}{'y'}{'damp'} ? 1 - ($self->{'data'}{'y'}{'damp'}/10000/$step_in_circle) : 0;
    my $zdamp  = $self->{'data'}{'z'}{'damp'} ? 1 - ($self->{'data'}{'z'}{'damp'}/10000/$step_in_circle) : 0;

    my $rx = $self->{'data'}{'x'}{'radius'} * $self->{'hard_radius'};
    my $ry = $self->{'data'}{'y'}{'radius'} * $self->{'hard_radius'};
    if ($self->{'data'}{'z'}{'on'}){
        $rx *= 2 * $self->{'data'}{'z'}{'radius'} / 3;
        $ry *= 2 * $self->{'data'}{'z'}{'radius'} / 3;
    }
    
    my $dtx =   $self->{'data'}{'x'}{'frequency'} * $TAU / $step_in_circle;
    my $dty = - $self->{'data'}{'y'}{'frequency'} * $TAU / $step_in_circle;
    my $dtz =   $self->{'data'}{'z'}{'frequency'} * $TAU / $step_in_circle;
    $dtx =      0 unless $self->{'data'}{'x'}{'on'};
    $dty =      0 unless $self->{'data'}{'y'}{'on'};
    $dtz =      0 unless $self->{'data'}{'z'}{'on'};
    my $tx = my $ty = my $tz = 0;
    $tx += $TAU * $self->{'data'}{'x'}{'offset'} if $self->{'data'}{'x'}{'offset'};
    $ty += $TAU * $self->{'data'}{'y'}{'offset'} if $self->{'data'}{'y'}{'offset'};
    $tz += $TAU * $self->{'data'}{'z'}{'offset'} if $self->{'data'}{'z'}{'offset'};
    my ($x, $y);
    if ($self->{'data'}{'color_flow'}{'type'} eq 'no'){
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
        my $cflow = $self->{'data'}{'color_flow'};
        my $color_change_time;
        my @color;
        my $color_index = 1;
        my $startc = App::Harmonograph::Color->new( @{$self->{'data'}{'start_color'}}{'red', 'green', 'blue'} );
        my $endc = App::Harmonograph::Color->new( @{$self->{'data'}{'end_color'}}{'red', 'green', 'blue'} );
        if ($cflow->{'type'} eq 'linear'){
            my $color_count = int ($self->{'data'}{'line'}{'length'} / $cflow->{'stepsize'});
            @color = map {[$_->rgb] } $startc->gradient_to( $endc, $color_count + 1, $cflow->{'dynamic'} );
        } elsif ($cflow->{'type'} eq 'alter'){
            return unless exists $cflow->{'period'} and $cflow->{'period'} > 1;
            @color = map {[$_->rgb]} $startc->gradient_to( $endc, $cflow->{'period'}, $cflow->{'dynamic'} );
            my @tc = reverse @color;
            pop @tc;
            shift @tc;
            push @color, @tc;
            @tc = @color;
            my $color_circle_length = (2 * $cflow->{'period'} - 2) * $cflow->{'stepsize'};
            push @color, @tc for 0 .. int ($self->{'data'}{'line'}{'length'} / $color_circle_length);
        } else {
            return unless exists $cflow->{'period'} and $cflow->{'period'} > 1;
            @color = map {[$_->rgb]} $startc->complementary( $cflow->{'period'}, 
                                                             $endc->saturation - $startc->saturation,
                                                             $endc->lightness - $startc->lightness);
            my @tc = @color;
            push @color, @tc for 0 .. int ($self->{'data'}{'line'}{'length'} / $cflow->{'period'} / $cflow->{'stepsize'});
        }
        $color_change_time = $step_in_circle * $cflow->{'stepsize'};
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
                    Wx::Pen->new( Wx::Colour->new( @{$color[$color_index++]} ), $self->{'data'}{'line'}{'thickness'}, &Wx::wxPENSTYLE_SOLID) 
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
                    Wx::Pen->new( Wx::Colour->new( @{$color[$color_index++]} ), $self->{'data'}{'line'}{'thickness'}, &Wx::wxPENSTYLE_SOLID) 
                ) unless $_ % $color_change_time;
            }
        }
    }
}

sub save_file {
    my( $self, $file_name ) = @_;
    my ($x, $y) = ($self->{'size'}{'x'}, $self->{'size'}{'y'});
    my $dc = Wx::SVGFileDC->new( $file_name, $x, $y, 200 );
    $self->osc( $dc );
}

1;
    # $dc->Blit( 0,0, $x, $y, $self->{'dc'}, 0,0,$x, $y );
    # bool Blit (wxCoord xdest, wxCoord ydest, wxCoord width, wxCoord height, wxDC *source, wxCoord xsrc, wxCoord ysrc, wxRasterOperationMode logicalFunc=wxCOPY, bool useMask=false, wxCoord xsrcMask=wxDefaultCoord, wxCoord ysrcMask=wxDefaultCoord)
    # $dc->SetBrush( $fgb );
