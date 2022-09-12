use v5.12;
use warnings;
use Wx;

package App::GUI::Harmonograph::Dialog::Function;
use base qw/Wx::Dialog/;

sub new {
    my ( $class, $parent) = @_;
    my $self = $class->SUPER::new( $parent, -1, 'How does a Harmonograph work?' );
    my @lblb_pro = ( [-1,-1], [-1,-1], &Wx::wxALIGN_CENTRE_HORIZONTAL );
    my $layout = Wx::StaticText->new( $self, -1, 'The general layout of the program has three parts \n d' , @lblb_pro);

    $self->{'close'} = Wx::Button->new( $self, -1, '&Close', [10,10], [-1, -1] );
    Wx::Event::EVT_BUTTON( $self, $self->{'close'},  sub { $self->EndModal(1) });

    my $sizer = Wx::BoxSizer->new( &Wx::wxVERTICAL );
    my $t_attrs = &Wx::wxGROW | &Wx::wxALL | &Wx::wxALIGN_CENTRE_HORIZONTAL;
    $sizer->AddSpacer( 5 );
    $sizer->Add( $layout,          0, $t_attrs, 10 );
    $sizer->Add( 0,                1, &Wx::wxEXPAND | &Wx::wxGROW);
    $sizer->Add( $self->{'close'}, 0, &Wx::wxGROW | &Wx::wxALL, 25 );
    $self->SetSizer( $sizer );
    $self->SetAutoLayout( 1 );
    $self->SetSize( 550, 320 );
    return $self;
}

1;
