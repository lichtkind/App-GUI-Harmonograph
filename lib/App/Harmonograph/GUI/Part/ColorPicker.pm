use v5.12;
use warnings;
use Wx;

package App::Harmonograph::GUI::Part::ColorPicker;
use base qw/Wx::Panel/;
use App::Harmonograph::GUI::ColorDisplay;
use App::Harmonograph::Color;

sub new {
    my ( $class, $parent, $label, $data, $length, $space ) = @_;
    #return unless defined $max;
    $length //= 170;
    $space //= 0;
    my $self = $class->SUPER::new( $parent, -1 );

    my $colors = $parent->{'config'}->get_value('color');
    my $color_names = [ sort keys %$colors ];
    my $fcolor = $colors->{ $color_names->[0] };

    my $btnw = 50; my $btnh = 40;# button width and height
    $self->{'label'}  = Wx::StaticText->new($self, -1, $label.':' );
    $self->{'select'} = Wx::ComboBox->new( $self, -1, $color_names->[0], [-1,-1], [$length, -1], $color_names);
    $self->{'<'}    = Wx::Button->new( $self, -1, '<',       [-1,-1], [ 30, 20] );
    $self->{'>'}    = Wx::Button->new( $self, -1, '>',       [-1,-1], [ 30, 20] );
    $self->{'load'} = Wx::Button->new( $self, -1, 'Load',    [-1,-1], [$btnw, $btnh] );
    $self->{'del'}  = Wx::Button->new( $self, -1, 'Del',     [-1,-1], [$btnw, $btnh] );
    $self->{'save'} = Wx::Button->new( $self, -1, 'Save',    [-1,-1], [$btnw, $btnh] );
    $self->{'display'} = App::Harmonograph::GUI::ColorDisplay->new
                           ( $self, 25, 10, {red=> $fcolor->[0], green=> $fcolor->[1], blue=> $fcolor->[2] });
    
    #$self->{'label'}->SetToolTip("use displayed color on the right side as $label");
    $self->{'select'}->SetToolTip("select color in list directly");
    $self->{'<'}->SetToolTip("go to previous color in list");
    $self->{'>'}->SetToolTip("go to next color in list");
    $self->{'load'}->SetToolTip("use displayed color on the right side as $label");
    $self->{'save'}->SetToolTip("copy current $label here (into color storage)");
    $self->{'del'}->SetToolTip("delete displayed color from storage)");
    $self->{'display'}->SetToolTip("color monitor");


    my $vset_attr = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_HORIZONTAL | &Wx::wxGROW | &Wx::wxTOP| &Wx::wxBOTTOM;
    my $all_attr  = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_HORIZONTAL | &Wx::wxGROW | &Wx::wxALL;
    my $sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $sizer->Add( $self->{'label'},              0, $all_attr,  20 );
    $sizer->AddSpacer( $space );
    $sizer->Add( $self->{'select'}, 0, $vset_attr, 10 );
    $sizer->Add( $self->{'<'},      0, $vset_attr, 10 );
    $sizer->Add( $self->{'>'},      0, $vset_attr, 10 );
    $sizer->AddSpacer( 20 );
    $sizer->Add( $self->{'display'},  0, $vset_attr, 15);
    $sizer->AddSpacer( 10 );
    $sizer->Add( $self->{'load'}, 0, $all_attr,  10 );
    $sizer->Add( $self->{'del'},  0, $all_attr,  10 );
    $sizer->Add( $self->{'save'}, 0, $all_attr,  10 );
    $sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);
    $self->SetSizer($sizer);

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

sub set_color {
    my ( $self, $data ) = @_;
    return unless ref $data eq 'HASH';
    $self->{$_}->SetValue( $data->{$_} ) for qw/length density thickness/, 
}

1;
