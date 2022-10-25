use v5.12;
use warnings;

package App::GUI::Harmonograph::Function;
use Benchmark;
my $PI  = 3.1415926535;

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

sub init {
    my $precision = shift;   # 4 => 0.1 ; 5 => 1 sec computation
    my $faktor = 10 ** $precision;
    for (1 .. $PI * $faktor) {
        $sin->[$_] = CORE::sin ($_/$faktor);
        $cos->[$_] = CORE::cos ($_/$faktor);
        $tan->[$_] = $cos->[$_] ? $sin->[$_] / $cos->[$_] : $faktor;
        $sec->[$_] = $cos->[$_] ?          1 / $cos->[$_] : $faktor;
        $csc->[$_] = $sin->[$_] ?          1 / $sin->[$_] : $faktor;
        $cot->[$_] = $sin->[$_] ? $cos->[$_] / $sin->[$_] : $faktor;
        my $ep = exp $_ / $faktor;
        my $em = exp -$_ / $faktor;
        $sinh->[$_] = $ep - $em;
        $cosh->[$_] = $ep + $em;
        $tanh->[$_] = $cosh->[$_] ? $sinh->[$_] / $cosh->[$_] : $faktor;
        $sech->[$_] = $cosh->[$_] ?           1 / $cosh->[$_] : $faktor;
        $csch->[$_] = $sinh->[$_] ?           1 / $sinh->[$_] : $faktor;
        $coth->[$_] = $sinh->[$_] ? $cosh->[$_] / $sinh->[$_] : $faktor;
        
    }

}

sub sin  { $tan->[int $_[0]] }
sub cos  { $tan->[int $_[0]] }
sub tan  { $tan->[int $_[0]] } # sin / cos
sub sec  { $tan->[int $_[0]] } # 1 / cos
sub csc  { $tan->[int $_[0]] } # 1 / sin
sub cot  { $tan->[int $_[0]] } # cos / sin
sub sinh { $tan->[int $_[0]] } # exp $x - exp (- $x)
sub cosh { $tan->[int $_[0]] } # exp $x + exp (- $x)
sub tanh { $tan->[int $_[0]] } # sinh / cosh
sub sech { $tan->[int $_[0]] } # 1 / cosh
sub csch { $tan->[int $_[0]] } # 1 / sinh
sub coth { $tan->[int $_[0]] } # coth / sinh

1;
