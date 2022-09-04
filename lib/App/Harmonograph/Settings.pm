use v5.12;
use warnings;

# parameter of a drawing

package App::Harmonograph::Settings;

sub load {
    my ($file) = @_;
    my $data = {};
    open my $FH, '<', $file or return "could not read $file: $!";
    my $cat = '';
    while (<$FH>) {
        chomp;
        next unless $_ or substr( $_, 0, 1) eq '#';
        if    (/\s*\[(\w+)\]/)           { $cat = $1 }
        elsif (/\s*(\w+)\s*=\s*(.+)\s*$/){ $data->{$cat}{$1} = $2 }
    }
    close $FH;
    $data;
}

sub write {
    my ($file, $data) = @_;
    open my $FH, '>', $file or return "could not write $file: $!";
    for my $main_key (sort keys %$data){
        say $FH "\n  [$main_key]\n";
        my $subhash = $data->{$main_key};
        next unless ref $subhash eq 'HASH';
        for my $key (sort keys %$subhash){
            say $FH "$key = $subhash->{$key}";
        }
    }
    close $FH;
    0;
}

sub are_equal {
    my ($h1, $h2)  = @_;
    return 0 unless ref $h1 eq 'HASH' and $h2 eq 'HASH';
    for my $key (keys %$h1){
        next if not ref $h1->{$key} and exists $h2->{$key} and not ref $h2->{$key} and $h1->{$key} eq $h2->{$key};
        next if are_equal( $h1->{$key}, $h2->{$key} );
        return 0;
    }
}


1;
