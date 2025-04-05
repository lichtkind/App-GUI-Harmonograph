
# assemble code that calculates drawing

package App::GUI::Harmonograph::Compute::Drawing;
use v5.12;
use warnings;
use utf8;
use Graphics::Toolkit::Color qw/color/;
use Benchmark;

my $TAU = 6.283185307;

sub gradient_steps {
    my $dots_per_gradient = shift;
    return ($dots_per_gradient > 500) ? 50 :
           ($dots_per_gradient > 50)  ? 10 : $dots_per_gradient;
}

sub calculate_colors {
    my ($val, $dot_count, $dot_per_sec) = @_;
    my $color_swap_time;
    my @colors = map { color( $val->{'color'}{$_} ) } 1 .. $val->{'visual'}{'colors_used'};
    $val = $val->{'visual'};

    if      ($val->{'color_flow_type'} eq 'one_time'){
        my $dots_per_gradient = int( $dot_count / $val->{'colors_used'} );
        my @color_objects = @colors;
        @colors = ($color_objects[0]);
        for my $i (0 .. $val->{'colors_used'}-2){
            pop @colors;
            push @colors, $color_objects[$i]->gradient(
                    to => $color_objects[$i+1],
                    steps => gradient_steps( $dots_per_gradient ),
                    dynamic => $val->{'color_flow_dynamic'},
            );
        }
        $color_swap_time = int( $dot_count / @colors );
        $color_swap_time++ if $color_swap_time * @colors < $dot_count;
    }

    elsif ($val->{'color_flow_type'} eq 'alternate'){
        my $dots_per_gradient = int ($dot_per_sec * 60 / $val->{'color_flow_speed'});
        my $gradient_steps = gradient_steps( $dots_per_gradient );
        my @color_objects = @colors;
        my @c = ($color_objects[0]);
        for my $i (0 .. $val->{'colors_used'}-2){
            pop @c;
            push @c, $color_objects[$i]->gradient(
                    to => $color_objects[$i+1],
                    steps => $gradient_steps,
                    dynamic => $val->{'color_flow_dynamic'},
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
    }

    elsif ($val->{'color_flow_type'} eq 'circular'){
        my $dots_per_gradient = int ($dot_per_sec * 60 / $val->{'color_flow_speed'});
        my $gradient_steps = gradient_steps( $dots_per_gradient );
        my @color_objects = @colors;
        my @c = ($color_objects[0]);
        for my $i (0 .. $val->{'colors_used'}-2){
            pop @c;
            push @c, $color_objects[$i]->gradient(
                    to => $color_objects[$i+1],
                    steps => $gradient_steps,
                    dynamic => $val->{'color_flow_dynamic'},
            );
        }
        pop @c;
        push @c, $color_objects[-1]->gradient(
                to => $color_objects[0],
                steps => $gradient_steps,
                dynamic => $val->{'color_flow_dynamic'},
        );
        pop @c;
        $color_swap_time = int ($dots_per_gradient / $gradient_steps);
        my $colors_needed = int($dot_count / ($color_swap_time + 1));
        $colors_needed++ if $colors_needed * ($color_swap_time + 1) < $dot_count;
        @colors = @c;
        push @colors, @c while $colors_needed > @colors;
    }
    return \@colors, $color_swap_time;
}

sub compile {
    my ($state, $progress_bar, $main_radius, $sketch) = @_;
    my $val = $state;
    my $Cr = $main_radius;
    my $t = Benchmark->new();

    my $dot_per_sec = ($val->{'visual'}{'dot_density'} || 1);
    my $dot_count = ((defined $sketch) ? 5 : $val->{'visual'}{'duration'}) * $dot_per_sec;

    $val->{'visual'}{'connect_dots'} = int ($val->{'visual'}{'draw'} eq 'Line');

    my ($colors, $color_swap_time) = calculate_colors( $val, $dot_count, $dot_per_sec );
    my @colors = @$colors;
    my @wx_colors = map { Wx::Colour->new( $_->values ) } @colors;

    my @pendulum_names = qw/x y e f w r/;
    my %init_code = (map {$_ => []} @pendulum_names);
    my %iter_code = (map {$_ => []} @pendulum_names);
    my @compute_pen_coordinates;

    # init variables
    for my $pendulum_name (@pendulum_names){
        # next unless $val->{$pendulum_name}{'on'}; # need all for mod matrix
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
            my $code = 'my $dr'.$index.' = '.$val->{'radius_damp'}.' / $dot_per_sec / 8_000 * $r'.$index;
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

    # update variables
    for my $pendulum_name (@pendulum_names){
        # next unless $val->{$pendulum_name}{'on'}; # need all for mod matrix
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

    my %var_names = ( 'X time' => '$tX', 'X freq.' => '$dtX', 'X radius' => '$rX',
                      'Y time' => '$tY', 'Y freq.' => '$dtY', 'Y radius' => '$rY',
                      'E time' => '$tE', 'E freq.' => '$dtE', 'E radius' => '$rE',
                      'F time' => '$tF', 'F freq.' => '$dtF', 'F radius' => '$rF',
                      'W time' => '$tW', 'W freq.' => '$dtW', 'W radius' => '$rW',
                      'R time' => '$tR', 'R freq.' => '$dtR', 'R radius' => '$rR');
 #  sin  cos
 #  tan  =  sin / cos
 #  cot  =  cos / sin
 #  sec  =  1 / cos
 #  csc  =  1 / sin
 #  sinh =  exp $x - exp (- $x)
 #  cosh =  exp $x + exp (- $x)
 #  tanh = sinh / cosh
 #  coth = coth / sinh
 #  sech = 1 / cosh
 #  csch = 1 / sinh

    # compute coordinates
    my ($factor, $term, $function);
    for my $eq (qw/x y e f wx wy r11 r12 r21 r22/){
        push @compute_pen_coordinates,'next unless '.$var_names{ $val->{'function'}{$eq.'_variable'} }
            if $val->{'function'}{$eq.'_operator'} eq '/';
        $factor->{$eq} = $val->{'function'}{$eq.'_factor'} * $val->{'function'}{$eq.'_constant'};
        $term->{$eq} = 'my $term'.uc($eq).' = ('.$factor->{$eq}.' * '.
                      $var_names{ $val->{'function'}{$eq.'_variable'} }.')'.
                      ($val->{'function'}{$eq.'_operator'} eq '=' ? ' + $t'.uc(substr($eq, 0, 1)) : '' );
    }
    if ($val->{'x'}{'on'}){
        push @compute_pen_coordinates, $term->{'x'}, '  $x = $rX * cos($termX)';
    } else { push @compute_pen_coordinates, '  $x = 0' }
    if ($val->{'y'}{'on'}){
        push @compute_pen_coordinates, $term->{'y'}, '  $y = $rY * sin($termY)';
    } else { push @compute_pen_coordinates, '  $y = 0' }
    if ($val->{'e'}{'on'}){
        push @compute_pen_coordinates, $term->{'e'}, '  $x += $rE * cos($termE)';
    }
    if ($val->{'f'}{'on'}){
        push @compute_pen_coordinates, $term->{'f'}, '  $y += $rF * cos($termF)';
    }
    if ($val->{'w'}{'on'}){
        push @compute_pen_coordinates, $term->{'wx'}, $term->{'wy'},
            '  $x += $rW * cos($termWX)',
            '  $y += $rW * sin($termWY)';
    }
    if ($val->{'r'}{'on'}){
        push @compute_pen_coordinates, $term->{'r11'}, $term->{'r12'}, $term->{'r21'},$term->{'r22'},
            ' ($x, $y) = ($rR * (($x * cos($termR11)) - ($y * sin($termR12)))'
                       .',$rR * (($x * sin($termR21)) + ($y * cos($termR22))))';
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
    push @code, 'my ($x_old, $y_old)', @compute_pen_coordinates, '$x += $Cx', '$y += $Cy'
        if $val->{'visual'}{'connect_dots'};
    push @code, '$dc->SetPen( Wx::Pen->new( shift @wx_colors, $pen_size, $pen_style ) )',
                'my $first_color = shift @colors';
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
    push @code, @compute_pen_coordinates, '  $x += $Cx', '  $y += $Cy';
    push @code, ($val->{'visual'}{'connect_dots'}
              ? '  $dc->DrawLine( $x_old, $y_old, $x, $y)'
              : '  $dc->DrawPoint( $x, $y )');
    push @code, '}';
    push @code, '$progress_bar->add_percentage( 100, [$first_color->values] )' unless defined $sketch or $color_swap_time ;

    my $code = join '', map {$_.";\n"} @code, '}'; # say $code;
    my $code_ref = eval $code;
    die "bug '$@' in drawing code: $code" if $@; #
    say "comp: ",timestr( timediff( Benchmark->new(), $t) );
    return $code_ref
}

1;
