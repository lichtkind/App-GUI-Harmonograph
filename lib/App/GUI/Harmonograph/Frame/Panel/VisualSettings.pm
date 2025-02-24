
# tab with visual settings

package App::GUI::Harmonograph::Frame::Panel::VisualSettings;
use v5.12;
use warnings;
use Wx;
use base qw/Wx::Panel/;
use App::GUI::Harmonograph::Frame::Part::ColorBrowser;
use App::GUI::Harmonograph::Frame::Part::ColorFlow;
use App::GUI::Harmonograph::Frame::Part::PenLine;
use App::GUI::Harmonograph::Frame::Part::ColorPicker;


sub new {
    my ( $class, $parent, $colors ) = @_;
    return unless ref $colors eq 'HASH';

    my $self = $class->SUPER::new( $parent, -1 );
    App::GUI::Harmonograph::Frame::Part::ColorPicker::set_colors( $colors );

    $self->{'part'}{'start_color'}        = App::GUI::Harmonograph::Frame::Part::ColorBrowser->new( $self, 'start', { red => 20, green => 20, blue => 110 } );
    $self->{'part'}{'end_color'}          = App::GUI::Harmonograph::Frame::Part::ColorBrowser->new( $self, 'end',  { red => 110, green => 20, blue => 20 } );
    $self->{'part'}{'start_color_picker'} = App::GUI::Harmonograph::Frame::Part::ColorPicker->new( $self, $self->{'part'}{'start_color'}, 'Start Picker:', 150, 0);
    $self->{'part'}{'end_color_picker'}   = App::GUI::Harmonograph::Frame::Part::ColorPicker->new( $self, $self->{'part'}{'end_color'}, 'End Picker:', 150, 5);
    $self->{'part'}{'pen_settings'}       = App::GUI::Harmonograph::Frame::Part::PenLine->new( $self );
    $self->{'part'}{'color_change'}       = App::GUI::Harmonograph::Frame::Part::ColorFlow->new( $self, $self->{'part'}{'end_color'} );

    my $std_attr = &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL | &Wx::wxALIGN_CENTER_VERTICAL;
    my $next_attr = &Wx::wxALIGN_LEFT | $std_attr;
    my $below_attr = &Wx::wxTOP | $std_attr;
    my @separator_args = ($self, -1, [-1,-1], [ 135, 2]);
    my $start_label = Wx::StaticText->new( $self, -1, 'Start Color', [-1,-1], [-1,-1], &Wx::wxALIGN_CENTRE_HORIZONTAL);
    my $end_label   = Wx::StaticText->new( $self, -1,   'End Color', [-1,-1], [-1,-1], &Wx::wxALIGN_CENTRE_HORIZONTAL);
    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->AddSpacer( 5);
    $sizer->Add( $self->{'part'}{'pen_settings'},         0, $below_attr, 10);
    $sizer->Add( Wx::StaticLine->new( @separator_args ),  0, $below_attr, 10);
    $sizer->Add( $self->{'part'}{'color_change'},         0, $below_attr, 15);
    $sizer->Add( Wx::StaticLine->new( @separator_args ),  0, $below_attr, 10);
    $sizer->AddSpacer(10);
    $sizer->Add( $start_label,                            0, $std_attr | &Wx::wxALL, 5);
    $sizer->Add( $self->{'part'}{'start_color'},          0, $below_attr,  0);
    $sizer->AddSpacer( 5);
    $sizer->Add( $end_label,                              0, $std_attr | &Wx::wxALL, 5);
    $sizer->Add( $self->{'part'}{'end_color'},            0, $below_attr,  0);
    $sizer->Add( Wx::StaticLine->new( @separator_args ),  0, $below_attr, 10);
    $sizer->AddSpacer( 15);
    $sizer->Add( $self->{'part'}{'start_color_picker'},   0, $below_attr,  5);
    $sizer->AddSpacer( 10);
    $sizer->Add( $self->{'part'}{'end_color_picker'},     0, $below_attr,  5);
    $sizer->Add( 0, 1, $std_attr );
    $self->SetSizer( $sizer );
    $self;
}

sub init  {
    $_[0]->{'part'}{ $_ }->init for qw/pen_settings color_change start_color end_color/
}
sub get_settings {
    my ( $self ) = @_;
    {
        line        => $self->{'part'}{'pen_settings'}->get_settings,
        color_flow  => $self->{'part'}{'color_change'}->get_settings,
        start_color => $self->{'part'}{'start_color'}->get_settings,
        end_color   => $self->{'part'}{'end_color'}->get_settings,
    }
}

sub set_settings {
    my ( $self, $settings ) = @_;
    return unless ref $settings eq 'HASH';
    $self->{'part'}{'pen_settings'}->set_settings( $settings->{'line'} );
    $self->{'part'}{'color_change'}->set_settings( $settings->{'color_flow'} );
    $self->{'part'}{'start_color'}->set_settings( $settings->{'start_color'} );
    $self->{'part'}{'end_color'}->set_settings( $settings->{'end_color'} );
}

sub SetCallBack {
    my ( $self, $code) = @_;
    return unless ref $code eq 'CODE';
    $_[0]->{'part'}{ $_ }->SetCallBack( $code ) for qw/pen_settings color_change start_color end_color/
}

sub get_start_color { $_[0]->{'part'}{'start_color'}->get_settings }
sub get_colors { App::GUI::Harmonograph::Frame::Part::ColorPicker::get_colors() }

1;
