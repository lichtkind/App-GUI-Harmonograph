
# painting area on left side

package App::GUI::Harmonograph::Frame::Panel::Board;
use v5.12;
use warnings;
use utf8;
use Wx;
use base qw/Wx::Panel/;
use Benchmark;
use Graphics::Toolkit::Color qw/color/;
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

   # my $code_ref = App::GUI::Harmonograph::Compute::Drawing::prepare( $self->{'flag'}{'sketch'} );

    my %var_names = ( x_time => '$tX', y_time => '$tY', e_time => '$tE', f_time => '$tF', w_time => '$tW', r_time => '$tR',
                      x_freq => '$dtX', y_freq => '$dtY', e_freq => '$dtE', f_freq => '$dtF', w_freq => '$dtW', r_freq => '$dtR',
                      x_radius => '$rX', y_radius => '$rY', e_radius => '$rE', f_radius => '$rF', w_radius => '$rW', r_radius => '$rR');

    my $dot_per_sec = ($val->{'visual'}{'dot_density'} || 1);
    my $t_max = (exists $self->{'flag'}{'sketch'}) ? 5 : $val->{'visual'}{'duration'};
    $t_max *= $dot_per_sec;
    $val->{'visual'}{'connect_dots'} = int ($val->{'visual'}{'draw'} eq 'Line');
    my $color_swap_time;
    my $color_timer = 0;
    my @colors = map { color( $val->{'color'}{$_} ) } 1 .. $val->{'visual'}{'colors_used'};
    if      ($val->{'visual'}{'color_flow_type'} eq 'one_time'){
        my $dots_per_gradient = int( $t_max / ($val->{'visual'}{'colors_used'}-1) );
        my $gradient_steps = ($dots_per_gradient > 500) ? 50 :
                             ($dots_per_gradient > 50)  ? 10 : $dots_per_gradient;
        my @gtc_color_objects = @colors;
        @colors = ($gtc_color_objects[0]);
        for my $i (0 .. $val->{'visual'}{'colors_used'}-2){
            pop @colors;
            push @colors, $gtc_color_objects[$i]->gradient(
                    to => $gtc_color_objects[$i+1],
                    steps => $gradient_steps,
                    dynamic => $self->{'color_flow_dynamic'},
            );
        }
        $color_swap_time = int( $t_max / @colors );
        $color_swap_time++ if $color_swap_time * @colors < $t_max;
    } elsif ($val->{'visual'}{'color_flow_type'} eq 'alternate'){
        my $dots_per_gradient = int ($dot_per_sec * 60 / $val->{'visual'}{'color_flow_speed'});
        my $gradient_steps = ($dots_per_gradient > 500) ? 50 :
                             ($dots_per_gradient > 50)  ? 10 : $dots_per_gradient;
        my @gtc_color_objects = @colors;
        my @c = ($gtc_color_objects[0]);
        for my $i (0 .. $val->{'visual'}{'colors_used'}-2){
            pop @c;
            push @c, $gtc_color_objects[$i]->gradient(
                    to => $gtc_color_objects[$i+1],
                    steps => $gradient_steps,
                    dynamic => $self->{'color_flow_dynamic'},
            );
        }
        $color_swap_time = int ($dots_per_gradient / $gradient_steps);
        my $colors_needed = int($t_max / ($color_swap_time + 1));
        $colors_needed++ if $colors_needed * ($color_swap_time + 1) < $t_max;
        @colors = @c;
        while ($colors_needed > @colors){
            @c = reverse @c;
            push @colors, @c[1 .. $#c];
        }
    } elsif ($val->{'visual'}{'color_flow_type'} eq 'circular'){
        my $dots_per_gradient = int ($dot_per_sec * 60 / $val->{'visual'}{'color_flow_speed'});
        my $gradient_steps = ($dots_per_gradient > 500) ? 50 :
                             ($dots_per_gradient > 50)  ? 10 : $dots_per_gradient;
        my @gtc_color_objects = @colors;
        my @c = ($gtc_color_objects[0]);
        for my $i (0 .. $val->{'visual'}{'colors_used'}-2){
            pop @c;
            push @c, $gtc_color_objects[$i]->gradient(
                    to => $gtc_color_objects[$i+1],
                    steps => $gradient_steps,
                    dynamic => $self->{'color_flow_dynamic'},
            );
        }
        pop @c;
        push @c, $gtc_color_objects[-1]->gradient(
                to => $gtc_color_objects[0],
                steps => $gradient_steps,
                dynamic => $self->{'color_flow_dynamic'},
        );
        pop @c;
        $color_swap_time = int ($dots_per_gradient / $gradient_steps);
        my $colors_needed = int($t_max / ($color_swap_time + 1));
        $colors_needed++ if $colors_needed * ($color_swap_time + 1) < $t_max;
        @colors = @c;
        push @colors, @c while $colors_needed > @colors;
    }
    my @wx_colors = map { Wx::Colour->new( $_->values ) } @colors;

    my $fX = $val->{'x'}{'frequency'} * $val->{'x'}{'freq_factor'};
    my $fY = $val->{'y'}{'frequency'} * $val->{'y'}{'freq_factor'};
    my $fE = $val->{'e'}{'frequency'} * $val->{'e'}{'freq_factor'};
    my $fF = $val->{'f'}{'frequency'} * $val->{'f'}{'freq_factor'};
    my $fW = $val->{'w'}{'frequency'} * $val->{'w'}{'freq_factor'};
    my $fR = $val->{'r'}{'frequency'} * $val->{'r'}{'freq_factor'};
    my $dfX = $val->{'x'}{'freq_damp'} * sqrt($val->{'x'}{'freq_damp'}) / $dot_per_sec / 10_000_000 * $fX;
    my $dfY = $val->{'y'}{'freq_damp'} * sqrt($val->{'y'}{'freq_damp'}) / $dot_per_sec / 10_000_000 * $fY;
    my $dfE = $val->{'e'}{'freq_damp'} * sqrt($val->{'e'}{'freq_damp'}) / $dot_per_sec / 10_000_000 * $fE;
    my $dfF = $val->{'f'}{'freq_damp'} * sqrt($val->{'f'}{'freq_damp'}) / $dot_per_sec / 10_000_000 * $fF;
    my $dfW = $val->{'w'}{'freq_damp'} * sqrt($val->{'w'}{'freq_damp'}) / $dot_per_sec / 10_000_000 * $fW;
    my $dfR = $val->{'r'}{'freq_damp'} * sqrt($val->{'r'}{'freq_damp'}) / $dot_per_sec / 10_000_000 * $fR;
    my $ddfX = $val->{'x'}{'freq_damp_acc'} / $dot_per_sec / 50_000_000_000;
    my $ddfY = $val->{'y'}{'freq_damp_acc'} / $dot_per_sec / 50_000_000_000;
    my $ddfE = $val->{'e'}{'freq_damp_acc'} / $dot_per_sec / 50_000_000_000;
    my $ddfF = $val->{'f'}{'freq_damp_acc'} / $dot_per_sec / 50_000_000_000;
    my $ddfW = $val->{'w'}{'freq_damp_acc'} / $dot_per_sec / 50_000_000_000;
    my $ddfR = $val->{'r'}{'freq_damp_acc'} / $dot_per_sec / 50_000_000_000;
    if ($val->{'x'}{'direction'}){   $fX = - $fX;   $dfX = - $dfX;  $ddfX = - $ddfX;}
    if ($val->{'y'}{'direction'}){   $fY = - $fY;   $dfY = - $dfY;  $ddfY = - $ddfY; }
    if ($val->{'e'}{'direction'}){   $fE = - $fE;   $dfE = - $dfE;  $ddfE = - $ddfE; }
    if ($val->{'f'}{'direction'}){   $fF = - $fF;   $dfF = - $dfF;  $ddfF = - $ddfF; }
    if ($val->{'w'}{'direction'}){   $fW = - $fW;   $dfW = - $dfW;  $ddfW = - $ddfW; }
    if ($val->{'r'}{'direction'}){   $fR = - $fR;   $dfR = - $dfR;  $ddfR = - $ddfR; }
    if ($val->{'x'}{'invert_freq'}){ $fX = 1 / $fX; $dfX = $dfX / $fX;  $ddfX = $ddfX / $fX; }
    if ($val->{'y'}{'invert_freq'}){ $fY = 1 / $fY; $dfY = $dfX / $fY;  $ddfY = $ddfX / $fY; }
    if ($val->{'e'}{'invert_freq'}){ $fE = 1 / $fE; $dfE = $dfE / $fE;  $ddfE = $ddfE / $fE; }
    if ($val->{'f'}{'invert_freq'}){ $fF = 1 / $fF; $dfF = $dfF / $fF;  $ddfF = $ddfF / $fF; }
    if ($val->{'w'}{'invert_freq'}){ $fW = 1 / $fW; $dfW = $dfW / $fW;  $ddfW = $ddfW / $fW; }
    if ($val->{'r'}{'invert_freq'}){ $fR = 1 / $fR; $dfR = $dfR / $fR;  $ddfR = $ddfR / $fR; }
    $dfX = 1 - ($dfX * 20) if $val->{'x'}{'freq_damp_type'} eq '*';
    $dfY = 1 - ($dfY * 20) if $val->{'y'}{'freq_damp_type'} eq '*';
    $dfE = 1 - ($dfE * 20) if $val->{'e'}{'freq_damp_type'} eq '*';
    $dfF = 1 - ($dfF * 20) if $val->{'f'}{'freq_damp_type'} eq '*';
    $dfW = 1 - ($dfW * 20) if $val->{'w'}{'freq_damp_type'} eq '*';
    $dfR = 1 - ($dfR * 20) if $val->{'r'}{'freq_damp_type'} eq '*';
    $ddfX = 1 - ($ddfX * 20) if $val->{'x'}{'freq_damp_acc_type'} eq '*' or $val->{'x'}{'freq_damp_acc_type'} eq '/';
    $ddfY = 1 - ($ddfY * 20) if $val->{'y'}{'freq_damp_acc_type'} eq '*' or $val->{'y'}{'freq_damp_acc_type'} eq '/';
    $ddfE = 1 - ($ddfE * 20) if $val->{'e'}{'freq_damp_acc_type'} eq '*' or $val->{'e'}{'freq_damp_acc_type'} eq '/';
    $ddfF = 1 - ($ddfF * 20) if $val->{'f'}{'freq_damp_acc_type'} eq '*' or $val->{'f'}{'freq_damp_acc_type'} eq '/';
    $ddfW = 1 - ($ddfW * 20) if $val->{'w'}{'freq_damp_acc_type'} eq '*' or $val->{'w'}{'freq_damp_acc_type'} eq '/';
    $ddfR = 1 - ($ddfR * 20) if $val->{'r'}{'freq_damp_acc_type'} eq '*' or $val->{'r'}{'freq_damp_acc_type'} eq '/';

    my $rX = $val->{'x'}{'radius'} * $val->{'x'}{'radius_factor'};
    my $rY = $val->{'y'}{'radius'} * $val->{'y'}{'radius_factor'};
    my $rE = $val->{'e'}{'radius'} * $val->{'e'}{'radius_factor'};
    my $rF = $val->{'f'}{'radius'} * $val->{'f'}{'radius_factor'};
    my $rW = $val->{'w'}{'radius'} * $val->{'w'}{'radius_factor'};
    my $rR = $val->{'r'}{'radius'};
    my $max_xr = $val->{'x'}{'on'} ? $rX : 1;
    my $max_yr = $val->{'y'}{'on'} ? $rY : 1;
    $max_xr += $rE if $val->{'e'}{'on'};
    $max_yr += $rF if $val->{'f'}{'on'};
    $max_xr += $rW if $val->{'w'}{'on'};
    $max_yr += $rW if $val->{'w'}{'on'};
    $max_xr *= 1.4 if $val->{'r'}{'on'};
    $max_yr *= 1.4 if $val->{'r'}{'on'};
    $Cr /=  (($max_xr > $max_yr) ? $max_xr : $max_yr); # zoom out so everything is visible
    $rX *= $Cr;
    $rY *= $Cr;
    $rE *= $Cr;
    $rF *= $Cr;
    $rW *= $Cr;

    my $drX = $val->{'x'}{'radius_damp'} / $dot_per_sec / 10_000 * $rX;
    my $drY = $val->{'y'}{'radius_damp'} / $dot_per_sec / 10_000 * $rY;
    my $drE = $val->{'e'}{'radius_damp'} / $dot_per_sec / 10_000 * $rE;
    my $drF = $val->{'f'}{'radius_damp'} / $dot_per_sec / 10_000 * $rF;
    my $drW = $val->{'w'}{'radius_damp'} / $dot_per_sec / 10_000 * $rW;
    my $drR = $val->{'r'}{'radius_damp'} / $dot_per_sec / 10_000 * $rR * $Cr;
    my $ddrX = $val->{'x'}{'radius_damp_acc'} / $dot_per_sec / 20_000;
    my $ddrY = $val->{'y'}{'radius_damp_acc'} / $dot_per_sec / 20_000;
    my $ddrE = $val->{'e'}{'radius_damp_acc'} / $dot_per_sec / 20_000;
    my $ddrF = $val->{'f'}{'radius_damp_acc'} / $dot_per_sec / 20_000;
    my $ddrW = $val->{'w'}{'radius_damp_acc'} / $dot_per_sec / 20_000;
    my $ddrR = $val->{'r'}{'radius_damp_acc'} / $dot_per_sec / 20_000;
    my %acc_mul = map {$_ => ($val->{$_}{'radius_damp_acc_type'} eq '*' or
                              $val->{$_}{'radius_damp_acc_type'} eq '/')   } qw/x y e f w r/;
    if ($val->{'x'}{'radius_damp_type'} eq '*'){ $drX  = 1 - ($drX / 300);
                                                 $ddrX = 1 - ($ddrX / 400) if $acc_mul{'x'};
    } else {                                     $ddrX = 1 - ($ddrX * 40) if $acc_mul{'x'}; }
    if ($val->{'y'}{'radius_damp_type'} eq '*'){ $drY  = 1 - ($drY / 300);
                                                 $ddrY = 1 - ($ddrY / 400) if $acc_mul{'y'};
    } else {                                     $ddrY = 1 - ($ddrY * 40) if $acc_mul{'y'}; }
    if ($val->{'e'}{'radius_damp_type'} eq '*'){ $drE  = 1 - ($drE / 300);
                                                 $ddrE = 1 - ($ddrE / 400) if $acc_mul{'e'};
    } else {                                     $ddrE = 1 - ($ddrE * 40) if $acc_mul{'e'}; }
    if ($val->{'f'}{'radius_damp_type'} eq '*'){ $drF  = 1 - ($drF / 300);
                                                 $ddrF = 1 - ($ddrF / 400) if $acc_mul{'f'};
    } else {                                     $ddrF = 1 - ($ddrF * 40) if $acc_mul{'f'}; }
    if ($val->{'w'}{'radius_damp_type'} eq '*'){ $drW  = 1 - ($drW / 300);
                                                 $ddrW = 1 - ($ddrW / 400) if $acc_mul{'w'};
    } else {                                     $ddrW = 1 - ($ddrW * 40) if $acc_mul{'w'}; }
    if ($val->{'r'}{'radius_damp_type'} eq '*'){ $drR  = 1 - ($drR / 300);
                                                 $ddrR = 1 - ($ddrR / 400) if $acc_mul{'r'};
    } else {                                     $ddrR = 1 - ($ddrR * 40) if $acc_mul{'r'}; }

    my $tX = $val->{'x'}{'offset'} * $TAU;
    my $tY = $val->{'y'}{'offset'} * $TAU;
    my $tE = $val->{'e'}{'offset'} * $TAU;
    my $tF = $val->{'f'}{'offset'} * $TAU;
    my $tW = $val->{'w'}{'offset'} * $TAU;
    my $tR = $val->{'r'}{'offset'} * $TAU;
    my $dtX = $TAU * $fX / $dot_per_sec;
    my $dtY = $TAU * $fY / $dot_per_sec;
    my $dtE = $TAU * $fE / $dot_per_sec;
    my $dtF = $TAU * $fF / $dot_per_sec;
    my $dtW = $TAU * $fW / $dot_per_sec;
    my $dtR = $TAU * $fR / $dot_per_sec;
    my ($x_old, $y_old);
    my $x = $val->{'x'}{'on'} ? ($rX * cos($tX)) : 0;
    my $y = $val->{'y'}{'on'} ? ($rY * sin($tY)) : 0;
    $x += $val->{'e'}{'on'} ? ($rE * cos($tE)) : 0;
    $y += $val->{'f'}{'on'} ? ($rF * sin($tF)) : 0;
    $x += $val->{'w'}{'on'}  ? ($rW * cos($tW)) : 0;
    $y += $val->{'w'}{'on'}  ? ($rW * sin($tW)) : 0;
    my $xr = $val->{'r'}{'on'} ? ($rR * (($x * cos($tR)) - ($y * sin($tR)))) : $x;
    my $yr = $val->{'r'}{'on'} ? ($rR * (($x * sin($tR)) + ($y * cos($tR)))) : $y;
    $x = $xr + $Cx;
    $y = $yr + $Cy;

    my @pendulum_names = qw/x y w r e f/;
    my %init_code  = (map {$_ => []} @pendulum_names);
    my %iter_code = (map {$_ => []} @pendulum_names);
    for my $pendulum_name (@pendulum_names){
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
        push @{$iter_code{$pendulum_name}}, @code;
    }
    my $pen_size = $val->{'visual'}{'line_thickness'};
    my $wxpen_style = { dotted => &Wx::wxPENSTYLE_DOT,        short_dash => &Wx::wxPENSTYLE_SHORT_DASH,
                        solid => &Wx::wxPENSTYLE_SOLID,       vertical => &Wx::wxPENSTYLE_VERTICAL_HATCH,
                        horizontal => &Wx::wxPENSTYLE_HORIZONTAL_HATCH, cross => &Wx::wxPENSTYLE_CROSS_HATCH,
                        diagonal => &Wx::wxPENSTYLE_BDIAGONAL_HATCH, bidiagonal => &Wx::wxPENSTYLE_CROSSDIAG_HATCH};
    my $pen_style = $wxpen_style->{ $val->{'visual'}{'pen_style'} };
    $dc->SetPen( Wx::Pen->new( shift @wx_colors, $pen_size, $pen_style ) );

    #my @code = ('sub {','= @_');
    my @code = ();
    push @code, @{$init_code{$_}} for @pendulum_names;
    push @code, 'for (1 .. $t_max){';
    push @code, '  ($x_old, $y_old) = ($x, $y)' if $val->{'visual'}{'connect_dots'};
    push @code, @{$iter_code{$_}} for @pendulum_names;
    push @code, ($val->{'x'}{'on'}  ? '  $x = $rX * cos($tX)' : '  $x = 0');
    push @code, ($val->{'y'}{'on'}  ? '  $y = $rY * sin($tY)' : '  $y = 0');
    push @code,                       '  $x += $rE * cos($tE)' if $val->{'e'}{'on'};
    push @code,                       '  $y += $rF * sin($tF)' if $val->{'f'}{'on'};
    push @code, '  $x += $rW * cos($tW)', '  $y += $rW * sin($tW)' if $val->{'w'}{'on'};
    push @code, ' ($x, $y) = ($rR * (($x * cos($tR)) - ($y * sin($tR)))'
                           .',$rR * (($x * sin($tR)) + ($y * cos($tR))))' if $val->{'r'}{'on'};
    push @code, '  $x += $Cx', '  $y += $Cy';
    push @code, '  if ($color_timer++ == $color_swap_time){', '$color_timer = 0',
                '  $dc->SetPen( Wx::Pen->new( shift @wx_colors, $pen_size, $pen_style) )','}' if $color_swap_time;
    push @code, ($val->{'visual'}{'connect_dots'}
              ? '  $dc->DrawLine( $x_old, $y_old, $x, $y)'
              : '  $dc->DrawPoint( $x, $y )');

   # push @code, '$progress->add_percentage( $_ / $t_max * 100, $color[$color_index] ) unless $_ % $step_in_circle;'."\n" unless defined $self->{'flag'}{'sketch'};

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
