use v5.12;
use warnings;
use Wx;

package App::GUI::Harmonograph::Dialog::About;
use base qw/Wx::Dialog/;
use Graphics::Toolkit::Color;

sub new {
    my ( $class, $parent) = @_;
    my $self = $class->SUPER::new( $parent, -1, 'About Wx::GUI::Harmonograph' );

    my @center = ( [-1,-1], [-1,-1], &Wx::wxALIGN_CENTRE_HORIZONTAL );
    my $version = Wx::StaticText->new( $self, -1, $App::GUI::Harmonograph::NAME . '    version '.$App::GUI::Harmonograph::VERSION , @center);
    my $author  = Wx::StaticText->new( $self, -1, ' by Herbert Breunung ', @center);
    my $license = Wx::StaticText->new( $self, -1, ' licensed under the GPL 3 ', @center);
    my $perl    = Wx::StaticText->new( $self, -1, 'using Perl '.$^V, @center);
    my $wx      = Wx::StaticText->new( $self, -1, 'WxPerl '. $Wx::VERSION . '  ( '. &Wx::wxVERSION_STRING. ' )', @center);
    my $gtc     = Wx::StaticText->new( $self, -1, 'Graphics::Toolkit::Color  '.$Graphics::Toolkit::Color::VERSION, @center);
    my $hd      = Wx::StaticText->new( $self, -1, 'File::HomeDir  '.$File::HomeDir::VERSION, @center);
    my $url_lbl = Wx::StaticText->new( $self, -1, 'latest version on CPAN:   ', @center);
    my $url     = Wx::HyperlinkCtrl->new( $self, -1, 'metacpan.org/dist/App::GUI::Harmonograph', 'https://metacpan.org/dist/App::GUI::Harmonograph' );

    $self->{'close'} = Wx::Button->new( $self, -1, '&Close', [10,10], [-1, -1] );
    Wx::Event::EVT_BUTTON( $self, $self->{'close'},  sub { $self->EndModal(1) });

    my $ll_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $ll_sizer->AddSpacer( 5 );
    $ll_sizer->Add( $url_lbl,    0, &Wx::wxGROW | &Wx::wxALL, 12 );
    $ll_sizer->Add( $url,        0, &Wx::wxGROW | &Wx::wxALIGN_RIGHT| &Wx::wxRIGHT, 10);

    my $sizer = Wx::BoxSizer->new( &Wx::wxVERTICAL );
    my $t_attrs = &Wx::wxGROW | &Wx::wxALL | &Wx::wxALIGN_CENTRE_HORIZONTAL;
    $sizer->AddSpacer( 10 );
    $sizer->Add( $version,         0, $t_attrs, 15 );
    $sizer->Add( $author,          0, $t_attrs,  5 );
    $sizer->Add( $license,         0, $t_attrs,  5 );
    $sizer->AddSpacer( 10 );
    $sizer->Add( $perl,            0, $t_attrs,  5 );
    $sizer->Add( $wx,              0, $t_attrs,  5 );
    $sizer->Add( $gtc,             0, $t_attrs,  5 );
    $sizer->Add( $hd,              0, $t_attrs,  5 );
    $sizer->Add( $ll_sizer,        0, $t_attrs, 10 );
    $sizer->Add( 0,                1, &Wx::wxEXPAND | &Wx::wxGROW);
    $sizer->Add( $self->{'close'}, 0, &Wx::wxGROW | &Wx::wxALL, 25 );
    $self->SetSizer( $sizer );
    $self->SetAutoLayout( 1 );
    $self->SetSize( 550, 385 );
    $self->{'close'}->SetFocus;
    return $self;
}

1;
