
#

package App::GUI::Harmonograph::Frame::Part::PenLine;
use v5.12;
use warnings;
use Wx;
use base qw/Wx::Panel/;
use App::GUI::Harmonograph::Widget::SliderCombo;

sub new {
    my ( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent, -1 );
    $self->{'connect'} = Wx::CheckBox->new( $self, -1, '  Line');
    $self->{'length'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 80, 'Length','length of drawing in full circles', 1,  150,  10);
    $self->{'density'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 80, 'Density','pixel per circle',  1,  35,  10);
    $self->{'thickness'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 80, 'Thickness','dot size or thickness of drawn line in pixel',  0,  12,  0);
    $self->{'connect'}->SetToolTip('draw just dots (off) or connect them with lines (on)');
    Wx::Event::EVT_CHECKBOX( $self, $self->{'connect'}, sub {  $self->{'callback'}->() });

    my $widget_attr = &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxGROW | &Wx::wxLEFT;
    my $row1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $row1->AddSpacer(  25 );
    $row1->Add( $self->{'connect'}, 0, $widget_attr, 0);
    $row1->AddSpacer( 217 );
    $row1->Add( $self->{'length'},  0, $widget_attr, 0);
    $row1->Add( 0, 0, &Wx::wxEXPAND);

    my $row2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $row2->AddSpacer(  15 );
    $row2->Add( $self->{'density'}, 0, $widget_attr, 0);
    # $row2->Add( Wx::StaticText->new($self, -1, 'Thickness'), 0, &Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW|&Wx::wxALL, 10);
    $row2->AddSpacer( 22 );
    $row2->Add( $self->{'thickness'},  0, $widget_attr, 0);
    # $row2->Add( Wx::StaticText->new($self, -1, 'Px'), 0, &Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW|&Wx::wxALL, 10);
    $row2->Add( 0, 0, &Wx::wxEXPAND);

    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->Add( $row1, 0, &Wx::wxEXPAND );
    $sizer->AddSpacer(15);
    $sizer->Add( $row2, 0, &Wx::wxEXPAND );
    $sizer->AddSpacer(5);

    $self->SetSizer($sizer);
    $self->init();
    $self;
}

sub init { $_[0]->set_settings ( { length => 30, density => 15, thickness => 0, connect => 1 } ) }
sub get_settings {
    my ( $self ) = @_;
    {
        'length'    => $self->{ 'length' }->GetValue,
        'density'   => $self->{ 'density' }->GetValue,
        'thickness' => $self->{ 'thickness' }->GetValue,
        'connect'   => $self->{ 'connect' }->GetValue ? 1 : 0,
    }
}

sub set_settings {
    my ( $self, $data ) = @_;
    return unless ref $data eq 'HASH';
    $self->{$_}->SetValue( $data->{$_} ) for qw/length density thickness connect/,
}


sub SetCallBack {
    my ( $self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'callback'} = $code;
    $self->{ $_ }->SetCallBack( $code ) for qw /density thickness/;
}

1;
