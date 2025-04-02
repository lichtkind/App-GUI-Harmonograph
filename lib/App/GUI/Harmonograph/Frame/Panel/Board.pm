
# painting area on left side

package App::GUI::Harmonograph::Frame::Panel::Board;
use v5.12;
use warnings;
use utf8;
use Wx;
use base qw/Wx::Panel/;
# use Benchmark;
use Graphics::Toolkit::Color qw/color/;
use App::GUI::Harmonograph::Compute::Function;
use App::GUI::Harmonograph::Compute::Drawing;

my $TAU = 6.283185307;

sub new {
    my ( $class, $parent, $x, $y ) = @_;
    my $self = $class->SUPER::new( $parent, -1, [-1,-1], [$x, $y] );
    $self->{'precision'} = 4;
    $self->{'menu_size'} = 27;
    $self->{'size'}{'x'} = $x;
    $self->{'size'}{'y'} = $y;
    $self->{'center'}{'x'} = $x / 2;
    $self->{'center'}{'y'} = $y / 2;
    $self->{'hard_radius'} = ($x > $y ? $self->{'center'}{'y'} : $self->{'center'}{'x'});
    $self->{'bmp'} = Wx::Bitmap->new( $self->{'size'}{'x'} + 10, $self->{'size'}{'y'} +10 + $self->{'menu_size'}, 24);
    $self->{'dc'} = Wx::MemoryDC->new( );
    $self->{'dc'}->SelectObject( $self->{'bmp'} );

    Wx::Event::EVT_PAINT( $self, sub {
        my( $self, $event ) = @_;
        return unless ref $self->{'settings'} and ref $self->{'settings'}{'x'};
        $self->{'x_pos'} = $self->GetPosition->x;
        $self->{'y_pos'} = $self->GetPosition->y;

        if (exists $self->{'flag'}{'new'}) {
            $self->{'dc'}->Blit (0, 0, $self->{'size'}{'x'} + $self->{'x_pos'},
                                       $self->{'size'}{'y'} + $self->{'y_pos'} + $self->{'menu_size'},
                                       $self->paint( Wx::PaintDC->new( $self ), $self->{'size'}{'x'}, $self->{'size'}{'y'} ), 0, 0);
        } else {
            Wx::PaintDC->new( $self )->Blit (0, 0, $self->{'size'}{'x'},
                                                   $self->{'size'}{'y'} + $self->{'menu_size'},
                                                   $self->{'dc'},
                                                   $self->{'x_pos'} , $self->{'y_pos'} + $self->{'menu_size'} );
        }
        1;
    }); # Blit (xdest, ydest, width, height, DC *src, xsrc, ysrc, wxRasterOperationMode logicalFunc=wxCOPY, bool useMask=false)
    return $self;
}

sub draw {
    my( $self, $settings ) = @_;
    return unless $self->set_settings( $settings );
    $self->Refresh;
}
sub sketch {
    my( $self, $settings ) = @_;
    return unless $self->set_settings( $settings );
    $self->{'flag'}{'sketch'} = 1;
    $self->Refresh;
}
sub set_settings {
    my( $self, $settings ) = @_;
    return unless ref $settings eq 'HASH';
    $self->GetParent->{'progress'}->reset;
    $self->{'settings'} = $settings;
    $self->{'flag'}{'new'} = 1;
}


sub paint {
    my( $self, $dc, $width, $height ) = @_; # my $t = Benchmark->new;
    my $val = $self->{'settings'};
    my $progress = $self->GetParent->{'progress'};

    my $Cx = (defined $width)  ? ($width / 2)  : $self->{'center'}{'x'};
    my $Cy = (defined $height) ? ($height / 2) : $self->{'center'}{'y'};
    my $Cr = (defined $height) ? ($width > $height ? $Cx : $Cy) : $self->{'hard_radius'};
    $Cr -= 15;

   # my $ = App::GUI::Harmonograph::Compute::Drawing::prepare( $val, $Cr, $self->{'flag'}{'sketch'} );

    my %var_names = ( x_time => '$tx', y_time => '$ty', z_time => '$tz', r_time => '$tr',
                      x_freq => '$dtx', y_freq => '$dty', z_freq => '$dtz', r_freq => '$dtr',
                      x_radius => '$rx', y_radius => '$ry', z_radius => '$rz', r_radius => '$rr',
                      zero => '0', one => '1');

    my $start_color = Wx::Colour->new( 0, 20, 200 ); # @{$val->{'start_color'}}{'red', 'green', 'blue'}
    $dc->SetBackground( Wx::Brush->new( Wx::Colour->new( 255, 255, 255 ), &Wx::wxBRUSHSTYLE_SOLID ) );
    $dc->Clear();
    $dc->SetPen( Wx::Pen->new( $start_color, $val->{'visual'}{'line_thickness'}, &Wx::wxPENSTYLE_SOLID) );
    #$dc->SetBrush( Wx::Brush->new( $start_color, &Wx::wxBRUSHSTYLE_STIPPLE) );

    my $dot_per_sec = ($val->{'visual'}{'dot_density'} || 1);
    my $t_iter = (exists $self->{'flag'}{'sketch'}) ? 5 : $val->{'visual'}{'duration'};
    $t_iter *= $dot_per_sec;
    $val->{'visual'}{'connect_dots'} = int ($val->{'visual'}{'draw'} eq 'Line');

    my $fX = $val->{'x'}{'frequency'} * $val->{'x'}{'freq_factor'};
    my $fY = $val->{'y'}{'frequency'} * $val->{'y'}{'freq_factor'};
    my $fZ = $val->{'z'}{'frequency'} * $val->{'z'}{'freq_factor'};
    my $fR = $val->{'r'}{'frequency'} * $val->{'r'}{'freq_factor'};
    my $dfX = $val->{'x'}{'freq_damp'} / $dot_per_sec / 1_000_000;
    my $dfY = $val->{'y'}{'freq_damp'} / $dot_per_sec / 1_000_000;
    my $dfZ = $val->{'z'}{'freq_damp'} / $dot_per_sec / 1_000_000;
    my $dfR = $val->{'r'}{'freq_damp'} / $dot_per_sec / 1_000_000;
    my $ddfX = $val->{'x'}{'freq_damp_acc'} / $dot_per_sec / 2_000_000_000;
    my $ddfY = $val->{'y'}{'freq_damp_acc'} / $dot_per_sec / 2_000_000_000;
    my $ddfZ = $val->{'z'}{'freq_damp_acc'} / $dot_per_sec / 2_000_000_000;
    my $ddfR = $val->{'r'}{'freq_damp_acc'} / $dot_per_sec / 2_000_000_000;
    if ($val->{'x'}{'direction'}){  $fX = - $fX;   $dfX = - $dfX; }
    if ($val->{'y'}{'direction'}){  $fY = - $fY;   $dfY = - $dfY; }
    if ($val->{'z'}{'direction'}){  $fZ = - $fZ;   $dfZ = - $dfZ; }
    if ($val->{'r'}{'direction'}){  $fR = - $fR;   $dfR = - $dfR; }
    if ($val->{'x'}{'invert_freq'}){$fX = 1 / $fX; $dfX = $dfX / $fX; }
    if ($val->{'y'}{'invert_freq'}){$fY = 1 / $fY; $dfY = $dfX / $fY; }
    if ($val->{'z'}{'invert_freq'}){$fZ = 1 / $fZ; $dfZ = $dfZ / $fZ; }
    if ($val->{'r'}{'invert_freq'}){$fR = 1 / $fR; $dfR = $dfR / $fR; }
    $dfX = 1 - ($dfX * 20) if $val->{'x'}{'freq_damp_type'} eq '*';
    $dfY = 1 - ($dfY * 20) if $val->{'y'}{'freq_damp_type'} eq '*';
    $dfZ = 1 - ($dfZ * 20) if $val->{'z'}{'freq_damp_type'} eq '*';
    $dfR = 1 - ($dfR * 20) if $val->{'r'}{'freq_damp_type'} eq '*';
    $ddfX = 1 - ($ddfX * 20) if $val->{'x'}{'freq_damp_acc_type'} eq '*' or $val->{'x'}{'freq_damp_acc_type'} eq '/';
    $ddfY = 1 - ($ddfY * 20) if $val->{'y'}{'freq_damp_acc_type'} eq '*' or $val->{'y'}{'freq_damp_acc_type'} eq '/';
    $ddfZ = 1 - ($ddfZ * 20) if $val->{'z'}{'freq_damp_acc_type'} eq '*' or $val->{'z'}{'freq_damp_acc_type'} eq '/';
    $ddfR = 1 - ($ddfR * 20) if $val->{'r'}{'freq_damp_acc_type'} eq '*' or $val->{'r'}{'freq_damp_acc_type'} eq '/';

    my $rX = $val->{'x'}{'radius'} * $Cr;
    my $rY = $val->{'y'}{'radius'} * $Cr;
    my $rZ = $val->{'z'}{'radius'} * $Cr;
    my $rR = $val->{'r'}{'radius'} * $Cr;
    my $drX = $val->{'x'}{'radius_damp'} / $dot_per_sec / 1_300 * $Cr;
    my $drY = $val->{'y'}{'radius_damp'} / $dot_per_sec / 1_300 * $Cr;
    my $drZ = $val->{'z'}{'radius_damp'} / $dot_per_sec / 1_300 * $Cr;
    my $drR = $val->{'r'}{'radius_damp'} / $dot_per_sec / 1_300 * $Cr;
    my $ddrX = $val->{'x'}{'radius_damp_acc'} / $dot_per_sec / 300_000_000;
    my $ddrY = $val->{'y'}{'radius_damp_acc'} / $dot_per_sec / 300_000_000;
    my $ddrZ = $val->{'z'}{'radius_damp_acc'} / $dot_per_sec / 300_000_000;
    my $ddrR = $val->{'r'}{'radius_damp_acc'} / $dot_per_sec / 300_000_000;
    $drX = 1 - ($drX / 300) if $val->{'x'}{'radius_damp_type'} eq '*';
    $drY = 1 - ($drY / 300) if $val->{'y'}{'radius_damp_type'} eq '*';
    $drZ = 1 - ($drZ / 300) if $val->{'z'}{'radius_damp_type'} eq '*';
    $drR = 1 - ($drR / 300) if $val->{'r'}{'radius_damp_type'} eq '*';

    my $tX = $val->{'x'}{'offset'} * $TAU;
    my $tY = $val->{'y'}{'offset'} * $TAU;
    my $tZ = $val->{'z'}{'offset'} * $TAU;
    my $tR = $val->{'r'}{'offset'} * $TAU;
    my $dtX = $TAU * $fX / $dot_per_sec;
    my $dtY = $TAU * $fY / $dot_per_sec;
    my $dtZ = $TAU * $fZ / $dot_per_sec;
    my $dtR = $TAU * $fR / $dot_per_sec;
    my ($x_old, $y_old);
    my $x = $Cx + ($rX * cos($tX));
    my $y = $Cy + ($rY * sin($tY));

    my %delta_code = ( x=> [], y=> [], z=> [], r=> [], ex=> [], ey=> [] );
    for my $pendulum_name (qw/x y z r ex ey/){
        next unless $val->{$pendulum_name}{'on'};
        my $val = $val->{ $pendulum_name };
        my $index = uc $pendulum_name;
        my @code = ('  $t'.$index.' += $dt'.$index);
        if ($val->{'freq_damp'}){
            push @code, '  $dt'.$index.' '.$val->{'freq_damp_type'}.'= $df'.$index;
            push @code, '  $df'.$index.' '.$val->{'freq_damp_acc_type'}.'= $ddf'.$index if $val->{'freq_damp_acc'};
        }
        if ($val->{'radius_damp'}){
            my $code = '  $r'.$index.' '.$val->{'radius_damp_type'}.'= $dr'.$index;
            $code .= ' if $r'.$index.' > 0' if not $val->{'neg_radius'} and $val->{'radius_damp_type'} eq '-';
            push @code, $code;
            push @code, '  $dr'.$index.' '.$val->{'freq_damp_acc_type'}.'= $ddr'.$index if $val->{'radius_damp_acc'};
        }
        push @{$delta_code{$pendulum_name}}, @code;
    }

    my @code = ('for (1 .. $t_iter){');
    push @code, '  ($x_old, $y_old) = ($x, $y)' if $val->{'visual'}{'connect_dots'};
    push @code, @{$delta_code{$_}} for qw/x y z r ex ey/;
    push @code, ($val->{'x'}{'on'} ? '  $x = $rX * cos($tX)' : '  $x = 0');
    push @code, ($val->{'y'}{'on'} ? '  $y = $rY * sin($tY)' : '  $y = 0');
    push @code, '  $x += $Cx', '  $y += $Cy';
    push @code, ($val->{'visual'}{'connect_dots'}
              ? '  $dc->DrawLine( $x_old, $y_old, $x, $y)'
              : '  $dc->DrawPoint( $x, $y )');

   # push @code, ' $dc->SetPen( Wx::Pen->new( $start_color ), 1, &Wx::wxPENSTYLE_SOLID);';
   # push @code, '$progress->add_percentage( $_ / $t_iter * 100, $color[$color_index] ) unless $_ % $step_in_circle;'."\n" unless defined $self->{'flag'}{'sketch'};

    my $code = join '', map {$_.";\n"} @code, '}';
say $code;
    eval $code;
    die "bad iter code - $@ : $code" if $@; # say "comp: ",timestr( timediff( Benchmark->new(), $t) );

    delete $self->{'flag'};
    $dc;
}

sub save_file {
    my( $self, $file_name, $width, $height ) = @_;
    my $file_end = lc substr( $file_name, -3 );
    if ($file_end eq 'svg') { $self->save_svg_file( $file_name, $width, $height ) }
    elsif ($file_end eq 'png' or $file_end eq 'jpg') { $self->save_bmp_file( $file_name, $file_end, $width, $height ) }
    else { return "unknown file ending: '$file_end'" }
}

sub save_svg_file {
    my( $self, $file_name, $width, $height ) = @_;
    $width  //= $self->GetParent->{'config'}->get_value('image_size');
    $height //= $self->GetParent->{'config'}->get_value('image_size');
    $width  //= $self->{'size'}{'x'};
    $height //= $self->{'size'}{'y'};
    my $dc = Wx::SVGFileDC->new( $file_name, $width, $height, 250 );  #  250 dpi
    $self->paint( $dc, $width, $height );
}

sub save_bmp_file {
    my( $self, $file_name, $file_end, $width, $height ) = @_;
    $width  //= $self->GetParent->{'config'}->get_value('image_size');
    $height //= $self->GetParent->{'config'}->get_value('image_size');
    $width  //= $self->{'size'}{'x'};
    $height //= $self->{'size'}{'y'};
    my $bmp = Wx::Bitmap->new( $width, $height, 24); # bit depth
    my $dc = Wx::MemoryDC->new( );
    $dc->SelectObject( $bmp );
    $self->paint( $dc, $width, $height);
    # $dc->Blit (0, 0, $width, $height, $self->{'dc'}, 10, 10 + $self->{'menu_size'});
    $dc->SelectObject( &Wx::wxNullBitmap );
    $bmp->SaveFile( $file_name, $file_end eq 'png' ? &Wx::wxBITMAP_TYPE_PNG : &Wx::wxBITMAP_TYPE_JPEG );
}

1;

__END__

    $fx *= ($base_factor->{ $val->{'x'}{'freq_factor'} } // 1);
    $fy *= ($base_factor->{ $val->{'y'}{'freq_factor'} } // 1);
    $fz *= ($base_factor->{ $val->{'z'}{'freq_factor'} } // 1);
    $fr *= ($base_factor->{ $val->{'r'}{'freq_factor'} } // 1);

    my $max_freq = abs $fx;
    $max_freq = abs $fy if $max_freq < abs $fy ;
    $max_freq = abs $fz if $max_freq < abs $fz;
    $max_freq = abs $fr if $max_freq < abs $fr;

    my $step_in_circle = $val->{'line'}{'density'} * $val->{'line'}{'density'} * $max_freq;
    my $t_iter =         exists $self->{'flag'}{'sketch'}
               ? 5 * $step_in_circle
               : $val->{'line'}{'length'} * $step_in_circle;

    my $rx = $val->{'x'}{'radius'} * $raster_radius;
    my $ry = $val->{'y'}{'radius'} * $raster_radius;
    my $rz = $val->{'z'}{'radius'} * $raster_radius;
    my $rr = $val->{'r'}{'radius'} * $raster_radius;
    if ($val->{'z'}{'on'}){
        $rx *= $val->{'z'}{'radius'} / 2;
        $ry *= $val->{'z'}{'radius'} / 2;
        $rz /=                         2;
    }
    if ($val->{'r'}{'on'}){
        $rx *= 2 * $val->{'r'}{'radius'} / 3;
        $ry *= 2 * $val->{'r'}{'radius'} / 3;
    }

    my $rxdamp  = (not $val->{'x'}{'radius_damp'}) ? 0 :
          ($val->{'x'}{'radius_damp_type'} eq '*') ? 1 - ($val->{'x'}{'radius_damp'} / 1000 / $step_in_circle)
                                                   : $rx * $val->{'x'}{'radius_damp'}/ 2000 / $step_in_circle;
    my $rydamp  = (not $val->{'y'}{'radius_damp'}) ? 0 :
          ($val->{'y'}{'radius_damp_type'} eq '*') ? 1 - ($val->{'y'}{'radius_damp'} / 1000 / $step_in_circle)
                                                   : $ry * $val->{'y'}{'radius_damp'}/ 2000 / $step_in_circle;
    my $rzdamp  = (not $val->{'z'}{'radius_damp'}) ? 0 :
          ($val->{'z'}{'radius_damp_type'} eq '*') ? 1 - ($val->{'z'}{'radius_damp'} / 1500 / $step_in_circle)
                                                            : $rz * $val->{'z'}{'radius_damp'}/ 3000 / $step_in_circle;
    my $rrdamp  = (not $val->{'r'}{'radius_damp'}) ? 0 :
          ($val->{'r'}{'radius_damp_type'} eq '*') ? 1 - ($val->{'r'}{'radius_damp'} / 1000 / $step_in_circle)
                                                   : $rr * $val->{'r'}{'radius_damp'}/ 2000 / $step_in_circle;
    my $rxdacc  = (not $val->{'x'}{'radius_damp_acc'}) ? 0 :
          ($val->{'x'}{'radius_damp_acc_type'} eq '*') ? 1 - ($val->{'x'}{'radius_damp_acc'} / 1_000_000 / $step_in_circle) :
          ($val->{'x'}{'radius_damp_acc_type'} eq '/') ? 1 + ($val->{'x'}{'radius_damp_acc'} / 1_000_000 / $step_in_circle)
                                                                : $rx * $val->{'x'}{'radius_damp_acc'}/ 100_000_000 / $step_in_circle;
    my $rydacc  = (not $val->{'y'}{'radius_damp_acc'}) ? 0 :
          ($val->{'y'}{'radius_damp_acc_type'} eq '*') ? 1 - ($val->{'y'}{'radius_damp_acc'} / 1_000_000 / $step_in_circle) :
          ($val->{'y'}{'radius_damp_acc_type'} eq '/') ? 1 + ($val->{'y'}{'radius_damp_acc'} / 1_000_000 / $step_in_circle)
                                                                : $ry * $val->{'y'}{'radius_damp_acc'}/ 100_000_000 / $step_in_circle;
    my $rzdacc  = (not $val->{'z'}{'radius_damp_acc'}) ? 0 :
          ($val->{'z'}{'radius_damp_acc_type'} eq '*') ? 1 - ($val->{'z'}{'radius_damp_acc'} / 2_000_000 / $step_in_circle) :
          ($val->{'z'}{'radius_damp_acc_type'} eq '/') ? 1 + ($val->{'z'}{'radius_damp_acc'} / 2_000_000 / $step_in_circle)
                                                       : $rz * $val->{'z'}{'radius_damp_acc'}/ 200_000_000 / $step_in_circle;
    my $rrdacc  = (not $val->{'r'}{'radius_damp_acc'}) ? 0 :
          ($val->{'r'}{'radius_damp_acc_type'} eq '*'
        or $val->{'x'}{'radius_damp_acc_type'} eq '/') ? 1 - ($val->{'r'}{'radius_damp_acc'}/ 1000 / $step_in_circle)
                                                       : $rr * $val->{'r'}{'radius_damp_acc'}/20000 / $step_in_circle;

    my $dtx = $val->{'x'}{'on'} ? (  $fx * $TAU / $step_in_circle) : 0;
    my $dty = $val->{'y'}{'on'} ? (  $fy * $TAU / $step_in_circle) : 0;
    my $dtz = $val->{'z'}{'on'} ? (  $fz * $TAU / $step_in_circle) : 0;
    my $dtr = $val->{'r'}{'on'} ? (- $fr * $TAU / $step_in_circle) : 0;

    my $fxdamp  = (not $val->{'x'}{'freq_damp'}) ? 0 :
          ($val->{'x'}{'freq_damp_type'} eq '*') ? 1 - ($val->{'x'}{'freq_damp'}  / 40_000 / $step_in_circle)
                                                 : $dtx * $val->{'x'}{'freq_damp'} / 40 / $step_in_circle;
    my $fydamp  = (not $val->{'y'}{'freq_damp'}) ? 0 :
          ($val->{'y'}{'freq_damp_type'} eq '*') ? 1 - ($val->{'y'}{'freq_damp'}  / 40_000 / $step_in_circle)
                                                 : $dty * $val->{'y'}{'freq_damp'} / 40 / $step_in_circle;
    my $fzdamp  = (not $val->{'z'}{'freq_damp'}) ? 0 :
          ($val->{'z'}{'freq_damp_type'} eq '*') ? 1 - ($val->{'z'}{'freq_damp'}  / 20_000 / $step_in_circle)
                                                 : $dtz * $val->{'z'}{'freq_damp'}/ 20_000 / $step_in_circle;
    my $frdamp  = (not $val->{'r'}{'freq_damp'}) ? 0 :
          ($val->{'r'}{'freq_damp_type'} eq '*') ? 1 - ($val->{'r'}{'freq_damp'}  / 20_000 / $step_in_circle)
                                                 : $dtr * $val->{'r'}{'freq_damp'}/ 20_000 / $step_in_circle;

    my $tx = my $ty = my $tz = my $tr = 0;
    $tx += $TAU * $val->{'x'}{'offset'} if $val->{'x'}{'offset'};
    $ty += $TAU * $val->{'y'}{'offset'} if $val->{'y'}{'offset'};
    $tz += $TAU * $val->{'z'}{'offset'} if $val->{'z'}{'offset'};
    $tr += $TAU * $val->{'r'}{'offset'} if $val->{'r'}{'offset'};
    $tx -= $max_time while $tx >=  $max_time;
    $tx += $max_time while $tx <= -$max_time;
    $ty -= $max_time while $ty >=  $max_time;
    $ty += $max_time while $ty <= -$max_time;
    my ($x, $y);
    my $color_change_time;
    my @color;
    my $color_index = 0;
    my $startc = color( @{$val->{'start_color'}}{'red', 'green', 'blue'} );
    my $endc = color( @{$val->{'end_color'}}{'red', 'green', 'blue'} );
    if ($val->{'color_flow'}{'type'} eq 'linear'){
        my $color_count = int ($val->{'line'}{'length'} / $val->{'color_flow'}{'stepsize'});
        @color = map {[$_->values('rgb')] } $startc->gradient( to => $endc, steps => $color_count + 1, dynamic => $val->{'color_flow'}{'dynamic'} );
    } elsif ($val->{'color_flow'}{'type'} eq 'alternate'){
        return unless exists $val->{'color_flow'}{'period'} and $val->{'color_flow'}{'period'} > 1;
        @color = map {[$_->values('rgb')]} $startc->gradient( to => $endc, steps => $val->{'color_flow'}{'period'}, dynamic => $val->{'color_flow'}{'dynamic'} );
        my @tc = reverse @color;
        pop @tc;
        shift @tc;
        push @color, @tc;
        @tc = @color;
        my $color_circle_length = (2 * $val->{'color_flow'}{'period'} - 2) * $val->{'color_flow'}{'stepsize'};
        push @color, @tc for 0 .. int ($val->{'line'}{'length'} / $color_circle_length);
    } elsif ($val->{'color_flow'}{'type'} eq 'circular'){
        return unless exists $val->{'color_flow'}{'period'} and $val->{'color_flow'}{'period'} > 1;
        @color = map {[$_->values('rgb')]} $startc->complement( steps => $val->{'color_flow'}{'period'},
                                                      saturation_tilt => $endc->saturation - $startc->saturation,
                                                      lightness_tilt => $endc->lightness - $startc->lightness);
        my @tc = @color;
        push @color, @tc for 0 .. int ($val->{'line'}{'length'} / $val->{'color_flow'}{'period'} / $val->{'color_flow'}{'stepsize'});
    } else { @color = ([ @{$val->{'start_color'}}{'red', 'green', 'blue'}  ]);
    }
    $color_change_time = $step_in_circle * $val->{'color_flow'}{'stepsize'};

    $x = ($dtx ? $rx * cos $tx : 0);
    $y = ($dty ? $ry * sin $ty : 0);
    $x -= $rz * cos $tz if $dtz;
    $y -= $rz * sin $tz if $dtz;
    ($x, $y) = (($x * cos($rz) ) - ($y * sin($tr) ), ($x * sin($tr) ) + ($y * cos($tr) ) ) if $dtr;
    my ($x_old, $y_old) = ($x, $y);

    my $code = 'for (1 .. $t_iter){'."\n";

    $code .= $dtx ? '  $x = $rx * App::GUI::Harmonograph::Function::'.$val->{'mod'}{'x_function'}.
                            '('.$var_names{ $val->{'mod'}{'x_var'} }.');'."\n"
                  : '  $x = 0;'."\n";

    $code .= $dty ? '  $y = $ry * App::GUI::Harmonograph::Function::'.$val->{'mod'}{'y_function'}.
                            '('.$var_names{ $val->{'mod'}{'y_var'} }.');'."\n"
                  : '  $y = 0;'."\n";

    $code .= '  $x -= $rz * App::GUI::Harmonograph::Function::'.$val->{'mod'}{'zx_function'}.
                           '('.$var_names{ $val->{'mod'}{'zx_var'} }.');'."\n" if $dtz;
    $code .= '  $y -= $rz * App::GUI::Harmonograph::Function::'.$val->{'mod'}{'zy_function'}.
                           '('.$var_names{ $val->{'mod'}{'zy_var'} }.');'."\n" if $dtz;

    $code .= '  ($x, $y) = (($x * App::GUI::Harmonograph::Function::'.$val->{'mod'}{'r11_function'}.
                            '('.$var_names{ $val->{'mod'}{'r11_var'} }.'))'.
                        ' - ($y * App::GUI::Harmonograph::Function::'.$val->{'mod'}{'r12_function'}.
                            '('.$var_names{ $val->{'mod'}{'r12_var'} }.')),'.
                          ' ($x * App::GUI::Harmonograph::Function::'.$val->{'mod'}{'r21_function'}.
                            '('.$var_names{ $val->{'mod'}{'r21_var'} }.'))'.
                        ' + ($y * App::GUI::Harmonograph::Function::'.$val->{'mod'}{'r22_function'}.
                            '('.$var_names{ $val->{'mod'}{'r22_var'} }.')));'."\n" if $dtr;

    $code .= $val->{'line'}{'connect'}
           ? '  $dc->DrawLine( $cx + $x_old, $cy + $y_old, $cx + $x, $cy + $y);'."\n"
           : '  $dc->DrawPoint( $cx + $x, $cy + $y );'."\n";
    $code .= '  $tx += $dtx;'."\n"                          if $dtx;
    $code .= '  $ty += $dty;'."\n"                          if $dty;
    $code .= '  $tz += $dtz;'."\n"                          if $dtz;
    $code .= '  $tr += $dtr;'."\n"                          if $dtr;
    $code .= '  $tx -= $max_time if $tx >= $max_time;'."\n" if $dtx;
    $code .= '  $ty -= $max_time if $ty >= $max_time;'."\n" if $dtx;

    $code .= '  $dtx *= $fxdamp;'."\n"             if $fxdamp and $val->{'x'}{'freq_damp_type'} eq '*';
    $code .= '  $dty *= $fydamp;'."\n"             if $fydamp and $val->{'y'}{'freq_damp_type'} eq '*';
    $code .= '  $dtz *= $fzdamp;'."\n"             if $fzdamp and $val->{'z'}{'freq_damp_type'} eq '*';
    $code .= '  $dtr *= $frdamp;'."\n"             if $frdamp and $val->{'r'}{'freq_damp_type'} eq '*';
    $code .= '  $dtx -= $fxdamp if $dtx > 0;'."\n" if $fxdamp and $val->{'x'}{'freq_damp_type'} eq '-';
    $code .= '  $dty -= $fydamp if $dty > 0;'."\n" if $fydamp and $val->{'y'}{'freq_damp_type'} eq '-';
    $code .= '  $dtz -= $fzdamp if $dtz > 0;'."\n" if $fzdamp and $val->{'z'}{'freq_damp_type'} eq '-';
    $code .= '  $dtr -= $frdamp if $dtr < 0;'."\n" if $frdamp and $val->{'r'}{'freq_damp_type'} eq '-';


    $code .= '  $rx *= $rxdamp;'."\n"            if $rxdamp and $val->{'x'}{'radius_damp_type'} eq '*';
    $code .= '  $ry *= $rydamp;'."\n"            if $rydamp and $val->{'y'}{'radius_damp_type'} eq '*';
    $code .= '  $rz *= $rzdamp;'."\n"            if $rzdamp and $val->{'z'}{'radius_damp_type'} eq '*';
    $code .= '  $rx -= $rxdamp if $rx > 0;'."\n" if $rxdamp and $val->{'x'}{'radius_damp_type'} eq '-';
    $code .= '  $ry -= $rydamp if $ry > 0;'."\n" if $rydamp and $val->{'y'}{'radius_damp_type'} eq '-';
    $code .= '  $rz -= $rzdamp if $rz > 0;'."\n" if $rzdamp and $val->{'z'}{'radius_damp_type'} eq '-';
    $code .= '  $dtr *= $rrdamp;' if $rrdamp;
    $code .= '  $rxdamp += $rxdacc;'."\n"  if $rxdacc and $rxdamp and $val->{'x'}{'radius_damp_acc_type'} eq '+';
    $code .= '  $rxdamp -= $rxdacc;'."\n"  if $rxdacc and $rxdamp and $val->{'x'}{'radius_damp_acc_type'} eq '-';
    $code .= '  $rxdamp *= $rxdacc;'."\n"  if $rxdacc and $rxdamp and $val->{'x'}{'radius_damp_acc_type'} eq '*';
    $code .= '  $rxdamp *= $rxdacc;'."\n"  if $rxdacc and $rxdamp and $val->{'x'}{'radius_damp_acc_type'} eq '/';
    $code .= '  $rydamp += $rydacc;'."\n"  if $rydacc and $rydamp and $val->{'y'}{'radius_damp_acc_type'} eq '+';
    $code .= '  $rydamp -= $rydacc;'."\n"  if $rydacc and $rydamp and $val->{'y'}{'radius_damp_acc_type'} eq '-';
    $code .= '  $rydamp *= $rydacc;'."\n"  if $rydacc and $rydamp and $val->{'y'}{'radius_damp_acc_type'} eq '*';
    $code .= '  $rydamp *= $rydacc;'."\n"  if $rydacc and $rydamp and $val->{'y'}{'radius_damp_acc_type'} eq '/';
    $code .= '  $rzdamp += $rzdacc;'."\n"  if $rzdacc and $rzdamp and $val->{'z'}{'radius_damp_acc_type'} eq '+';
    $code .= '  $rzdamp -= $rzdacc;'."\n"  if $rzdacc and $rzdamp and $val->{'z'}{'radius_damp_acc_type'} eq '-';
    $code .= '  $rzdamp *= $rzdacc;'."\n"  if $rzdacc and $rzdamp and $val->{'z'}{'radius_damp_acc_type'} eq '*';
    $code .= '  $rzdamp *= $rzdacc;'."\n"  if $rzdacc and $rzdamp and $val->{'z'}{'radius_damp_acc_type'} eq '/';
#    $code .= '$rxdamp += $rxdacc;'  if $rrdacc and $rrdamp and $val->{'r'}{'radius_damp_acc_type'} eq '+';
#    $code .= '$rxdamp -= $rxdacc;'  if $rrdacc and $rrdamp and $val->{'r'}{'radius_damp_acc_type'} eq '-';
#    $code .= '$rxdamp *= $rxdacc;'  if $rrdacc and $rrdamp and $val->{'r'}{'radius_damp_acc_type'} eq '*';
#    $code .= '$rxdamp *= $rxdacc;'  if $rrdacc and $rrdamp and $val->{'r'}{'radius_damp_acc_type'} eq '/';

    $code .= ' $dc->SetPen( Wx::Pen->new( Wx::Colour->new( @{$color[++$color_index]} ),'.
             ' $thickness, &Wx::wxPENSTYLE_SOLID)) unless $_ % $color_change_time;' if $val->{'color_flow'}{'type'} ne 'no' and @color;
    $code .= '  $progress->add_percentage( $_ / $t_iter * 100, $color[$color_index] ) unless $_ % $step_in_circle;'."\n" unless defined $self->{'flag'}{'sketch'};
    $code .= '  ($x_old, $y_old) = ($x, $y);'."\n" if ($val->{'line'}{'connect'} or exists $self->{'flag'}{'sketch'});
    $code .= '}';
