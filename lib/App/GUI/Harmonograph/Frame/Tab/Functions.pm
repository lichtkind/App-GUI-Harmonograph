
# panel behind modulation tab for changing base function of each pendulum

package App::GUI::Harmonograph::Frame::Tab::Functions;
use v5.12;
use utf8;
use warnings;
use Wx;
use base qw/Wx::Panel/;
use App::GUI::Harmonograph::Widget::SliderCombo;

my @function_names = (qw/sin cos tan cot sec csc sinh cosh tanh coth sech csch/);
my @variable_names = ('X time',  'Y time', 'W time', 'R time', 'E time', 'F time',
                      'X freq.', 'Y freq.', 'W freq.', 'R freq.', 'E freq.', 'F freq.',
                      'X radius','Y radius', 'W radius', 'R radius', 'E radius', 'F radius'); # variable names
my @operator_names = (qw/= + - * \//);
my @pendulum_names = (qw/x y wx wy r11 r12 r21 r22 e f/);

my $default = { x_function   => 'cos', x_variable   => 'X time',   x_operator   => '=',
                y_function   => 'sin', y_variable   => 'Y time',   y_operator   => '=',
                wx_function  => 'cos', wx_variable  => 'W time',   wx_operator  => '=',
                wy_function  => 'sin', wy_variable  => 'W time',   wy_operator  => '=',
                r11_function => 'cos', r11_variable => 'R time',   r11_operator => '=',
                r12_function => 'sin', r12_variable => 'R time',   r12_operator => '=',
                r21_function => 'sin', r21_variable => 'R time',   r21_operator => '=',
                r22_function => 'cos', r22_variable => 'R time',   r22_operator => '=',
                e_function   => 'cos', e_variable  => 'E time',    e_operator  => '=',
                f_function   => 'sin', f_variable  => 'F time',    f_operator  => '=',
};

sub new {
    my ( $class, $parent ) = @_;

    my $self = $class->SUPER::new( $parent, -1);

    my $label = { x => 'X', y => 'Y', w => 'W', r => 'R', e => 'E', f => 'F' };
    $self->{'lbl'}{$_} = Wx::StaticText->new(  $self, -1, $label->{$_}.' :' ) for keys %$label;

    $self->{$_.'_function'} = Wx::ComboBox->new( $self, -1, '', [-1,-1], [ 82, -1], [@function_names], &Wx::wxTE_READONLY) for @pendulum_names;
    $self->{$_.'_variable'} = Wx::ComboBox->new( $self, -1, '', [-1,-1], [105, -1], [@variable_names], &Wx::wxTE_READONLY) for @pendulum_names;
    $self->{$_.'_operator'} = Wx::ComboBox->new( $self, -1, '', [-1,-1], [ 65, -1], [@operator_names], &Wx::wxTE_READONLY) for @pendulum_names;

    $self->{'x_function'}->SetToolTip('function that computes pendulum X');
    $self->{'y_function'}->SetToolTip('function that computes pendulum Y');
    $self->{'wx_function'}->SetToolTip('function that computes pendulum W in x direction');
    $self->{'wy_function'}->SetToolTip('function that computes pendulum W in y direction');
    $self->{'r11_function'}->SetToolTip('left upper function in rotation matrix of pendulum R');
    $self->{'r12_function'}->SetToolTip('right upper function in rotation matrix of pendulum R');
    $self->{'r21_function'}->SetToolTip('left lower function in rotation matrix of pendulum R');
    $self->{'r22_function'}->SetToolTip('left lower function in rotation matrix of pendulum R');
    $self->{'e_function'}->SetToolTip('function that computes epicycle pendulum in x direction');
    $self->{'f_function'}->SetToolTip('function that computes epicycle pendulum in y direction');

    $self->{'x_variable'}->SetToolTip('variable on which the function of pendulum X is computed upon');
    $self->{'y_variable'}->SetToolTip('variable on which the function of pendulum Y is computed upon');
    $self->{'wx_variable'}->SetToolTip('variable on which the function for x-direction of pendulum W is computed upon');
    $self->{'wy_variable'}->SetToolTip('variable on which the function for y-direction of pendulum W is computed upon');
    $self->{'r11_variable'}->SetToolTip('left upper variable in rotation matrix of pendulum R');
    $self->{'r12_variable'}->SetToolTip('right upper variable in rotation matrix of pendulum R');
    $self->{'r21_variable'}->SetToolTip('left lower variable in rotation matrix of pendulum R');
    $self->{'r22_variable'}->SetToolTip('left lower variable in rotation matrix of pendulum R');
    $self->{'e_variable'}->SetToolTip('variable on which the epicycle pendulum in x direction is computed');
    $self->{'f_variable'}->SetToolTip('variable on which the epicycle pendulum in y direction is computed');

    $self->{'x_operator'}->SetToolTip('replace, add, subtract, multiply or divide with the original variable value');
    $self->{'y_operator'}->SetToolTip('replace, add, subtract, multiply or divide with the original variable value');
    $self->{'wx_operator'}->SetToolTip('replace, add, subtract, multiply or divide with the original variable value');
    $self->{'wy_operator'}->SetToolTip('replace, add, subtract, multiply or divide with the original variable value');
    $self->{'r11_operator'}->SetToolTip('replace, add, subtract, multiply or divide with the original variable value');
    $self->{'r12_operator'}->SetToolTip('replace, add, subtract, multiply or divide with the original variable value');
    $self->{'r21_operator'}->SetToolTip('replace, add, subtract, multiply or divide with the original variable value');
    $self->{'r22_operator'}->SetToolTip('replace, add, subtract, multiply or divide with the original variable value');
    $self->{'e_operator'}->SetToolTip('replace, add, subtract, multiply or divide with the original variable value');
    $self->{'f_operator'}->SetToolTip('replace, add, subtract, multiply or divide with the original variable value');

    $self->{'callback'} = sub {};
    Wx::Event::EVT_COMBOBOX( $self, $self->{$_.'_function'},   sub { $self->{'callback'}->() }) for @pendulum_names;
    Wx::Event::EVT_COMBOBOX( $self, $self->{$_.'_variable'},   sub { $self->{'callback'}->() }) for @pendulum_names;
    Wx::Event::EVT_COMBOBOX( $self, $self->{$_.'_operator'},   sub { $self->{'callback'}->() }) for @pendulum_names;

    my $std_attr  = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxGROW;
    my $box_attr  = $std_attr | &Wx::wxTOP | &Wx::wxBOTTOM;
    my $next_attr = &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP;

    my $x_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $x_sizer->AddSpacer( 15 );
    $x_sizer->Add( $self->{'lbl'}{'x'},    0, $box_attr, 12);
    $x_sizer->AddSpacer( 25 );
    $x_sizer->Add( $self->{'x_function'},  0, $box_attr, 6);
    $x_sizer->AddSpacer( 10 );
    $x_sizer->Add( $self->{'x_variable'},  0, $box_attr, 6);
    $x_sizer->AddSpacer( 10 );
    $x_sizer->Add( $self->{'x_operator'},  0, $box_attr, 6);
    $x_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $y_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL);
    $y_sizer->AddSpacer( 15 );
    $y_sizer->Add( $self->{'lbl'}{'y'},    0, $box_attr, 10);
    $y_sizer->AddSpacer( 25 );
    $y_sizer->Add( $self->{'y_function'},  0, $box_attr, 5);
    $y_sizer->AddSpacer( 10 );
    $y_sizer->Add( $self->{'y_variable'},  0, $box_attr, 5);
    $y_sizer->AddSpacer( 10 );
    $y_sizer->Add( $self->{'y_operator'},  0, $box_attr, 6);
    $y_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $e_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $e_sizer->AddSpacer( 15 );
    $e_sizer->Add( $self->{'lbl'}{'e'},   0, $box_attr, 10);
    $e_sizer->AddSpacer( 25 );
    $e_sizer->Add( $self->{'e_function'}, 0, $box_attr, 6);
    $e_sizer->AddSpacer( 10 );
    $e_sizer->Add( $self->{'e_variable'}, 0, $box_attr, 6);
    $e_sizer->AddSpacer( 10 );
    $e_sizer->Add( $self->{'e_operator'}, 0, $box_attr, 6);
    $e_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $f_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL);
    $f_sizer->AddSpacer( 15 );
    $f_sizer->Add( $self->{'lbl'}{'f'},   0, $box_attr, 10);
    $f_sizer->AddSpacer( 25 );
    $f_sizer->Add( $self->{'f_function'}, 0, $box_attr, 5);
    $f_sizer->AddSpacer( 10 );
    $f_sizer->Add( $self->{'f_variable'}, 0, $box_attr, 5);
    $f_sizer->AddSpacer( 10 );
    $f_sizer->Add( $self->{'f_operator'}, 0, $box_attr, 6);
    $f_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $wx_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL);
    $wx_sizer->AddSpacer( 15 );
    $wx_sizer->Add( $self->{'lbl'}{'w'},    0, $box_attr, 10);
    $wx_sizer->AddSpacer( 22 );
    $wx_sizer->Add( $self->{'wx_function'},  0, $box_attr, 6);
    $wx_sizer->AddSpacer( 10 );
    $wx_sizer->Add( $self->{'wx_variable'},  0, $box_attr, 6);
    $wx_sizer->AddSpacer( 10 );
    $wx_sizer->Add( $self->{'wx_operator'},  0, $box_attr, 6);
    $wx_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $wy_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL);
    $wy_sizer->AddSpacer( 55 );
    $wy_sizer->Add( $self->{'wy_function'},  0, $box_attr, 6);
    $wy_sizer->AddSpacer( 10 );
    $wy_sizer->Add( $self->{'wy_variable'},  0, $box_attr, 6);
    $wy_sizer->AddSpacer( 10 );
    $wy_sizer->Add( $self->{'wy_operator'},  0, $box_attr, 6);
    $wy_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $r11_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL);
    $r11_sizer->AddSpacer( 15 );
    $r11_sizer->Add( $self->{'lbl'}{'r'},    0, $box_attr, 10);
    $r11_sizer->AddSpacer( 25 );
    $r11_sizer->Add( $self->{'r11_function'},  0, $box_attr, 6);
    $r11_sizer->AddSpacer( 10 );
    $r11_sizer->Add( $self->{'r11_variable'},  0, $box_attr, 6);
    $r11_sizer->AddSpacer( 10 );
    $r11_sizer->Add( $self->{'r11_operator'},  0, $box_attr, 6);
    $r11_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $r12_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL);
    $r12_sizer->AddSpacer( 55 );
    $r12_sizer->Add( $self->{'r12_function'},  0, $box_attr, 6);
    $r12_sizer->AddSpacer( 10 );
    $r12_sizer->Add( $self->{'r12_variable'},  0, $box_attr, 6);
    $r12_sizer->AddSpacer( 10 );
    $r12_sizer->Add( $self->{'r12_operator'},  0, $box_attr, 6);
    $r12_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $r21_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL);
    $r21_sizer->AddSpacer( 55 );
    $r21_sizer->Add( $self->{'r21_function'},  0, $box_attr, 6);
    $r21_sizer->AddSpacer( 10 );
    $r21_sizer->Add( $self->{'r21_variable'},  0, $box_attr, 6);
    $r21_sizer->AddSpacer( 10 );
    $r21_sizer->Add( $self->{'r21_operator'},  0, $box_attr, 6);
    $r21_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $r22_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL);
    $r22_sizer->AddSpacer( 55 );
    $r22_sizer->Add( $self->{'r22_function'},  0, $box_attr, 6);
    $r22_sizer->AddSpacer( 10 );
    $r22_sizer->Add( $self->{'r22_variable'},  0, $box_attr, 6);
    $r22_sizer->AddSpacer( 10 );
    $r22_sizer->Add( $self->{'r22_operator'},  0, $box_attr, 6);
    $r22_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->Add( $x_sizer,                         0, $next_attr, 15);
    $sizer->Add( Wx::StaticLine->new( $self, -1),  0, $next_attr, 15);
    $sizer->Add( $y_sizer,                         0, $next_attr, 15);
    $sizer->Add( Wx::StaticLine->new( $self, -1),  0, $next_attr, 15);
    $sizer->Add( $e_sizer,                        0, $next_attr, 15);
    $sizer->Add( Wx::StaticLine->new( $self, -1),  0, $next_attr, 15);
    $sizer->Add( $f_sizer,                        0, $next_attr, 15);
    $sizer->Add( Wx::StaticLine->new( $self, -1),  0, $next_attr, 15);
    $sizer->Add( $wx_sizer,                        0, $next_attr, 15);
    $sizer->Add( $wy_sizer,                        0, $next_attr,  5);
    $sizer->Add( Wx::StaticLine->new( $self, -1),  0, $next_attr, 15);
    $sizer->Add( $r11_sizer,                       0, $next_attr, 15);
    $sizer->Add( $r12_sizer,                       0, $next_attr,  5);
    $sizer->Add( $r21_sizer,                       0, $next_attr,  5);
    $sizer->Add( $r22_sizer,                       0, $next_attr,  5);
    $sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    $self->SetSizer( $sizer );
    $self->init;
    $self;
}

sub init { $_[0]->set_settings ( $default ) }

sub set_settings {
    my ( $self, $data ) = @_;
    return unless ref $data eq 'HASH' and exists $data->{'x_function'};
    for my $key (keys %$default){
        $self->{ $key }->SetValue( $data->{ $key } // $default->{ $key, 1 } );
    }
    1;
}
sub get_settings {
    my ( $self ) = @_;
    return { map { $_, $self->{$_}->GetValue } keys %$default };
}

sub SetCallBack {
    my ( $self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'callback'} = $code;
}

1;
