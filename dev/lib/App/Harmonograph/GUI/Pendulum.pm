use v5.18;
use warnings;
use Wx;

package App::Harmonograph::GUI::Pendulum;
my $VERSION = 0.1;
use base qw/Wx::Panel/;
use App::Harmonograph::GUI::SliderCombo;

sub new {
    my ( $class, $parent, $label, $help, $on, $max,  ) = @_;
    return unless defined $max;
    my $self = $class->SUPER::new( $parent, -1, [-1,-1], [-1, -1] );

    $self->{'maxf'} = $max;
    $self->{'initially_on'} = $on;

    $self->{'on'} = Wx::CheckBox->new( $self, -1, '', [-1,-1],[-1,-1], 1 );
    $self->{'on'}->SetToolTip('set partial pendulum on or off');
    $self->{'f'}  = App::Harmonograph::GUI::SliderCombo->new( $self, 100, ' '.uc($label).'  ', 
                           'frequency of '.$help, 1,   $max,   1);
    $self->{'dir'} = Wx::CheckBox->new( $self, -1, ' <->', [-1,-1],[-1,-1] );
    $self->{'dir'}->SetToolTip('invert pendulum direction');
    $self->{'2_off'} = Wx::CheckBox->new( $self, -1, ' 2', [-1,-1],[-1,-1] );
    $self->{'2_off'}->SetToolTip('pendulum starts with offset of half rotation');
    $self->{'4_off'} = Wx::CheckBox->new( $self, -1, ' 4', [-1,-1],[-1,-1] );
    $self->{'4_off'}->SetToolTip('pendulum starts with offset of quater rotation');
    $self->{'offset'} = Wx::Slider->new( $self, -1, 0, 0, 100, [-1, -1], [100, -1], &Wx::wxSL_HORIZONTAL | &Wx::wxSL_BOTTOM );
    $self->{'offset'}->SetToolTip('additional offset pendulum starts with');

    Wx::Event::EVT_CHECKBOX( $self, $self->{'on'}, sub { $self->update_enable() });

    my $sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $sizer->Add( $self->{'on'},      0, &Wx::wxALIGN_LEFT|&Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW|&Wx::wxLEFT, 0);
    $sizer->Add( $self->{'f'},       0, &Wx::wxALIGN_LEFT| &Wx::wxGROW, 0);
    $sizer->Add( $self->{'dir'},     0, &Wx::wxALIGN_LEFT|&Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW|&Wx::wxLEFT,  0);
    $sizer->Add( $self->{'2_off'},   0, &Wx::wxALIGN_LEFT|&Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW|&Wx::wxLEFT, 10);
    $sizer->Add( $self->{'4_off'},   0, &Wx::wxALIGN_LEFT|&Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW|&Wx::wxLEFT, 10);
    $sizer->Add( $self->{'offset'},  0, &Wx::wxALIGN_LEFT|&Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW|&Wx::wxLEFT, 10);
    $sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);
    $self->SetSizer($sizer);

    $self->init();
    $self;
}

sub init {
    my ( $self ) = @_;
    $self->set_data ({ f => 1, on => $self->{'initially_on'}, dir => 0, offset => 0} );
}

sub get_data {
    my ( $self ) = @_;
    {
        f => $self->{'f'}->GetValue,
        on => $self->{ 'on' }->IsChecked,
        dir => $self->{ 'dir' }->IsChecked,
        offset => (0.5 * $self->{'2_off'}->IsChecked) 
                + (0.25 * $self->{'4_off'}->IsChecked) 
                + ($self->{'offset'}->GetValue / 400),
    }
}

sub set_data {
    my ( $self, $data ) = @_;
    return unless ref $data eq 'HASH';
    $self->{ 'data'} = $data;
    $self->{ 'f' }->SetValue( $data->{'f'} );
    $self->{ 'on' }->SetValue( $data->{'on'} );
    $self->{ 'dir' }->SetValue( $data->{'dir'} );
    $self->{ '2_off' }->SetValue( $data->{'offset'} >= 0.5 );
    $data->{ 'offset' } -= 0.5 if $data->{'offset'} >= 0.5;
    $self->{ '4_off' }->SetValue( $data->{'offset'} >= 0.25 );
    $data->{ 'offset' } -= 0.25 if $data->{'offset'} >= 0.25;
    $self->{ 'offset' }->SetValue( $data->{'offset'} );
    $self->update_enable;
}

sub update_enable {
    my ($self) = @_;
    my $val = $self->{ 'on' }->IsChecked;
    $self->{$_}->Enable( $val ) for 'f', 'dir', '2_off', '4_off', 'offset';
}


1;
