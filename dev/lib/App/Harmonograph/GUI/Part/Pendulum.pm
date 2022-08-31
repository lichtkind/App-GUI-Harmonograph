use v5.18;
use warnings;
use Wx;

package App::Harmonograph::GUI::Part::Pendulum;
my $VERSION = 0.1;
use base qw/Wx::Panel/;
use App::Harmonograph::GUI::SliderCombo;

sub new {
    my ( $class, $parent, $label, $help, $on, $max,  ) = @_;
    return unless defined $max;
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'name'} = $label;
    $self->{'maxf'} = $max;
    $self->{'initially_on'} = $on;

    $self->{'on'} = Wx::CheckBox->new( $self, -1, '', [-1,-1],[-1,-1], 1 );
    $self->{'on'}->SetToolTip('set partial pendulum on or off');
    
    my $lbl  = Wx::StaticText->new($self, -1, uc($label) );

    $self->{'freq'}  = App::Harmonograph::GUI::SliderCombo->new
                        ( $self, 100, 'f', 'frequency of '.$help, 1, $max, 1 );
    $self->{'fdez'} = App::Harmonograph::GUI::SliderCombo->new
                        ( $self, 100, 'f  dec.', 'decimals of frequency at '.$help, 0, 1000, 0);
    $self->{'inv'} = Wx::CheckBox->new( $self, -1, ' Inv.');
    $self->{'inv'}->SetToolTip('invert (1/x) pendulum frequency');
    $self->{'dir'} = Wx::CheckBox->new( $self, -1, ' Dir.');
    $self->{'dir'}->SetToolTip('invert pendulum direction');
    $self->{'2_off'} = Wx::CheckBox->new( $self, -1, ' 2');
    $self->{'2_off'}->SetToolTip('pendulum starts with offset of half rotation');
    $self->{'4_off'} = Wx::CheckBox->new( $self, -1, ' 4');
    $self->{'4_off'}->SetToolTip('pendulum starts with offset of quater rotation');
    $self->{'offset'} = App::Harmonograph::GUI::SliderCombo->new
                            ($self, 100, 'Offset', 'additional offset pendulum starts with (0 - quater rotation)', 0, 100, 0);
                            
    $self->{'radius'} = App::Harmonograph::GUI::SliderCombo->new( $self, 100, 'r', 'radius of pendulum swing', 0, 150, 100);
    $self->{'damp'} = App::Harmonograph::GUI::SliderCombo->new( $self, 100, 'Damp', 'damping factor', 0, 400, 0);


    Wx::Event::EVT_CHECKBOX( $self, $self->{'on'}, sub { $self->update_enable() });
    
    my $f_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $f_sizer->Add( $self->{'freq'},       0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxLEFT, 49);
    $f_sizer->Add( $self->{'fdez'},      0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxLEFT,   8);
    $f_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);
    
    my $r_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $r_sizer->Add( $self->{'on'},      0, &Wx::wxALIGN_LEFT|&Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW|&Wx::wxLEFT, 0);
    $r_sizer->Add( $lbl,               0, &Wx::wxALIGN_LEFT|&Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW|&Wx::wxALL, 12);
    $r_sizer->Add( $self->{'radius'},  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxLEFT,  0);
    $r_sizer->Add( $self->{'damp'},    0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxLEFT,  0);
    $r_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);
    
    my $o_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $o_sizer->Add( $self->{'inv'},     0, &Wx::wxALIGN_LEFT|&Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW|&Wx::wxLEFT, 86);
    $o_sizer->Add( $self->{'dir'},     0, &Wx::wxALIGN_LEFT|&Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW|&Wx::wxLEFT, 20);
    $o_sizer->Add( $self->{'2_off'},   0, &Wx::wxALIGN_LEFT|&Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW|&Wx::wxLEFT, 20);
    $o_sizer->Add( $self->{'4_off'},   0, &Wx::wxALIGN_LEFT|&Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW|&Wx::wxLEFT,  8);
    $o_sizer->Add( $self->{'offset'},  0, &Wx::wxALIGN_LEFT|&Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW|&Wx::wxLEFT,  0);
    $o_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);
    
    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->Add( $r_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW, 0);
    $sizer->Add( $f_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW, 0);
    $sizer->Add( $o_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW, 0);
    $self->SetSizer($sizer);

    $self->init();
    $self;
}

sub init {
    my ( $self ) = @_;
    $self->set_data ({ on => $self->{'initially_on'}, freq => 1, dir => 0, offset => 0, radius => 1, damp => 0} );
}

sub get_data {
    my ( $self ) = @_;
    my $f = $self->{'freq'}->GetValue + $self->{'fdez'}->GetValue/100;
    $f = 1 / $f if $self->{ 'inv' }->IsChecked;
    {
        freq => $f,
        on => $self->{ 'on' }->IsChecked ? 1 : 0,
        dir => $self->{ 'dir' }->IsChecked ? 1 : 0,
        offset => (0.5 * $self->{'2_off'}->IsChecked) 
                + (0.25 * $self->{'4_off'}->IsChecked) 
                + ($self->{'offset'}->GetValue / 400),
        radius => $self->{'radius'}->GetValue / 100,
        damp => $self->{'damp'}->GetValue,
    }
}

sub set_data {
    my ( $self, $data ) = @_;
    return unless ref $data eq 'HASH';
    $self->{ 'data'} = $data;
    $self->{ 'freq' }->SetValue( int $data->{'freq'} );
    $self->{ 'fdez' }->SetValue( 1000 * ($data->{'freq'} - int $data->{'freq'} ) );
    $self->{ 'on' }->SetValue( $data->{'on'} );
    $self->{ 'dir' }->SetValue( $data->{'dir'} );
    $self->{ '2_off' }->SetValue( $data->{'offset'} >= 0.5 );
    $data->{ 'offset' } -= 0.5 if $data->{'offset'} >= 0.5;
    $self->{ '4_off' }->SetValue( $data->{'offset'} >= 0.25 );
    $data->{ 'offset' } -= 0.25 if $data->{'offset'} >= 0.25;
    $self->{ 'radius' }->SetValue( $data->{'radius'} * 100 );
    $self->{ 'damp' }->SetValue( $data->{'damp'} );
    $self->update_enable;
}

sub update_enable {
    my ($self) = @_;
    my $val = $self->{ 'on' }->IsChecked;
    $self->{$_}->Enable( $val ) for qw/freq fdez inv dir 2_off 4_off offset radius damp/;
}


1;
