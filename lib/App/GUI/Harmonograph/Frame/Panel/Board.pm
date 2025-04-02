
# painting area on left side

package App::GUI::Harmonograph::Frame::Panel::Board;
use v5.12;
use warnings;
use utf8;
use Wx;
use base qw/Wx::Panel/;
use Benchmark;
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
    $dc->SetBackground( Wx::Brush->new( Wx::Colour->new( 255, 255, 255 ), &Wx::wxBRUSHSTYLE_SOLID ) );
    $dc->Clear();
    my $t = Benchmark->new();
    my $Cx = (defined $width)  ? ($width / 2)  : $self->{'center'}{'x'};
    my $Cy = (defined $height) ? ($height / 2) : $self->{'center'}{'y'};
    my $Cr = (defined $height) ? ($width > $height ? $Cx : $Cy) : $self->{'hard_radius'};
    $Cr -= 15;
    my $max_xr = $val->{'x'}{'on'} ? $val->{'x'}{'radius'} : 1;
    my $max_yr = $val->{'y'}{'on'} ? $val->{'y'}{'radius'} : 1;
    $max_xr += $val->{'ex'}{'radius'} if $val->{'ex'}{'on'};
    $max_yr += $val->{'ey'}{'radius'} if $val->{'ey'}{'on'};
    $max_xr += $val->{'z'}{'radius'} if $val->{'z'}{'on'};
    $max_yr += $val->{'z'}{'radius'} if $val->{'z'}{'on'};
    $max_xr *= 1.5 if $val->{'r'}{'on'};
    $max_yr *= 1.5 if $val->{'r'}{'on'};
    $Cr /=  (($max_xr > $max_yr) ? $max_xr : $max_yr); # zoom out so everything is visible

   # my $ = App::GUI::Harmonograph::Compute::Drawing::prepare( $val, $Cr, $self->{'flag'}{'sketch'} );

    my %var_names = ( x_time => '$tx', y_time => '$ty', z_time => '$tz', r_time => '$tr',
                      x_freq => '$dtx', y_freq => '$dty', z_freq => '$dtz', r_freq => '$dtr',
                      x_radius => '$rx', y_radius => '$ry', z_radius => '$rz', r_radius => '$rr',
                      zero => '0', one => '1');

    my $start_color = Wx::Colour->new( 0, 20, 200 ); # @{$val->{'start_color'}}{'red', 'green', 'blue'}
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
    my $fEX = $val->{'ex'}{'frequency'} * $val->{'ex'}{'freq_factor'};
    my $fEY = $val->{'ey'}{'frequency'} * $val->{'ey'}{'freq_factor'};
    my $dfX = $val->{'x'}{'freq_damp'} / $dot_per_sec / 5_000_000;
    my $dfY = $val->{'y'}{'freq_damp'} / $dot_per_sec / 5_000_000;
    my $dfZ = $val->{'z'}{'freq_damp'} / $dot_per_sec / 5_000_000;
    my $dfR = $val->{'r'}{'freq_damp'} / $dot_per_sec / 5_000_000;
    my $dfEX = $val->{'ex'}{'freq_damp'} / $dot_per_sec / 5_000_000;
    my $dfEY = $val->{'ey'}{'freq_damp'} / $dot_per_sec / 5_000_000;
    my $ddfX = $val->{'x'}{'freq_damp_acc'} / $dot_per_sec / 50_000_000_000;
    my $ddfY = $val->{'y'}{'freq_damp_acc'} / $dot_per_sec / 50_000_000_000;
    my $ddfZ = $val->{'z'}{'freq_damp_acc'} / $dot_per_sec / 50_000_000_000;
    my $ddfR = $val->{'r'}{'freq_damp_acc'} / $dot_per_sec / 50_000_000_000;
    my $ddfEX = $val->{'ex'}{'freq_damp_acc'} / $dot_per_sec / 50_000_000_000;
    my $ddfEY = $val->{'ey'}{'freq_damp_acc'} / $dot_per_sec / 50_000_000_000;
    if ($val->{'x'}{'direction'}){   $fX = - $fX;   $dfX = - $dfX;   $ddfX  = - $ddfX;}
    if ($val->{'y'}{'direction'}){   $fY = - $fY;   $dfY = - $dfY;   $ddfY  = - $ddfY; }
    if ($val->{'z'}{'direction'}){   $fZ = - $fZ;   $dfZ = - $dfZ;   $ddfZ  = - $ddfZ; }
    if ($val->{'r'}{'direction'}){   $fR = - $fR;   $dfR = - $dfR;   $ddfR  = - $ddfR; }
    if ($val->{'ex'}{'direction'}){ $fEX = - $fEX; $dfEX = - $dfEX;  $ddfEX = - $ddfEX; }
    if ($val->{'ey'}{'direction'}){ $fEY = - $fEY; $dfEY = - $dfEY;  $ddfEY = - $ddfEY; }
    if ($val->{'x'}{'invert_freq'}){ $fX = 1 / $fX; $dfX = $dfX / $fX;  $ddfX = $ddfX / $fX; }
    if ($val->{'y'}{'invert_freq'}){ $fY = 1 / $fY; $dfY = $dfX / $fY;  $ddfY = $ddfX / $fY; }
    if ($val->{'z'}{'invert_freq'}){ $fZ = 1 / $fZ; $dfZ = $dfZ / $fZ;  $ddfZ = $ddfZ / $fZ; }
    if ($val->{'r'}{'invert_freq'}){ $fR = 1 / $fR; $dfR = $dfR / $fR;  $ddfR = $ddfR / $fR; }
    if ($val->{'ex'}{'invert_freq'}){$fEX = 1 / $fEX; $dfEX = $dfEX / $fEX;  $ddfEX = $ddfEX / $fEX; }
    if ($val->{'ey'}{'invert_freq'}){$fEY = 1 / $fEY; $dfEY = $dfEY / $fEY;  $ddfEY = $ddfEY / $fEY; }
    $dfX = 1 - ($dfX * 20) if $val->{'x'}{'freq_damp_type'} eq '*';
    $dfY = 1 - ($dfY * 20) if $val->{'y'}{'freq_damp_type'} eq '*';
    $dfZ = 1 - ($dfZ * 20) if $val->{'z'}{'freq_damp_type'} eq '*';
    $dfR = 1 - ($dfR * 20) if $val->{'r'}{'freq_damp_type'} eq '*';
    $dfEX = 1 - ($dfEX * 20) if $val->{'ex'}{'freq_damp_type'} eq '*';
    $dfEY = 1 - ($dfEY * 20) if $val->{'ey'}{'freq_damp_type'} eq '*';
    $ddfX = 1 - ($ddfX * 20) if $val->{'x'}{'freq_damp_acc_type'} eq '*' or $val->{'x'}{'freq_damp_acc_type'} eq '/';
    $ddfY = 1 - ($ddfY * 20) if $val->{'y'}{'freq_damp_acc_type'} eq '*' or $val->{'y'}{'freq_damp_acc_type'} eq '/';
    $ddfZ = 1 - ($ddfZ * 20) if $val->{'z'}{'freq_damp_acc_type'} eq '*' or $val->{'z'}{'freq_damp_acc_type'} eq '/';
    $ddfR = 1 - ($ddfR * 20) if $val->{'r'}{'freq_damp_acc_type'} eq '*' or $val->{'r'}{'freq_damp_acc_type'} eq '/';
    $ddfEX = 1 - ($ddfX * 20) if $val->{'ex'}{'freq_damp_acc_type'} eq '*' or $val->{'ex'}{'freq_damp_acc_type'} eq '/';
    $ddfEY = 1 - ($ddfY * 20) if $val->{'ey'}{'freq_damp_acc_type'} eq '*' or $val->{'ey'}{'freq_damp_acc_type'} eq '/';

    my $rX = $val->{'x'}{'radius'} * $Cr;
    my $rY = $val->{'y'}{'radius'} * $Cr;
    my $rZ = $val->{'z'}{'radius'} * $Cr;
    my $rR = $val->{'r'}{'radius'};
    my $rEX = $val->{'ex'}{'radius'} * $Cr;
    my $rEY = $val->{'ey'}{'radius'} * $Cr;
    my $drX = $val->{'x'}{'radius_damp'} / $dot_per_sec / 1_000 * $Cr;
    my $drY = $val->{'y'}{'radius_damp'} / $dot_per_sec / 1_000 * $Cr;
    my $drZ = $val->{'z'}{'radius_damp'} / $dot_per_sec / 1_000 * $Cr;
    my $drR = $val->{'r'}{'radius_damp'} / $dot_per_sec / 1_000 * $Cr;
    my $drEX = $val->{'ex'}{'radius_damp'} / $dot_per_sec / 1_000 * $Cr;
    my $drEY = $val->{'ey'}{'radius_damp'} / $dot_per_sec / 1_000 * $Cr;
    my $ddrX = $val->{'x'}{'radius_damp_acc'} / $dot_per_sec / 20_000;
    my $ddrY = $val->{'y'}{'radius_damp_acc'} / $dot_per_sec / 20_000;
    my $ddrZ = $val->{'z'}{'radius_damp_acc'} / $dot_per_sec / 20_000;
    my $ddrR = $val->{'r'}{'radius_damp_acc'} / $dot_per_sec / 20_000;
    my $ddrEX = $val->{'ex'}{'radius_damp_acc'} / $dot_per_sec / 20_000;
    my $ddrEY = $val->{'ey'}{'radius_damp_acc'} / $dot_per_sec / 20_000;
    if ($val->{'x'}{'radius_damp_type'} eq '*'){
        $drX = 1 - ($drX / 300);
        $ddrX = 1 - ($ddrX / 400) if $val->{'x'}{'radius_damp_acc_type'} eq '*'
                                  or $val->{'x'}{'radius_damp_acc_type'} eq '/';
    } else {
        $ddrX = 1 - ($ddrX * 40) if $val->{'x'}{'radius_damp_acc_type'} eq '*'
                                 or $val->{'x'}{'radius_damp_acc_type'} eq '/';
    }
    if ($val->{'y'}{'radius_damp_type'} eq '*'){
        $drY = 1 - ($drY / 300);
        $ddrY = 1 - ($ddrY / 400) if $val->{'y'}{'radius_damp_acc_type'} eq '*'
                                  or $val->{'y'}{'radius_damp_acc_type'} eq '/';
    } else {
        $ddrY = 1 - ($ddrY * 40) if $val->{'y'}{'radius_damp_acc_type'} eq '*'
                                 or $val->{'y'}{'radius_damp_acc_type'} eq '/';
    }
    if ($val->{'z'}{'radius_damp_type'} eq '*'){
        $drZ = 1 - ($drZ / 300);
        $ddrZ = 1 - ($ddrZ / 400) if $val->{'z'}{'radius_damp_acc_type'} eq '*'
                                  or $val->{'z'}{'radius_damp_acc_type'} eq '/';
    } else {
        $ddrZ = 1 - ($ddrZ * 40) if $val->{'z'}{'radius_damp_acc_type'} eq '*'
                                 or $val->{'z'}{'radius_damp_acc_type'} eq '/';
    }
    if ($val->{'r'}{'radius_damp_type'} eq '*'){
        $drR = 1 - ($drR / 300);
        $ddrR = 1 - ($ddrR / 400) if $val->{'r'}{'radius_damp_acc_type'} eq '*'
                                  or $val->{'r'}{'radius_damp_acc_type'} eq '/';
    } else {
        $ddrR = 1 - ($ddrR * 40) if $val->{'r'}{'radius_damp_acc_type'} eq '*'
                                 or $val->{'r'}{'radius_damp_acc_type'} eq '/';
    }
    if ($val->{'ex'}{'radius_damp_type'} eq '*'){
        $drEX = 1 - ($drEX / 300);
        $ddrEX = 1 - ($ddrEX / 400) if $val->{'ex'}{'radius_damp_acc_type'} eq '*'
                                    or $val->{'ex'}{'radius_damp_acc_type'} eq '/';
    } else {
        $ddrEX = 1 - ($ddrEX * 40) if $val->{'ex'}{'radius_damp_acc_type'} eq '*'
                                   or $val->{'ex'}{'radius_damp_acc_type'} eq '/';
    }
    if ($val->{'ey'}{'radius_damp_type'} eq '*'){
        $drEY = 1 - ($drEY / 300);
        $ddrEY = 1 - ($ddrEY / 400) if $val->{'ey'}{'radius_damp_acc_type'} eq '*'
                                    or $val->{'ey'}{'radius_damp_acc_type'} eq '/';
    } else {
        $ddrEY = 1 - ($ddrEY * 40) if $val->{'ey'}{'radius_damp_acc_type'} eq '*'
                                   or $val->{'ey'}{'radius_damp_acc_type'} eq '/';
    }

    my $tX = $val->{'x'}{'offset'} * $TAU;
    my $tY = $val->{'y'}{'offset'} * $TAU;
    my $tZ = $val->{'z'}{'offset'} * $TAU;
    my $tR = $val->{'r'}{'offset'} * $TAU;
    my $tEX = $val->{'ex'}{'offset'} * $TAU;
    my $tEY = $val->{'ey'}{'offset'} * $TAU;
    my $dtX = $TAU * $fX / $dot_per_sec;
    my $dtY = $TAU * $fY / $dot_per_sec;
    my $dtZ = $TAU * $fZ / $dot_per_sec;
    my $dtR = $TAU * $fR / $dot_per_sec;
    my $dtEX = $TAU * $fEX / $dot_per_sec;
    my $dtEY = $TAU * $fEY / $dot_per_sec;
    my ($x_old, $y_old);
    my $x = $val->{'x'}{'on'} ? ($rX * cos($tX)) : 0;
    my $y = $val->{'y'}{'on'} ? ($rY * sin($tY)) : 0;
    $x += $val->{'ex'}{'on'} ? ($rEX * cos($tEX)) : 0;
    $y += $val->{'ey'}{'on'} ? ($rEY * sin($tEY)) : 0;
    $x += $val->{'z'}{'on'}  ? ($rZ * cos($tZ)) : 0;
    $y += $val->{'z'}{'on'}  ? ($rZ * sin($tZ)) : 0;
    my $xr = $val->{'r'}{'on'} ? ($rR * (($x * cos($tR)) - ($y * sin($tR)))) : $x;
    my $yr = $val->{'r'}{'on'} ? ($rR * (($x * sin($tR)) + ($y * cos($tR)))) : $y;
    $x = $xr + $Cx;
    $y = $yr + $Cy;

    my %delta_code = ( x=> [], y=> [], z=> [], r=> [], ex=> [], ey=> [] );
    for my $pendulum_name (qw/x y z r ex ey/){
        next unless $val->{$pendulum_name}{'on'};
        my $val = $val->{ $pendulum_name };
        my $index = uc $pendulum_name;
        my @code = ('  $t'.$index.' += $dt'.$index);
        if ($val->{'freq_damp'}){
            my $code = '  $dt'.$index.' '.$val->{'freq_damp_type'}.'= $df'.$index;
            $code .= ' if $dt'.$index.' > 0' if not $val->{'neg_freq'} and $val->{'freq_damp_type'} eq '-';
            push @code, $code;
            push @code, '  $df'.$index.' '.$val->{'freq_damp_acc_type'}.'= $ddf'.$index if $val->{'freq_damp_acc'};
        }
        if ($val->{'radius_damp'}){
            my $code = '  $r'.$index.' '.$val->{'radius_damp_type'}.'= $dr'.$index;
            $code .= ' if $r'.$index.' > 0' if not $val->{'neg_radius'} and $val->{'radius_damp_type'} eq '-';
            push @code, $code;
            push @code, '  $dr'.$index.' '.$val->{'radius_damp_acc_type'}.'= $ddr'.$index if $val->{'radius_damp_acc'};
        }
        push @{$delta_code{$pendulum_name}}, @code;
    }

    my @code = ('for (1 .. $t_iter){');
    push @code, '  ($x_old, $y_old) = ($x, $y)' if $val->{'visual'}{'connect_dots'};
    push @code, @{$delta_code{$_}} for qw/x y z r ex ey/;
    push @code, ($val->{'x'}{'on'}  ? '  $x = $rX * cos($tX)' : '  $x = 0');
    push @code, ($val->{'y'}{'on'}  ? '  $y = $rY * sin($tY)' : '  $y = 0');
    push @code,                       '  $x += $rEX * cos($tEX)' if $val->{'ex'}{'on'};
    push @code,                       '  $y += $rEY * sin($tEY)' if $val->{'ey'}{'on'};
    push @code, '  $x += $rZ * cos($tZ)', '  $y += $rZ * sin($tZ)' if $val->{'z'}{'on'};
    push @code, ' ($x, $y) = ($rR * (($x * cos($tR)) - ($y * sin($tR)))'
                           .',$rR * (($x * sin($tR)) + ($y * cos($tR))))' if $val->{'r'}{'on'};
    push @code, '  $x += $Cx', '  $y += $Cy';
    push @code, ($val->{'visual'}{'connect_dots'}
              ? '  $dc->DrawLine( $x_old, $y_old, $x, $y)'
              : '  $dc->DrawPoint( $x, $y )');

   # push @code, ' $dc->SetPen( Wx::Pen->new( $start_color ), 1, &Wx::wxPENSTYLE_SOLID);';
   # push @code, '$progress->add_percentage( $_ / $t_iter * 100, $color[$color_index] ) unless $_ % $step_in_circle;'."\n" unless defined $self->{'flag'}{'sketch'};

    my $code = join '', map {$_.";\n"} @code, '}'; # say $code;
    eval $code;
    die "bad iter code - $@ : $code" if $@; #
    say "comp: ",timestr( timediff( Benchmark->new(), $t) );

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
