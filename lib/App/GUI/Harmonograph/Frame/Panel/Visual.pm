
# tab with visual settings

package App::GUI::Harmonograph::Frame::Panel::Visual;
use v5.12;
use warnings;
use Wx;
use base qw/Wx::Panel/;
use App::GUI::Harmonograph::Frame::Part::ColorFlow;
use App::GUI::Harmonograph::Frame::Part::PenLine;



sub new {
    my ( $class, $parent ) = @_;

    my $self = $class->SUPER::new( $parent, -1 );

    $self->{'part'}{'pen_settings'}       = App::GUI::Harmonograph::Frame::Part::PenLine->new( $self );
    $self->{'part'}{'color_change'}       = App::GUI::Harmonograph::Frame::Part::ColorFlow->new( $self, $self->{'part'}{'end_color'} );

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

sub init  {
    $_[0]->{'part'}{ $_ }->init for qw/pen_settings color_change/
}
sub get_settings {
    my ( $self ) = @_;
    {
        line        => $self->{'part'}{'pen_settings'}->get_settings,
        color_flow  => $self->{'part'}{'color_change'}->get_settings,
    }
}

sub set_settings {
    my ( $self, $settings ) = @_;
    return unless ref $settings eq 'HASH';
    $self->{'part'}{'pen_settings'}->set_settings( $settings->{'line'} );
    $self->{'part'}{'color_change'}->set_settings( $settings->{'color_flow'} );
}

sub SetCallBack {
    my ( $self, $code) = @_;
    return unless ref $code eq 'CODE';
    $_[0]->{'part'}{ $_ }->SetCallBack( $code ) for qw/pen_settings color_change/
}


1;
