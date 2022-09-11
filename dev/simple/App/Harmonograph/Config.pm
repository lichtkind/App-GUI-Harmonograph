use v5.12;
use warnings;
use File::HomeDir;
use File::Spec;

package App::Harmonograph::Config;

my $file = '.harmonograph';
my $dir = '';
my $default = {
    file_base_dir => '~',
    file_base_name => 'good',
    file_base_counter => 0,
    file_base_ending => 'png',
    open_dir => '~',
    save_dir => '~',
    write_dir => '~',
    last_settings => [],
    tips => 1,
    color => {bright_blue => [  98, 156, 249 ],
    'marsala'             => [ 149,  82,  81 ],
    'radiandorchid'       => [ 181, 101, 167 ],
    'emerald'             => [   0, 155, 119 ],
    'tangerinetango'      => [ 221,  65,  36 ],
    'honeysucle'          => [ 214,  80, 118 ],
    'turquoise'           => [  69, 184, 172 ],
    'mimosa'              => [ 239, 192,  80 ],
    'blueizis'            => [  91,  94, 166 ],
    'chilipepper'         => [ 155,  27,  48 ],
    'sanddollar'          => [ 223, 207, 190 ],
    'blueturquoise'       => [  85, 180, 176 ],
    'tigerlily'           => [ 225,  93,  68 ],
    'aquasky'             => [ 127, 205, 205 ],
    'truered'             => [ 188,  36,  60 ],
    'fuchsiarose'         => [ 195,  68, 122 ],
    'ceruleanblue'        => [ 152, 180, 212 ],
},};

sub new {
    my ($pkg) = @_;
    for my $d ('.', File::HomeDir->my_home, File::HomeDir->my_documents){
        my $path = File::Spec->catfile( $d, $file );
        $dir = $d if -r $path;
    }
    my $data = $dir 
             ? load( $pkg, File::Spec->catfile( $dir, $file ) )
             : $default;
    $dir ||= File::HomeDir->my_home;
    bless { path => File::Spec->catfile( $dir, $file ), data => $data };
}

sub load {
    my ($self, $file) = @_;
    my $data = {};
    open my $FH, '<', $file or return "could not read $file: $!";
    my $cat = '';
    while (<$FH>) {
        chomp;
        next unless $_ or substr( $_, 0, 1) eq '#';
        if    (/^\s*(\w+):/)              {                   $cat = $1 }
        elsif (/^\s+-\s+(\S+)\s*$/)       { push @{$data->{$cat}}, $1   }
        elsif (/^\s+\+\s+(\w+)\s*=\s*\[\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\]/) 
                                          { $data->{$cat}{$1} = [$2, $3, $4] }
        elsif (/\s*(\w+)\s*=\s*(.+)\s*$/) { $data->{$1} = $2; $cat = '' }
    }
    close $FH;
    $data;
}
    
sub save {
    my ($self) = @_;
    my $data = $self->{'data'};
    my $file = $self->{'path'};
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


sub get_value {
    my ($self, $key) = @_;
    $self->{'data'}{$key};
}

sub set_value {
    my ($self, $key, $value) = @_;
    $self->{'data'}{$key} = $value;
}

sub add_setting_file {
    my ($self, $file) = @_;
    $file = App::Harmonograph::Settings::shrink_path( $file );
    for my $f (@{$self->{'data'}{'last_settings'}}) { return if $f eq $file }
    push @{$self->{'data'}{'last_settings'}}, $file;
    shift @{$self->{'data'}{'last_settings'}} if @{$self->{'data'}{'last_settings'}} > 15;
}

sub add_color {
    my ($self, $name, $color) = @_;
    return 'not a color' unless ref $color eq 'ARRAY' and @$color == 3
        and int $color->[0] == $color->[0] and $color->[0] < 256 and $color->[0] >= 0 
        and int $color->[1] == $color->[1] and $color->[1] < 256 and $color->[1] >= 0
        and int $color->[2] == $color->[2] and $color->[2] < 256 and $color->[2] >= 0; 
    return 'color name alread taken' if exists $self->{'data'}{'color'}{ $name };
    $self->{'data'}{'color'}{ $name } = $color;
}

sub delete_color {
    my ($self, $name) = @_;
    delete $self->{'data'}{'color'}{ $name }
}


1;
