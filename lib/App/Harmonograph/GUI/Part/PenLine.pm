use v5.12;
use warnings;
use Wx;

package App::Harmonograph::GUI::Part::PenLine;
use base qw/Wx::Panel/;
use App::Harmonograph::GUI::SliderCombo;

sub new {
    my ( $class, $parent ) = @_;
    #return unless defined $max;
    my $self = $class->SUPER::new( $parent, -1 );

    $self->{'length'} = App::Harmonograph::GUI::SliderCombo->new( $self, 80, 'Length','length of drawing in full circles',     1,  150,  10);
    $self->{'density'} = App::Harmonograph::GUI::SliderCombo->new( $self, 80, 'Dense','x 10 pixel per circle',  1,  400,  100);
    $self->{'thickness'}  = Wx::ComboBox->new( $self, -1, 1, [-1,-1],[65, -1], [1,2,3,4,5,6,7,8], 1);
    $self->{'thickness'}->SetToolTip('dot size (c of line) in pixel');

    my $sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $sizer->Add( $self->{'length'},  0, &Wx::wxALIGN_LEFT| &Wx::wxGROW | &Wx::wxRIGHT, 0);
    $sizer->Add( $self->{'density'}, 0, &Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW| &Wx::wxRIGHT, 5);
    $sizer->Add( Wx::StaticText->new($self, -1, 'Px'), 0, &Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW|&Wx::wxALL, 10);
    $sizer->Add( $self->{'thickness'}, 0, &Wx::wxALIGN_LEFT|&Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW, 0);
    $sizer->Add( 0, 0, &Wx::wxEXPAND);

    $self->SetSizer($sizer);
    $self->init();
    $self;
}

sub init {
    my ( $self ) = @_;
    $self->set_data ( { length => 10, density => 100, thickness => 1 } );
}

sub get_data {
    my ( $self ) = @_;
    {
        length    => $self->{'length'}->GetValue,
        density   => $self->{'density'}->GetValue,
        thickness => $self->{'thickness'}->GetValue,
    }
}

sub set_data {
    my ( $self, $data ) = @_;
    return unless ref $data eq 'HASH';
    $self->{$_}->SetValue( $data->{$_} ) for qw/length density thickness/, 
}

1;
