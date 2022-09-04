use v5.12;
use warnings;
use File::HomeDir;

package App::Harmonograph::Config;

my $file = 'harmonograph.cfg';
my $default = {
    file_base => './img/series',
    open_dir => '',
    save_dir => '',
    write_dir => '',
    last_settings => [],
    color => {bright_blue => [ 98, 156, 249 ], },
};

sub init {
    # find config file, 
    my $data = {};
    # if not init one  $data = $default;
    # -r $file 
    # load it
    open my $FH, '<', $file or return "could not read $file: $!";
    my $cat = '';
    while (<$FH>) {
        chomp;
        next unless $_ or substr( $_, 0, 1) eq '#';
        if    (/\s*(\w+)\s*=\s*(.+)\s*$/){ $data->{$1} = $2; $cat = '' }
        elsif (/\s*(\w+):/)              {                   $cat = $1 }
        elsif (/\s*-\s*(\w+)/)           { push @{$data->{$cat}}, $1   }
        elsif (/\s*+\s*(\w+)\s*=\s*\[\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\]/) 
                                         { $data->{$cat}{$1} = [$2, $3, $4]}
    }
    close $FH;

# File::HomeDir->my_home;
# File::HomeDir->my_documents
    
}

sub save {
    my ($data) = @_;
    open my $FH, '>', $file or return "could not write $file: $!";
    for my $key (sort keys %$data){
        my $val = $data->{ $key };
        if (ref $val eq 'ARRAY'){
            say $FH "$key:";
            say $FH "  - $_" for @$val;
        } elsif (ref $val eq 'HASH'){
            say $FH "$key:";
            say $FH "  + $_ = [ $val->{$_}[0], $val->{$_}[1], $val->{$_}[2] ]" for sort keys %$val;
        } elsif (not ref $val){
            say $FH "$key = $val";
        }
    }
    close $FH;
}


sub get {
    my $key = shift;
    
}

sub set {
    my ($key, $value) = @_;
    
    
}

sub add_setting {
    my ($key, $value) = @_;
    
    
}

sub add_color {
    my ($key, $value) = @_;
    
    
}


1;
