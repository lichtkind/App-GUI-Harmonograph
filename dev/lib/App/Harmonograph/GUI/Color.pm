use v5.18;
use warnings;
use Wx;

package App::Harmonograph::GUI::Color;
my $VERSION = 0.1;
use base qw/Wx::Panel/;
use App::Harmonograph::GUI::SliderCombo;
use App::Harmonograph::Color;

sub new {
    my ( $class, $parent, $type, $init  ) = @_;
    return unless ref $init eq 'HASH' and exists $init->{'r'}and exists $init->{'g'}and exists $init->{'b'};
    
    my $self = $class->SUPER::new( $parent, -1, [-1,-1], [-1, -1] );

    $self->{'init'} = $init;
    
    $self->{'r'} =  App::Harmonograph::GUI::SliderCombo->new( $self, 100, ' R  ', "red part of $type color",    0, 255,  0);
    $self->{'g'} =  App::Harmonograph::GUI::SliderCombo->new( $self, 100, ' G  ', "green part of $type color",  0, 255,  0);
    $self->{'b'} =  App::Harmonograph::GUI::SliderCombo->new( $self, 100, ' B  ', "blue part of $type color",   0, 255,  0);
    $self->{'h'} =  App::Harmonograph::GUI::SliderCombo->new( $self, 100, ' H  ', "hue of $type color",         0, 359,  0);
    $self->{'s'} =  App::Harmonograph::GUI::SliderCombo->new( $self, 100, ' S  ', "saturation of $type color",  0, 100,  0);
    $self->{'l'} =  App::Harmonograph::GUI::SliderCombo->new( $self, 100, ' L  ', "lightness of $type color",   0, 100,  0);
    $self->{'display'} = Wx::Panel->new( $self, -1, [-1,-1], [25, 10] );
    $self->{'display'}->SetToolTip("$type color monitor");
    
    Wx::Event::EVT_PAINT( $self->{'display'}, sub {
        my( $dpanel, $event ) = @_;
        return unless ref $self->{'b'};
        my $dc = Wx::PaintDC->new( $dpanel );
        my $bgb = Wx::Brush->new(
                      Wx::Colour->new( $self->{'r'}->GetValue, 
                                       $self->{'g'}->GetValue, 
                                       $self->{'b'}->GetValue), &Wx::wxBRUSHSTYLE_SOLID );
        $dc->SetBackground( $bgb );
        $dc->Clear();
    } );


    my $rgb2hsl = sub {
        my @hsl = App::Harmonograph::Color::Value::hsl_from_rgb( 
            $self->{'r'}->GetValue, $self->{'g'}->GetValue, $self->{'b'}->GetValue);
        $self->{'h'}->SetValue( $hsl[0], 1 );
        $self->{'s'}->SetValue( $hsl[1], 1 );
        $self->{'l'}->SetValue( $hsl[2], 1 );
        $self->{'display'}->Refresh;
    };
    my $hsl2rgb = sub {
        my @rgb = App::Harmonograph::Color::Value::rgb_from_hsl( 
            $self->{'h'}->GetValue,  $self->{'s'}->GetValue, $self->{'l'}->GetValue);
        $self->{'r'}->SetValue( $rgb[0], 1 );
        $self->{'g'}->SetValue( $rgb[1], 1 );
        $self->{'b'}->SetValue( $rgb[2], 1 );
        $self->{'display'}->Refresh;
    };
    $self->{'r'}->SetCallBack( $rgb2hsl );
    $self->{'g'}->SetCallBack( $rgb2hsl );
    $self->{'b'}->SetCallBack( $rgb2hsl );
    $self->{'h'}->SetCallBack( $hsl2rgb );
    $self->{'s'}->SetCallBack( $hsl2rgb );
    $self->{'l'}->SetCallBack( $hsl2rgb );


    my $rh_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $rh_sizer->Add( $self->{'r'},  0, &Wx::wxGROW|&Wx::wxLEFT, 10);
    $rh_sizer->Add( $self->{'h'},  0, &Wx::wxGROW|&Wx::wxLEFT, 50);
    $rh_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $gs_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $gs_sizer->Add( $self->{'g'},       0, &Wx::wxGROW|&Wx::wxLEFT, 10);
    $gs_sizer->Add( $self->{'display'}, 0, &Wx::wxGROW|&Wx::wxLEFT|&Wx::wxALIGN_CENTER_VERTICAL, 15);
    $gs_sizer->Add( $self->{'s'},       0, &Wx::wxGROW|&Wx::wxLEFT, 10);
    $gs_sizer->Add( 0,                  0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $bl_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $bl_sizer->Add( $self->{'b'},  0, &Wx::wxGROW|&Wx::wxLEFT, 10);
    $bl_sizer->Add( $self->{'l'},  0, &Wx::wxGROW|&Wx::wxLEFT, 50);
    $bl_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);


    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->Add( $rh_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW, 0);
    $sizer->Add( $gs_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW, 0);
    $sizer->Add( $bl_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW, 0);

    $self->SetSizer($sizer);
    $self->init();
    $self->{'display'}->Refresh;
    $self;
}

sub init { $_[0]->set_data( $_[0]->{'init'} ) }

sub get_data {
    my ( $self ) = @_;
    {
        r => $self->{'r'}->GetValue,
        g => $self->{'g'}->GetValue,
        b => $self->{'b'}->GetValue,
    }
}

sub set_data {
    my ( $self, $data ) = @_;
    return unless ref $data eq 'HASH';
    $self->{'r'}->SetValue( $data->{'r'}, 1);
    $self->{'g'}->SetValue( $data->{'g'}, 1);
    $self->{'b'}->SetValue( $data->{'b'} );
}


1;
