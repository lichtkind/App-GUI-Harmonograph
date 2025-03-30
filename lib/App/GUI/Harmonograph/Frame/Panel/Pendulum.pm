
# settings for all pendula

package App::GUI::Harmonograph::Frame::Panel::Pendulum;
use base qw/Wx::Panel/;
use v5.12;
use utf8;
use warnings;
use Wx;
use App::GUI::Harmonograph::Widget::SliderCombo;

my $PI    = 3.1415926535;
my $PHI   = 1.618033988;
my $phi   = 0.618033988;
my $e     = 2.718281828;
my $GAMMA = 1.7724538509055160;

sub new {
    my ( $class, $parent, $label, $help, $on, $max ) = @_;
    return unless defined $max;
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'name'} = $label;
    $self->{'maxf'} = $max;
    $self->{'initially_on'} = $on;
    $self->{'callback'} = sub {};

    $self->{'on'} = Wx::CheckBox->new( $self, -1, '', [-1,-1], [-1,-1], $on );
    $self->{'on'}->SetToolTip('set partial pendulum on or off');

    my $main_label  = Wx::StaticText->new($self, -1, uc($label) );

    $self->{'frequency'}  = App::GUI::Harmonograph::Widget::SliderCombo->new
                        ( $self, 100, 'Frequency', 'frequency of '.$help, 1, $max, 1 );
    $self->{'freq_dez'} = App::GUI::Harmonograph::Widget::SliderCombo->new
                        ( $self, 100, 'Precise   ', 'decimals of frequency at '.$help, 0, 1000, 0);
    my @factor = grep {lc $_ ne lc $self->{'name'}} qw/1 π Φ φ e Γ/;
    $self->{'freq_factor'} = Wx::ComboBox->new( $self, -1, 1, [-1,-1],[70, 20], \@factor);
    $self->{'freq_factor'}->SetToolTip('base factor the frequency will be multiplied with: one (no), or a math constants as shown');
    $self->{'freq_damp'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 100, 'Damp  ', 'damping factor (diminishes frequency over time)', 0, 100, 0);
    $self->{'freq_damp_type'} = Wx::ComboBox->new( $self, -1, '*', [-1,-1],[70, 20], [ '*', '-']);
    $self->{'freq_damp_acc'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 100, 'Acceleration ', 'accelaration of damping factor', 0, 100, 0);
    $self->{'freq_damp_acc_type'} = Wx::ComboBox->new( $self, -1, '*', [-1,-1],[70, 20], [ '*', '/', '+', '-']);
    $self->{'invert_freq'} = Wx::CheckBox->new( $self, -1, ' Inv.');
    $self->{'invert_freq'}->SetToolTip('invert (1/x) pendulum frequency');
    $self->{'direction'} = Wx::CheckBox->new( $self, -1, ' Dir.');
    $self->{'direction'}->SetToolTip('invert pendulum direction (to counter clockwise)');
    $self->{'half_off'} = Wx::CheckBox->new( $self, -1, ' 180');
    $self->{'half_off'}->SetToolTip('pendulum starts with offset of half rotation');
    $self->{'quarter_off'} = Wx::CheckBox->new( $self, -1, ' 90');
    $self->{'quarter_off'}->SetToolTip('pendulum starts with offset of quater rotation');
    $self->{'offset'} = App::GUI::Harmonograph::Widget::SliderCombo->new
                            ($self, 110, 'Offset', 'additional offset pendulum starts with (0 - quater rotation)', 0, 100, 0);
    $self->{'radius'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 100, 'Radius %', 'radius or amplitude of pendulum swing', 0, 150, 100);
    $self->{'radius_damp'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 100, 'Damp  ', 'damping factor (diminishes amplitude over time)', 0, 100, 0);
    $self->{'radius_damp_type'} = Wx::ComboBox->new( $self, -1, '*', [-1,-1],[70, 20], [ '*', '-']);
    $self->{'radius_damp_acc'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 100, 'Acceleration ', 'accelaration of damping factor', 0, 100, 0);
    $self->{'radius_damp_acc_type'} = Wx::ComboBox->new( $self, -1, '*', [-1,-1],[70, 20], [ '*', '/', '+', '-']);

    Wx::Event::EVT_CHECKBOX( $self, $self->{'on'},          sub { $self->update_enable(); $self->{'callback'}->() });
    Wx::Event::EVT_CHECKBOX( $self, $self->{'invert_freq'}, sub {                         $self->{'callback'}->() });
    Wx::Event::EVT_CHECKBOX( $self, $self->{'direction'},   sub {                         $self->{'callback'}->() });
    Wx::Event::EVT_CHECKBOX( $self, $self->{'half_off'},    sub {                         $self->{'callback'}->() });
    Wx::Event::EVT_CHECKBOX( $self, $self->{'quarter_off'}, sub {                         $self->{'callback'}->() });
    Wx::Event::EVT_COMBOBOX( $self, $self->{'freq_factor'}, sub {                         $self->{'callback'}->() });
    Wx::Event::EVT_COMBOBOX( $self, $self->{'freq_damp_type'},       sub {                $self->{'callback'}->() });
    Wx::Event::EVT_COMBOBOX( $self, $self->{'radius_damp_type'},     sub {                $self->{'callback'}->() });
    Wx::Event::EVT_COMBOBOX( $self, $self->{'radius_damp_acc_type'}, sub {                $self->{'callback'}->() });

    my $base_attr = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxGROW;
    my $box_attr = $base_attr | &Wx::wxTOP | &Wx::wxBOTTOM;

    my $f_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $f_sizer->Add( $self->{'on'},        0, $base_attr, 0);
    $f_sizer->Add( $main_label,          0, $base_attr|&Wx::wxTOP|&Wx::wxLEFT, 6);
    $f_sizer->Add( $self->{'frequency'}, 0, $base_attr|&Wx::wxLEFT, 5);
    $f_sizer->AddSpacer( 18 );
    $f_sizer->Add( $self->{'freq_factor'}, 0, $box_attr |&Wx::wxLEFT,  0);
    $f_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $fdez_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $fdez_sizer->Add( $self->{'freq_dez'},    0, $base_attr|&Wx::wxLEFT, 51);
    $fdez_sizer->AddSpacer( 5 );
    $fdez_sizer->Add( $self->{'invert_freq'}, 0, $base_attr|&Wx::wxLEFT, 9);
    $fdez_sizer->Add( $self->{'direction'},   0, $base_attr|&Wx::wxLEFT, 7);
    $fdez_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $f_damp_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $f_damp_sizer->Add( $self->{'freq_damp'},     0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxLEFT, 62);
    $f_damp_sizer->AddSpacer( 19 );
    $f_damp_sizer->Add( $self->{'freq_damp_type'}, 0, $box_attr |&Wx::wxLEFT, 0);
    $f_damp_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $f_acc_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $f_acc_sizer->Add( $self->{'freq_damp_acc'}, 0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxLEFT, 25);
    $f_acc_sizer->AddSpacer( 19 );
    $f_acc_sizer->Add( $self->{'freq_damp_acc_type'}, 0, $box_attr |&Wx::wxLEFT,  0);
    $f_acc_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $offset_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $offset_sizer->AddSpacer( 65 );
    $offset_sizer->Add( $self->{'offset'},      0, $box_attr,  8);
    $offset_sizer->Add( $self->{'quarter_off'}, 0, $base_attr|&Wx::wxLEFT, 8);
    $offset_sizer->Add( $self->{'half_off'},    0, $base_attr|&Wx::wxLEFT, 8);
    $offset_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $r_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $r_sizer->Add( $self->{'radius'},   0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxLEFT,  50);
    $r_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $r_damp_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $r_damp_sizer->Add( $self->{'radius_damp'},     0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxLEFT, 62);
    $r_damp_sizer->AddSpacer( 18 );
    $r_damp_sizer->Add( $self->{'radius_damp_type'}, 0, $box_attr |&Wx::wxLEFT,  0);
    $r_damp_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $r_acc_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $r_acc_sizer->Add( $self->{'radius_damp_acc'}, 0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxLEFT, 25);
    $r_acc_sizer->AddSpacer( 18 );
    $r_acc_sizer->Add( $self->{'radius_damp_acc_type'}, 0, $box_attr |&Wx::wxLEFT,  0);
    $r_acc_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->AddSpacer( 5 );
    $sizer->Add( $f_sizer,      0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 0);
    $sizer->Add( $fdez_sizer,   0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 13);
    $sizer->Add( $f_damp_sizer, 0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 13);
    $sizer->Add( $f_acc_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 13);
    $sizer->Add( $offset_sizer, 0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP ,  8);
    $sizer->Add( $r_sizer,      0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP ,  8);
    $sizer->Add( $r_damp_sizer, 0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 13);
    $sizer->Add( $r_acc_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 13);
    $sizer->AddSpacer( 5 );
    $self->SetSizer($sizer);
    $self;
}

sub SetCallBack {
    my ( $self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'callback'} = $code;
    $self->{ $_ }->SetCallBack( $code ) for qw /radius radius_damp radius_damp_acc offset
                                                freq_damp_acc frequency freq_dez freq_damp/;
}

sub init {
    my ( $self ) = @_;
    $self->set_settings ({
        on => $self->{'initially_on'},
        frequency => 1, freq_factor => 1, freq_damp => 0, freq_damp_type => '*',
        freq_damp_acc => 0,freq_damp_acc_type => '*', direction => 0, invert_freq => 0,
        offset => 0, radius => 1, radius_damp => 0, radius_damp_acc => 0,
        radius_damp_type => '*', radius_damp_acc_type => '*' } );
}

sub get_settings {
    my ( $self ) = @_;
    my $f = $self->{'frequency'}->GetValue + $self->{'freq_dez'}->GetValue/1000;
    my $ff = $self->{'freq_factor'}->GetValue;
    {
        on          => $self->{ 'on' }->IsChecked ? 1 : 0,
        direction   => $self->{ 'direction'}->IsChecked ? 1 : 0,
        invert_freq => $self->{ 'invert_freq'}->IsChecked ? 1 : 0,
        frequency   => $f,
        freq_factor => (($ff eq 1)   ? 1    : ($ff eq 'π') ? $PI : ($ff eq 'Φ') ? $PHI :
                        ($ff eq 'φ') ? $phi : ($ff eq 'e') ? $e  :                $GAMMA),
        freq_damp   => $self->{'freq_damp'}->GetValue,
        freq_damp_type => $self->{'freq_damp_type'}->GetValue,
        freq_damp_type => $self->{'freq_damp_type'}->GetValue,
        freq_damp_acc_type  => $self->{'freq_damp_acc_type'}->GetValue,
        offset      => (0.5 * $self->{'half_off'}->IsChecked)
                     + (0.25 * $self->{'quarter_off'}->IsChecked)
                     + ($self->{'offset'}->GetValue / 400),
        radius      => $self->{'radius'}->GetValue / 100,
        radius_damp => $self->{'radius_damp'}->GetValue,
        radius_damp_acc  => $self->{'radius_damp_acc'}->GetValue,
        radius_damp_type => $self->{'radius_damp_type'}->GetValue,
        radius_damp_acc_type  => $self->{'radius_damp_acc_type'}->GetValue,
    }
}

sub set_settings {
    my ( $self, $data ) = @_;
    return unless ref $data eq 'HASH' and exists $data->{'frequency'}
        and exists $data->{'offset'} and exists $data->{'radius'} and exists $data->{'radius_damp'};
    $self->{ 'data'} = $data;
    $self->{ 'on' }->SetValue( $data->{'on'} );
    $self->{ 'direction' }->SetValue( $data->{'direction'} );
    $self->{ 'invert_freq' }->SetValue( $data->{'invert_freq'} );
    $self->{ 'frequency'}->SetValue( int $data->{'frequency'} );
    $self->{ 'freq_dez' }->SetValue( int( 1000 * ($data->{'frequency'} - int $data->{'frequency'} ) ), 'passive' );
    my $ff = $data->{ 'freq_factor'} // 1;
    $self->{ 'freq_factor'}->SetValue( ($ff == 1) ? 1  : ($ff < 1) ? 'φ' : ($ff > 3) ? 'π' :
                                       ($ff > 2) ? 'e' : ($ff > 1.7) ? 'Γ' :           'Φ' );
    $self->{ 'freq_damp' }->SetValue( $data->{'freq_damp'}, 'passive' );
    $self->{ 'freq_damp_acc' }->SetValue( $data->{'freq_damp_acc'}, 'passive' );
    $self->{ 'freq_damp_type'}->SetValue(  $data->{ 'freq_damp_type'} // '*' );
    $self->{ 'freq_damp_acc_type'}->SetValue(  $data->{ 'freq_damp_type'} // '*' );
    $self->{ 'half_off' }->SetValue( $data->{'offset'} >= 0.5 );
    $data->{ 'offset' } -= 0.5 if $data->{'offset'} >= 0.5;
    $self->{ 'quarter_off' }->SetValue( $data->{'offset'} >= 0.25 );
    $data->{ 'offset' } -= 0.25 if $data->{'offset'} >= 0.25;
    $self->{ 'offset'}->SetValue( int( $data->{'offset'} * 400 ), 'passive');
    $self->{ 'radius' }->SetValue( $data->{'radius'} * 100, 'passive' );
    $self->{ 'radius_damp' }->SetValue( $data->{'radius_damp'}, 'passive' );
    $self->{ 'radius_damp_acc' }->SetValue( $data->{'radius_damp_acc'}, 'passive');
    $self->{ 'radius_damp_type'}->SetValue(  $data->{ 'radius_damp_type'} // '*' );
    $self->{ 'radius_damp_acc_type'}->SetValue(  $data->{ 'radius_damp_acc_type'} // '*' );
    $self->update_enable;
    1;
}

sub update_enable {
    my ($self) = @_;
    my $val = $self->{ 'on' }->IsChecked;
    $self->{$_}->Enable( $val ) for qw/
        freq_dez freq_factor invert_freq direction half_off quarter_off offset
        frequency freq_damp freq_damp_acc freq_damp_type freq_damp_acc_type
        radius radius_damp radius_damp_acc radius_damp_type radius_damp_acc_type/;
}

1;
