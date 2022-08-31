use v5.18;
use warnings;
use Wx;

package App::Harmonograph::GUI::Part::ColorFlow;
my $VERSION = 0.1;
use base qw/Wx::Panel/;
use App::Harmonograph::GUI::SliderCombo;

sub new {
    my ( $class, $parent ) = @_;
    #return unless defined $max;
    my $self = $class->SUPER::new( $parent, -1 );

    my $flow_label = Wx::StaticText->new( $self, -1, 'Color Flow');
    my $dyn_label = Wx::StaticText->new( $self, -1, 'Dynamics');

    $self->{'parent'} = $parent;
    $self->{'type'}  = Wx::ComboBox->new( $self, -1, 'linear', [-1,-1], [105, -1], [qw/no linear circular/] );
    $self->{'type'}->SetToolTip('choose between no color flow, linear color flow between start and end color or circular (start to end, back and again)');
    $self->{'dynamic'} = Wx::ComboBox->new( $self, -1, 1, [-1,-1],[65, -1], [1,2,3,4,5,6,7,8, 9, 10], 1);
    $self->{'dynamic'}->SetToolTip('dynamics of color change (1 = linear change, larger = starting slower becoming faster)');
    $self->{'stepsize'} = App::Harmonograph::GUI::SliderCombo->new( $self, 80, 'Step Size','after how many circles does color change', 1, 100, 1);
    $self->{'period'} = App::Harmonograph::GUI::SliderCombo->new( $self, 100, 'Period','amount of circles need to go from start to end color', 2, 100, 10);

    Wx::Event::EVT_COMBOBOX( $self, $self->{'type'},  \&update_enable);


    my $cf_attr = &Wx::wxLEFT|&Wx::wxALIGN_LEFT|&Wx::wxALIGN_CENTER_VERTICAL;
    
    my $row_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $row_sizer->Add( $flow_label,           0, $cf_attr,  10);
    $row_sizer->Add( $self->{'type'},       0, $cf_attr,  13);
    $row_sizer->Add( $dyn_label,            0, $cf_attr,  75);
    $row_sizer->Add( $self->{'dynamic'},    0, $cf_attr,  12);
    $row_sizer->Add( 0, 0, &Wx::wxEXPAND);

    my $row2_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $row2_sizer->Add( $self->{'stepsize'}, 0, $cf_attr,  0);
    $row2_sizer->Add( $self->{'period'},   0, $cf_attr,  0);
    $row2_sizer->Add( 0, 0, &Wx::wxEXPAND);

    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->Add( $row_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW, 0);
    $sizer->Add( $row2_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxTOP, 10);

    $self->SetSizer($sizer);
    $self->init();
    $self;
}

sub init {
    my ( $self ) = @_;
    $self->set_data ({ type => 'no', dynamic => 1, period => 10, stepsize => 1 } );
}

sub get_data {
    my ( $self ) = @_;
    {
        type     => $self->{'type'}->GetValue,
        dynamic  => $self->{'dynamic'}->GetValue,
        stepsize => $self->{'stepsize'}->GetValue,
        period   => $self->{'period'}->GetValue,
    }
}

sub set_data {
    my ( $self, $data ) = @_;
    return unless ref $data eq 'HASH';
    $self->{$_}->SetValue( $data->{$_} ) for qw/type stepsize period dynamic/, 
    $self->update_enable( );
}

sub update_enable {
    my ($self) = @_;
    my $type = $self->{'type'}->GetValue();
    $self->{'stepsize'}->Enable( $type ne 'no' );
    $self->{'period'}->Enable( $type eq 'circular' );
    $self->{'parent'}{'color'}{'end'}->Enable( $type ne 'no' );
}


1;
