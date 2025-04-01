
# tab with visual settings, line dots and color flow (change)

package App::GUI::Harmonograph::Frame::Tab::Visual;
use v5.12;
use warnings;
use Wx;
use base qw/Wx::Panel/;
use App::GUI::Harmonograph::Widget::SliderCombo;

my $default_settings = {
        connect_dots => 1, line_thickness => 0, duration=> 60, dot_density => 60,
};
my @state_keys = keys %$default_settings;
my @widget_keys;
my @state_widgets = qw/connect_dots line_thickness/;


sub new {
    my ($class, $parent) = @_;
    my $self = $class->SUPER::new( $parent, -1 );
    $self->{'callback'} = sub {};

    $self->{'label'}{'line'}  = Wx::StaticText->new($self, -1, 'Line Drawn' );
    $self->{'label'}{'time'}  = Wx::StaticText->new($self, -1, 'Drawing Duration (Line Length)' );
    $self->{'label'}{'dense'} = Wx::StaticText->new($self, -1, 'Dot Density' );
    $self->{'label'}{'flow'}  = Wx::StaticText->new($self, -1, 'Color Change' );
    $self->{'label'}{'flow_type'} = Wx::StaticText->new( $self, -1, 'Change Type:');

    $self->{'widget'}{'connect_dots'} = Wx::CheckBox->new( $self, -1, '  Connect');
    #$self->{'widget'}{'draw'} = Wx::RadioBox->new( $self, -1, 'Draw', [-1, -1], [-1, -1], ['Dots', 'Line']);
    $self->{'widget'}{'connect_dots'}->SetToolTip('draw just dots (off) or connect them with lines (on)');
    $self->{'widget'}{'line_thickness'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 160, 'Thickness','dot size or thickness of drawn line in pixel',  0,  25,  0);
    $self->{'widget'}{'duration_min'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 85, 'Minutes','', 0,  100,  10);
    $self->{'widget'}{'duration_s'}   = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 90, 'Seconds','', 0,  59,  10);
    # $self->{'widget'}{'duration_cs'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 80, 'Fraction','', 1,  100,  10);
    $self->{'widget'}{'100dots_per_second'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 110, 'Coarse','how many dots is drawn in a second in batches of 50 ?',  0,  90,  10);
    $self->{'widget'}{'dots_per_second'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 100, 'Fine','how many dots is drawn in a second ?',  0,  99,  10);

    $self->{'widget'}{'type'}    = Wx::ComboBox->new( $self, -1, 'linear', [-1,-1], [115, -1], [qw/no linear alternate circular/], &Wx::wxTE_READONLY );
    $self->{'widget'}{'type'}->SetToolTip("type of color flow: - linear - from start to end color \n  - alter(nate) - linearly between start and end color \n   - cicular - around the rainbow from start color visiting end color");
    $self->{'widget'}{'dynamic'}  = Wx::ComboBox->new( $self, -1, 1, [-1,-1],[75, -1], [1,2,3,4,5,6,7,8, 9, 10, 11, 12, 13], &Wx::wxTE_READONLY);
    $self->{'widget'}{'dynamic'}->SetToolTip('dynamics of linear and alternating color change (1 = equal distanced colors change,\n larger = starting with slow color change becoming faster - or vice versa when dir activated)');
    $self->{'widget'}{'stepsize'}  = App::GUI::Harmonograph::Widget::SliderCombo->new( $self,  94, 'Step Size','after how many circles does color change', 1, 100, 1);
    $self->{'widget'}{'period'}    = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 100, 'Period','amount of steps from start to end color', 2, 50, 10);
    $self->{'widget'}{'direction'} = Wx::CheckBox->new( $self, -1, ' Dir.');
    $self->{'widget'}{'direction'}->SetToolTip('if on color change starts fast getting slower, if odd starting slow ...');
    @widget_keys = keys %{$self->{'widget'}};

    Wx::Event::EVT_CHECKBOX( $self, $self->{'widget'}{'connect_dots'}, sub {  $self->{'callback'}->() });
    $self->{'widget'}{ $_ }->SetCallBack( sub {  $self->{'callback'}->() } )
        for qw/line_thickness duration_min duration_s 100dots_per_second dots_per_second/;

    my $std_attr  = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxGROW;
    my $box_attr  = $std_attr | &Wx::wxTOP | &Wx::wxBOTTOM;
    my $all_attr = &Wx::wxALL | &Wx::wxALIGN_CENTER_HORIZONTAL | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxGROW;

    my $line_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $line_sizer->AddSpacer( 20 );
    $line_sizer->Add( $self->{'widget'}{'connect_dots'},  0, $box_attr, 5);
    $line_sizer->AddSpacer( 30 );
    $line_sizer->Add( $self->{'widget'}{'line_thickness'},  0, $box_attr, 5);
    $line_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $time_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $time_sizer->AddSpacer( 20 );
    $time_sizer->Add( $self->{'widget'}{'duration_min'},  0, $box_attr, 5);
    $time_sizer->AddSpacer( 20 );
    $time_sizer->Add( $self->{'widget'}{'duration_s'},  0, $box_attr, 5);
    $time_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $dense_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $dense_sizer->AddSpacer( 20 );
    $dense_sizer->Add( $self->{'widget'}{'100dots_per_second'},  0, $box_attr, 5);
    $dense_sizer->AddSpacer( 20 );
    $dense_sizer->Add( $self->{'widget'}{'dots_per_second'},  0, $box_attr, 5);
    $dense_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->AddSpacer( 10 );
    $sizer->Add( $self->{'label'}{'line'},        0, &Wx::wxALIGN_CENTER_HORIZONTAL,  0);
    $sizer->Add( $line_sizer,                     0, $std_attr|&Wx::wxTOP,           10);
    $sizer->Add( Wx::StaticLine->new($self, -1),  0, $box_attr,                      10);
    $sizer->Add( $self->{'label'}{'time'},        0, &Wx::wxALIGN_CENTER_HORIZONTAL,  0);
    $sizer->Add( $time_sizer,                     0, $std_attr|&Wx::wxTOP,           10);
    $sizer->Add( Wx::StaticLine->new($self, -1),  0, $box_attr,                      10);
    $sizer->Add( $self->{'label'}{'dense'},       0, &Wx::wxALIGN_CENTER_HORIZONTAL,  0);
    $sizer->Add( $dense_sizer,                    0, $std_attr|&Wx::wxTOP,           10);
    $sizer->Add( Wx::StaticLine->new($self, -1),  0, $box_attr,                      10);
    $sizer->Add( Wx::StaticLine->new($self, -1),  0, $box_attr,                      10);
    $sizer->Add( 0, 1, $std_attr );

    $self->SetSizer( $sizer );
    $self->init();
    $self;
}

sub init         { $_[0]->set_settings( $default_settings ) }
sub set_settings {
    my ( $self, $settings ) = @_;
    return unless ref $settings eq 'HASH' and exists $settings->{'connect_dots'};
    $settings->{ $_ } //= $default_settings->{ $_ } for @state_keys;
    $self->{'widget'}{ $_ }->SetValue( $settings->{ $_ } ) for @state_widgets;
    $self->{'widget'}{ 'duration_min' }->SetValue( int($settings->{ 'duration'} / 60), 'passive');
    $self->{'widget'}{ 'duration_s' }->SetValue(       $settings->{ 'duration'} % 60, 'passive');
    $self->{'widget'}{ '100dots_per_second'}->SetValue( int($settings->{ 'dot_density'} / 100), 'passive');
    $self->{'widget'}{ 'dots_per_second' }->SetValue(       $settings->{ 'dot_density'} % 100, 'passive');
    1;
}
sub get_settings {
    my ( $self ) = @_;
    my $settings = { map { $_ => $self->{'widget'}{$_}->GetValue } @state_widgets};
    $settings->{'duration'} = ($self->{'widget'}{ 'duration_min' }->GetValue * 60)
                             + $self->{'widget'}{ 'duration_s' }->GetValue;
    $settings->{'dot_density'} = ($self->{'widget'}{ '100dots_per_second' }->GetValue * 100)
                                + $self->{'widget'}{ 'dots_per_second' }->GetValue;
    $settings;
}

sub SetCallBack {
    my ( $self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'callback'} = $code;
}

1;
