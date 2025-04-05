
# assemble code that calculates drawing

package App::GUI::Harmonograph::Compute::Drawing;
use v5.12;
use warnings;
use utf8;
use Graphics::Toolkit::Color qw/color/;
use Benchmark;

my $TAU = 6.283185307;

my %var_names = ( 'X time' => '$tX', 'X freq.' => '$dtX', 'X radius' => '$rX',
                  'Y time' => '$tY', 'Y freq.' => '$dtY', 'Y radius' => '$rY',
                  'E time' => '$tE', 'E freq.' => '$dtE', 'E radius' => '$rE',
                  'F time' => '$tF', 'F freq.' => '$dtF', 'F radius' => '$rF',
                  'W time' => '$tW', 'W freq.' => '$dtW', 'W radius' => '$rW',
                  'R time' => '$tR', 'R freq.' => '$dtR', 'R radius' => '$rR');

#~ my $default_settings = {
    #~ x_function   => 'cos', x_operator   => '=', x_factor => '1',   x_constant => '1',   x_variable  => 'X time',
    #~ y_function   => 'sin', y_operator   => '=', y_factor => '1',   y_constant => '1',   y_variable  => 'Y time',
    #~ e_function   => 'cos', e_operator   => '=', e_factor => '1',   e_constant => '1',   e_variable  => 'E time',
    #~ f_function   => 'sin', f_operator   => '=', f_factor => '1',   f_variable   => 'F time',
    #~ wx_function  => 'cos', wx_operator  => '=', wx_factor => '1',  wx_variable  => 'W time',
    #~ wy_function  => 'sin', wy_operator  => '=', wy_factor => '1',  wy_variable  => 'W time',
    #~ r11_function => 'cos', r11_operator => '=', r11_factor => '1', r11_variable => 'R time',
    #~ r12_function => 'sin', r12_operator => '=', r12_factor => '1', r12_variable => 'R time',
    #~ r21_function => 'sin', r21_operator => '=', r21_factor => '1', r21_variable => 'R time',
    #~ r22_function => 'cos', r22_operator => '=', r22_factor => '1', r22_variable => 'R time',
#~ };

sub calculate_colors {
}

sub compile {
    my ($state, $progress_bar, $main_radius, $sketch) = @_;
    my $val = $state;
    my $Cr = $main_radius;
    my $t = Benchmark->new();

    my $dot_per_sec = ($val->{'visual'}{'dot_density'} || 1);
    my $dot_count = ((defined $sketch) ? 5 : $val->{'visual'}{'duration'}) * $dot_per_sec;

    $val->{'visual'}{'connect_dots'} = int ($val->{'visual'}{'draw'} eq 'Line');
    my $color_swap_time;
    my @colors = map { color( $val->{'color'}{$_} ) } 1 .. $val->{'visual'}{'colors_used'};
    if      ($val->{'visual'}{'color_flow_type'} eq 'one_time'){
        my $dots_per_gradient = int( $dot_count / ($val->{'visual'}{'colors_used'}-1) );
        my $gradient_steps = ($dots_per_gradient > 500) ? 50 :
                             ($dots_per_gradient > 50)  ? 10 : $dots_per_gradient;
        my @gtc_color_objects = @colors;
        @colors = ($gtc_color_objects[0]);
        for my $i (0 .. $val->{'visual'}{'colors_used'}-2){
            pop @colors;
            push @colors, $gtc_color_objects[$i]->gradient(
                    to => $gtc_color_objects[$i+1],
                    steps => $gradient_steps,
                    dynamic => $val->{'visual'}{'color_flow_dynamic'},
            );
        }
        $color_swap_time = int( $dot_count / @colors );
        $color_swap_time++ if $color_swap_time * @colors < $dot_count;
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
                    dynamic => $val->{'visual'}{'color_flow_dynamic'},
            );
        }
        $color_swap_time = int( $dots_per_gradient / $gradient_steps );
        my $colors_needed = int( $dot_count / ($color_swap_time + 1) );
        $colors_needed++ if $colors_needed * ($color_swap_time + 1) < $dot_count;
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
                    dynamic => $val->{'visual'}{'color_flow_dynamic'},
            );
        }
        pop @c;
        push @c, $gtc_color_objects[-1]->gradient(
                to => $gtc_color_objects[0],
                steps => $gradient_steps,
                dynamic => $$val->{'visual'}{'color_flow_dynamic'},
        );
        pop @c;
        $color_swap_time = int ($dots_per_gradient / $gradient_steps);
        my $colors_needed = int($dot_count / ($color_swap_time + 1));
        $colors_needed++ if $colors_needed * ($color_swap_time + 1) < $dot_count;
        @colors = @c;
        push @colors, @c while $colors_needed > @colors;
    }
    my @wx_colors = map { Wx::Colour->new( $_->values ) } @colors;

    my @pendulum_names = qw/x y e f w r/;
    my %init_code = (map {$_ => []} @pendulum_names);
    my %iter_code = (map {$_ => []} @pendulum_names);
    my %comp_code = (map {$_ => []} @pendulum_names);

    for my $pendulum_name (@pendulum_names){
        next unless $val->{$pendulum_name}{'on'};
        my $val = $val->{ $pendulum_name };
        my $index = uc $pendulum_name;
        my @code = ();
        push @code, 'my $f'.$index.' = '.($val->{'invert_dir'} ? '-' : '+').'1 '.
                                         ($val->{'invert_freq'} ? '/ ': '* ').($val->{'frequency'} * $val->{'freq_factor'});
        if ($val->{'freq_damp'}){
            push @code, 'my $df'.$index.' = $f'.$index.' / $dot_per_sec * '.($val->{'freq_damp'} * sqrt($val->{'freq_factor'}) / 10_000_000 );
            push @code, '$df'.$index.' /= $f'.$index if $val->{'invert_freq'};
            push @code, '$df'.$index.' = - $df'.$index if $val->{'invert_dir'};
            push @code, '$df'.$index.' = 1 - ($df'.$index.' * 20)' if $val->{'freq_damp_type'} eq '*';
            if ($val->{'freq_damp_acc'}){
                push @code, 'my $ddf'.$index.' = '.($val->{'freq_damp_acc'} / 50_000_000_000).' / $dot_per_sec';
                push @code, '$ddf'.$index.' /= $f'.$index if $val->{'invert_freq'};
                push @code, '$ddf'.$index.' = - $ddf'.$index if $val->{'invert_dir'};
                push @code, '$ddf'.$index.' = 1 - ($ddf'.$index.' * 20)'
                    if $val->{'freq_damp_acc_type'} eq '*' or $val->{'freq_damp_acc_type'} eq '/';
            }
        }
        push @code, '$r'.$index.' *= $Cr' unless $pendulum_name eq 'r';

        if ($val->{'radius_damp'}){
            my $code = 'my $dr'.$index.' = '.$val->{'radius_damp'}.' / $dot_per_sec / 10_000 * $r'.$index;
            $code .= '* $Cr' if $pendulum_name eq 'r';
            push @code, $code;
            push @code, '$dr'.$index.' = 1 - ($dr'.$index.' / 300 )' if $val->{'radius_damp_type'} eq '*';
            if ($val->{'radius_damp_acc'}){
                push @code, 'my $ddr'.$index.' = '.$val->{'radius_damp_acc'}.' / $dot_per_sec / 20_000';
                push @code, '$ddr'.$index.' = 1 - ($ddr'.$index.(($val->{'radius_damp_type'} eq '*') ? '/ 400 ' : '* 40 ').' )'
                    if $val->{'radius_damp_acc_type'} eq '*' or $val->{'radius_damp_acc_type'} eq '/';
            }
        }
        push @code, 'my $t'.$index.' = '.$val->{'offset'}.' * '.$TAU,
                    'my $dt'.$index.' = $f'.$index.' / $dot_per_sec * '.$TAU;
        push @{$init_code{$pendulum_name}}, @code;
    }
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

    my @code = ('sub {','my ($dc, $Cx, $Cy) = @_');
    push @code, 'my $r'.uc($_).' = '.($val->{$_}{'radius'} * $val->{$_}{'radius_factor'}) for qw/x y e f w/;
    push @code, 'my $rR = '.$val->{'r'}{'radius'};
    push @code, ($val->{'x'}{'on'} ? 'my $max_xr = $rX' : 'my $max_xr = 1');
    push @code, ($val->{'y'}{'on'} ? 'my $max_yr = $rY' : 'my $max_yr = 1');
    push @code, '$max_xr += $rE' if $val->{'e'}{'on'};
    push @code, '$max_yr += $rF' if $val->{'f'}{'on'};
    push @code, '$max_xr += $rW', '$max_yr += $rW' if $val->{'w'}{'on'};
    push @code, '$max_xr *= 1.4', '$max_yr *= 1.4' if $val->{'r'}{'on'};


    push @code, '$Cr /= (($max_xr > $max_yr) ? $max_xr : $max_yr)'; # zoom out so everything is visible
    push @code, @{$init_code{$_}} for @pendulum_names;
    push @code, 'my ($x, $y)';
    if ($val->{'visual'}{'connect_dots'}){
        push @code, 'my ($x_old, $y_old)';
        push @code, ($val->{'x'}{'on'}  ? '$x = $rX * cos($tX)' : '$x = 0');
        push @code, ($val->{'y'}{'on'}  ? '$y = $rY * sin($tY)' : '$y = 0');
        push @code,                       '$x += $rE * cos($tE)' if $val->{'e'}{'on'};
        push @code,                       '$y += $rF * sin($tF)' if $val->{'f'}{'on'};
        push @code, '$x += $rW * cos($tW)', '$y += $rW * sin($tW)' if $val->{'w'}{'on'};
        push @code, '($x, $y) = ($rR * (($x * cos($tR)) - ($y * sin($tR)))'
                              .',$rR * (($x * sin($tR)) + ($y * cos($tR))))' if $val->{'r'}{'on'};
        push @code, '$x += $Cx', '$y += $Cy';
    }
    push @code, '$dc->SetPen( Wx::Pen->new( shift @wx_colors, $pen_size, $pen_style ) )', 'shift @colors';
    push @code, 'my $color_timer = 0' if $color_swap_time;
    push @code, 'for my $i (1 .. $dot_count){';
    push @code, '  ($x_old, $y_old) = ($x, $y)' if $val->{'visual'}{'connect_dots'};
    if ($color_swap_time){
        push @code, '  if ($color_timer++ == $color_swap_time){', '    $color_timer = 1',
                    '    $dc->SetPen( Wx::Pen->new( shift @wx_colors, $pen_size, $pen_style) )';
        push @code, '    $progress_bar->add_percentage( ($i/ $dot_count*100), [(shift @colors)->values] )' unless defined $sketch;
        push @code, '}';
    }
    push @code, @{$iter_code{$_}} for @pendulum_names;
    push @code, ($val->{'x'}{'on'}  ? '  $x = $rX * cos($tX)' : '  $x = 0');
    push @code, ($val->{'y'}{'on'}  ? '  $y = $rY * sin($tY)' : '  $y = 0');
    push @code,                       '  $x += $rE * cos($tE)' if $val->{'e'}{'on'};
    push @code,                       '  $y += $rF * sin($tF)' if $val->{'f'}{'on'};
    push @code, '  $x += $rW * cos($tW)', '  $y += $rW * sin($tW)' if $val->{'w'}{'on'};
    push @code, ' ($x, $y) = ($rR * (($x * cos($tR)) - ($y * sin($tR)))'
                           .',$rR * (($x * sin($tR)) + ($y * cos($tR))))' if $val->{'r'}{'on'};
    push @code, '  $x += $Cx', '  $y += $Cy';
    push @code, ($val->{'visual'}{'connect_dots'}
              ? '  $dc->DrawLine( $x_old, $y_old, $x, $y)'
              : '  $dc->DrawPoint( $x, $y )');

   # $progress_bar->add_percentage( 100, [$colors[0]->values] ) unless exists $self->{'flag'}{'sketch'} or $color_swap_time;

    my $code = join '', map {$_.";\n"} @code, '}}'; # say $code;
    my $code_ref = eval $code;
    die "bug '$@' in drawing code: $code" if $@; #
    say "comp: ",timestr( timediff( Benchmark->new(), $t) );
    return $code_ref
}

1;
__END__

 sin
 cos
 tan  =  sin / cos
 cot  =  cos / sin
 sec  =  1 / cos
 csc  =  1 / sin
 sinh =  exp $x - exp (- $x)
 cosh =  exp $x + exp (- $x)
 tanh = sinh / cosh
 coth = coth / sinh
 sech = 1 / cosh
 csch = 1 / sinh
