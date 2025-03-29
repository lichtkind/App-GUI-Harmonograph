
# tab with visual settings, line dots and color flow (change)

package App::GUI::Harmonograph::Frame::Panel::Visual;
use v5.12;
use warnings;
use Wx;
use base qw/Wx::Panel/;
use App::GUI::Harmonograph::Widget::SliderCombo;

my $default = {
        connect_dots => 1, line_thickness => 0, dots_per_second => 3,
};


sub new {
    my ($class, $parent) = @_;
    my $self = $class->SUPER::new( $parent, -1 );
    $self->{'callback'} = sub {};

    $self->{'widget'}{'connect_dots'} = Wx::CheckBox->new( $self, -1, '  Line');
    $self->{'widget'}{'connect_dots'}->SetToolTip('draw just dots (off) or connect them with lines (on)');

    $self->{'widget'}{'line_thickness'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 80, 'Thickness','dot size or thickness of drawn line in pixel',  0,  14,  0);


    $self->{'widget'}{'dots_per_second'}  = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 80, 'Density','how many dots is drawn in a second?',  1,  70,  10);
    $self->{'widget'}{'duration_min'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 80, 'minutes','', 1,  100,  10);
    $self->{'widget'}{'duration_s'}   = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 80, 'seconds','', 1,  60,  10);
    $self->{'widget'}{'duration_cs'}  = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 80, 'fraction','', 1,  100,  10);
    $self->{'widget'}{'type'}    = Wx::ComboBox->new( $self, -1, 'linear', [-1,-1], [115, -1], [qw/no linear alternate circular/], &Wx::wxTE_READONLY );
    $self->{'widget'}{'type'}->SetToolTip("type of color flow: - linear - from start to end color \n  - alter(nate) - linearly between start and end color \n   - cicular - around the rainbow from start color visiting end color");
    $self->{'widget'}{'dynlabel'} = Wx::StaticText->new( $self, -1, 'Dynamics');
    $self->{'widget'}{'dynamic'}  = Wx::ComboBox->new( $self, -1, 1, [-1,-1],[75, -1], [1,2,3,4,5,6,7,8, 9, 10, 11, 12, 13], &Wx::wxTE_READONLY);
    $self->{'widget'}{'dynamic'}->SetToolTip('dynamics of linear and alternating color change (1 = equal distanced colors change,\n larger = starting with slow color change becoming faster - or vice versa when dir activated)');
    $self->{'widget'}{'stepsize'}  = App::GUI::Harmonograph::Widget::SliderCombo->new( $self,  94, 'Step Size','after how many circles does color change', 1, 100, 1);
    $self->{'widget'}{'period'}    = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 100, 'Period','amount of steps from start to end color', 2, 50, 10);
    $self->{'widget'}{'direction'} = Wx::CheckBox->new( $self, -1, ' Dir.');
    $self->{'widget'}{'direction'}->SetToolTip('if on color change starts fast getting slower, if odd starting slow ...');




    my $std_attr = &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL | &Wx::wxALIGN_CENTER_VERTICAL;
    my $next_attr = &Wx::wxALIGN_LEFT | $std_attr;
    my $below_attr = &Wx::wxTOP | $std_attr;
    my @separator_args = ($self, -1, [-1,-1], [ 135, 2]);
    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->AddSpacer( 5);
    $sizer->Add( $self->{'part'}{'pen_settings'},         0, $below_attr, 10);
    $sizer->Add( Wx::StaticLine->new( @separator_args ),  0, $below_attr, 10);
    $sizer->Add( $self->{'part'}{'color_change'},         0, $below_attr, 15);
    $sizer->Add( Wx::StaticLine->new( @separator_args ),  0, $below_attr, 10);
    $sizer->AddSpacer(10);
    $sizer->Add( 0, 1, $std_attr );
    $self->SetSizer( $sizer );
    $self;
}

sub init         { $_[0]->set_settings($default) }
sub set_settings {
    my ( $self, $settings ) = @_;
    return unless ref $settings eq 'HASH' and exists $settings->{'connect_dots'};
    for my $key (keys %$default){
        $self->{'widget'}{ $key }->SetValue( $settings->{ $key } // $default->{ $key } );
    }
    1;
}
sub get_settings {
    my ( $self ) = @_;
    return { map { $_, $self->{'widget'}{$_}->GetValue } keys %$default };
}

sub SetCallBack {
    my ( $self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'callback'} = $code;
}

1;
