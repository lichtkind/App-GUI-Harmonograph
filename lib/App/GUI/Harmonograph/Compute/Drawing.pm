use v5.12;
use warnings;

package App::GUI::Harmonograph::Compute::Drawing;
use Benchmark;

my $TAU = 6.283185307;


sub prepare {
    my ($data, $main_radius, $sketch) = @_;
    my $val = $data;
    my $ret = {};

    my $step_in_circle = ($val->{'line'}{'density'}**2);
    my $t_iter = (defined $sketch) ? 5 : $val->{'line'}{'length'} * 10;
    $t_iter *= $step_in_circle;


    my $fX = $val->{'x'}{'frequency'} * $val->{'x'}{'freq_factor'};
    my $fY = $val->{'y'}{'frequency'} * $val->{'y'}{'freq_factor'};
    my $fZ = $val->{'z'}{'frequency'} * $val->{'z'}{'freq_factor'};
    my $fR = $val->{'r'}{'frequency'} * $val->{'r'}{'freq_factor'};
    my $dfX = $val->{'x'}{'freq_damp'} / $step_in_circle / 600_000;
    my $dfY = $val->{'y'}{'freq_damp'} / $step_in_circle / 600_000;
    my $dfZ = $val->{'z'}{'freq_damp'} / $step_in_circle / 600_000;
    my $dfR = $val->{'r'}{'freq_damp'} / $step_in_circle / 600_000;
    if ($val->{'x'}{'direction'}){  $fX = - $fX;   $dfX = - $dfX; }
    if ($val->{'y'}{'direction'}){  $fY = - $fY;   $dfY = - $dfY; }
    if ($val->{'z'}{'direction'}){  $fZ = - $fZ;   $dfZ = - $dfZ; }
    if ($val->{'r'}{'direction'}){  $fR = - $fR;   $dfR = - $dfR; }
    if ($val->{'x'}{'invert_freq'}){$fX = 1 / $fX; $dfX = $dfX / $fX; }
    if ($val->{'y'}{'invert_freq'}){$fY = 1 / $fY; $dfY = $dfX / $fY; }
    if ($val->{'z'}{'invert_freq'}){$fZ = 1 / $fZ; $dfZ = $dfZ / $fZ; }
    if ($val->{'r'}{'invert_freq'}){$fR = 1 / $fR; $dfR = $dfR / $fR; }
    $dfX = 1 - ($dfX * 30) if $val->{'x'}{'freq_damp_type'} eq '*';
    $dfY = 1 - ($dfY * 30) if $val->{'y'}{'freq_damp_type'} eq '*';
    $dfZ = 1 - ($dfZ * 30) if $val->{'z'}{'freq_damp_type'} eq '*';
    $dfR = 1 - ($dfR * 30) if $val->{'r'}{'freq_damp_type'} eq '*';


}

1;
__END__

my $factor = 0;

my $sin  = [];
my $cos  = [];
my $tan  = [];
my $sec  = [];
my $csc  = [];
my $cot  = [];
my $sinh = [];
my $cosh = [];
my $tanh = [];
my $sech = [];
my $csch = [];
my $coth = [];

# init( 4 );

sub factor { $factor }
sub init {
    my $precision = shift;   # 4 => 0.1 ; 5 => 1 sec computation
    $factor = 10 ** $precision;
    for (0 .. $TAU * $factor) {
        $sin->[$_] = CORE::sin ($_/$factor);
        $cos->[$_] = CORE::cos ($_/$factor);
        $tan->[$_] = $cos->[$_] ? $sin->[$_] / $cos->[$_] : $factor;
        $sec->[$_] = $cos->[$_] ?          1 / $cos->[$_] : $factor;
        $csc->[$_] = $sin->[$_] ?          1 / $sin->[$_] : $factor;
        $cot->[$_] = $sin->[$_] ? $cos->[$_] / $sin->[$_] : $factor;
        my $ep = exp $_ / $factor;
        my $em = exp -$_ / $factor;
        $sinh->[$_] = $ep - $em;
        $cosh->[$_] = $ep + $em;
        $tanh->[$_] = $cosh->[$_] ? $sinh->[$_] / $cosh->[$_] : $factor;
        $sech->[$_] = $cosh->[$_] ?           1 / $cosh->[$_] : $factor;
        $csch->[$_] = $sinh->[$_] ?           1 / $sinh->[$_] : $factor;
        $coth->[$_] = $sinh->[$_] ? $cosh->[$_] / $sinh->[$_] : $factor;

    }

}

#sub sin  { $sin ->[ int $_[0] ] }
#sub cos  { $cos ->[ int $_[0] ] }
#sub tan  { $tan ->[ int $_[0] ] } # sin / cos
#sub sec  { $sec ->[ int $_[0] ] } # 1 / cos
#sub csc  { $csc ->[ int $_[0] ] } # 1 / sin
#sub cot  { $cot ->[ int $_[0] ] } # cos / sin
#sub sinh { $sinh->[ int $_[0] ] } # exp $x - exp (- $x)
#sub cosh { $cosh->[ int $_[0] ] } # exp $x + exp (- $x)
#sub tanh { $tanh->[ int $_[0] ] } # sinh / cosh
#sub sech { $sech->[ int $_[0] ] } # 1 / cosh
#sub csch { $csch->[ int $_[0] ] } # 1 / sinh
#sub coth { $coth->[ int $_[0] ] } # coth / sinh

sub sin  { CORE::sin($_[0]) }
sub cos  { CORE::cos($_[0]) }
sub tan  { my $c = CORE::cos($_[0]); $c ? (CORE::sin($_[0]) / $c) : 10 } # sin / cos
sub cot  { my $s = CORE::sin($_[0]); $s ? (CORE::cos($_[0]) / $s) : 10 } # cos / sin
sub sec  { my $c = CORE::cos($_[0]); $c ? (1 / $c) : 10 } # 1 / cos
sub csc  { my $s = CORE::sin($_[0]); $s ? (1 / $s) : 10 } # 1 / sin
sub sinh { exp($_[0]) - exp(-$_[0]) } # exp $x - exp (- $x)
sub cosh { exp($_[0]) + exp(-$_[0]) } # exp $x + exp (- $x)
sub tanh { my $ep = exp($_[0]); my $em = exp(-$_[0]); ($ep - $em) / ($ep + $em) } # sinh / cosh
sub coth { my $ep = exp($_[0]); my $em = exp(-$_[0]); ($ep + $em) / ($ep - $em) } # coth / sinh
sub sech { 1 / (exp($_[0]) + exp(-$_[0])) } # 1 / cosh
sub csch { my $e = (exp($_[0]) - exp(-$_[0])); $e ? 1 / $e : 10 } # 1 / sinh
