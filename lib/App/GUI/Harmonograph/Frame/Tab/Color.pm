
# color panel tab

use v5.12;
use warnings;
use Wx;

package App::GUI::Harmonograph::Frame::Tab::Color;
use base qw/Wx::Panel/;

use App::GUI::Harmonograph::Frame::Panel::ColorBrowser;
use App::GUI::Harmonograph::Frame::Panel::ColorPicker;
use App::GUI::Harmonograph::Frame::Panel::ColorSetPicker;
use App::GUI::Harmonograph::Widget::ColorDisplay;
use App::GUI::Harmonograph::Widget::PositionMarker;
use Graphics::Toolkit::Color qw/color/;

our $default_color_def = $App::GUI::Harmonograph::Frame::Panel::ColorSetPicker::default_color;
my $default_settings = { 1=> 'blue', 2=> 'red', dynamic => 1, delta_S => 0, delta_L => 0 };

sub new {
    my ( $class, $parent, $config ) = @_;
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'call_back'}  = sub {};
    $self->{'config'}     = $config;
    $self->{'color_count'} = 11;  # max pos
    $self->{'active_color_count'} = 2;  # nr of currently used
    $self->{'current_color_nr'} = 1;
    $self->{'display_size'} = 32;

    $self->{'used_colors'}       = [ color('blue')->gradient( to => 'red', steps => $self->{'active_color_count'}) ];
    $self->{'used_colors'}[$_]   = color( $default_color_def ) for $self->{'active_color_count'} .. $self->{'color_count'}-1;
    $self->{'color_marker'}      = [ map { App::GUI::Harmonograph::Widget::PositionMarker->new
                                           ($self, $self->{'display_size'}, 20, $_, '', $default_color_def) } 0 .. $self->{'color_count'}-1 ];
    $self->{'color_display'}[$_] = App::GUI::Harmonograph::Widget::ColorDisplay->new
        ($self, $self->{'display_size'}-2, $self->{'display_size'},
         $_, $self->{'used_colors'}[$_]->values(as => 'hash')      ) for 0 .. $self->{'color_count'}-1;
    $self->{'color_marker'}[$_-1]->SetToolTip("used color number $_ to change (marked by arrow - crosses mark currently passive colors)") for 2 .. $self->{'color_count'};
    $self->{'color_display'}[$_-1]->SetToolTip("used color number $_ to change (marked by arrow - crosses mark currently passive colors)") for 2 .. $self->{'color_count'};
    $self->{'color_marker'}[0]->SetToolTip("color number 1, is always used, even when color flow is deactivated, click on it before change it with sliders below");
    $self->{'color_display'}[0]->SetToolTip("color number 1, is always used, even when color flow is deactivated, click on it before change it with sliders below");

    $self->{'label'}{'color_set_store'} = Wx::StaticText->new($self, -1, 'Color Set Store' );
    $self->{'label'}{'color_set_funct'} = Wx::StaticText->new($self, -1, 'Colors Set Function' );
    $self->{'label'}{'used_colors'}     = Wx::StaticText->new($self, -1, 'Currently Used Colors' );
    $self->{'label'}{'selected_color'}  = Wx::StaticText->new($self, -1, 'Selected State Color' );
    $self->{'label'}{'color_store'}     = Wx::StaticText->new($self, -1, 'Color Store' );

    $self->{'widget'}{'dynamic'} = Wx::ComboBox->new( $self, -1, 1, [-1,-1],[75, -1], [ 0.2, 0.25, 0.33, 0.4, 0.5, 0.66, 0.7, 0.83, 0.9, 1, 1.2, 1.5, 2, 2.5, 3, 4 ]);
    $self->{'widget'}{'delta_S'} = Wx::TextCtrl->new( $self, -1, 0, [-1,-1], [50,-1], &Wx::wxTE_RIGHT);
    $self->{'widget'}{'delta_L'} = Wx::TextCtrl->new( $self, -1, 0, [-1,-1], [50,-1], &Wx::wxTE_RIGHT);

    $self->{'btn'}{'gray'}       = Wx::Button->new( $self, -1, 'Gray',       [-1,-1], [45, 17] );
    $self->{'btn'}{'gradient'}   = Wx::Button->new( $self, -1, 'Gradient',   [-1,-1], [70, 17] );
    $self->{'btn'}{'complement'} = Wx::Button->new( $self, -1, 'Complement', [-1,-1], [90, 17] );
    $self->{'btn'}{'gray'}->SetToolTip("reset to default grey scale color pallet. Adheres to count of needed colors and current dynamic settings.");
    $self->{'btn'}{'gradient'}->SetToolTip("create gradient between first and current color. Adheres to dynamic settings.");
    $self->{'btn'}{'complement'}->SetToolTip("Create color set from first up to current color as complementary colors. Adheres to both delta values.");
    $self->{'widget'}{'dynamic'}->SetToolTip("dynamic of gradient (1 = linear) and also of gray scale");
    $self->{'widget'}{'delta_S'}->SetToolTip("max. satuaration deviation when computing complement colors ( -100 .. 100)");
    $self->{'widget'}{'delta_L'}->SetToolTip("max. lightness deviation when computing complement colors ( -100 .. 100)");


    $self->{'picker'}    = App::GUI::Harmonograph::Frame::Panel::ColorPicker->new( $self, $config->get_value('color') );
    $self->{'setpicker'} = App::GUI::Harmonograph::Frame::Panel::ColorSetPicker->new( $self, $config->get_value('color_set'), $self->{'color_count'});

    $self->{'browser'}   = App::GUI::Harmonograph::Frame::Panel::ColorBrowser->new( $self, 'selected', {red => 0, green => 0, blue => 0} );
    $self->{'browser'}->SetCallBack( sub { $self->set_current_color( $_[0] ) });

    Wx::Event::EVT_LEFT_DOWN( $self->{'color_display'}[$_], sub { $self->set_current_color_nr( $_[0]->get_nr ) }) for 0 .. $self->{'color_count'}-1;
    Wx::Event::EVT_LEFT_DOWN( $self->{'color_marker'}[$_], sub { $self->set_current_color_nr( $_[0]->get_nr ) }) for 0 .. $self->{'color_count'}-1;


    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'gray'}, sub {
        $self->set_all_colors( color('white')->gradient( to => 'black', steps => $self->{'active_color_count'}, dynamic => $self->{'widget'}{'dynamic'}->GetValue) );
    });
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'gradient'}, sub {
        my @c = $self->get_all_colors;
        my @new_colors = $c[0]->gradient( to => $c[ $self->{'current_color_nr'} ], in => 'RGB', steps => $self->{'current_color_nr'}+1, dynamic => $self->{'widget'}{'dynamic'}->GetValue);
        $self->set_all_colors( @new_colors );
    });
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'complement'}, sub {
        my @c = $self->get_all_colors;
        my @new_colors = $c[ $self->{'current_color_nr'} ]->complement( steps => $self->{'current_color_nr'}+1,
                                                                     saturation_tilt => $self->{'widget'}{'delta_S'}->GetValue,
                                                                     lightness_tilt => $self->{'widget'}{'delta_L'}->GetValue );
        push @new_colors, shift @new_colors;
        $self->set_all_colors( @new_colors );
    });

    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW ;
    my $all_attr = $std_attr | &Wx::wxALL | &Wx::wxALIGN_CENTER_HORIZONTAL | &Wx::wxALIGN_CENTER_VERTICAL;
    my $next_attr = &Wx::wxGROW | &Wx::wxTOP | &Wx::wxALIGN_CENTER_HORIZONTAL;

    my $f_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $f_sizer->AddSpacer( 10 );
    $f_sizer->Add( $self->{'btn'}{'gray'},       0, $all_attr, 5 );
    $f_sizer->Add( $self->{'btn'}{'gradient'},   0, $all_attr, 5 );
    $f_sizer->Add( $self->{'widget'}{'dynamic'}, 0, $all_attr, 5 );
    $f_sizer->AddSpacer( 20 );
    $f_sizer->Add( $self->{'btn'}{'complement'}, 0, $all_attr, 5 );
    $f_sizer->Add( $self->{'widget'}{'delta_S'}, 0, $all_attr, 5 );
    $f_sizer->Add( $self->{'widget'}{'delta_L'}, 0, $all_attr, 5 );
    $f_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $state_sizer = $self->{'state_sizer'} = Wx::BoxSizer->new(&Wx::wxHORIZONTAL); # $self->{'plate_sizer'}->Clear(1);
    $state_sizer->AddSpacer( 10 );
    my @option_sizer;
    for my $nr (0 .. $self->{'color_count'}-1){
        $option_sizer[$nr] = Wx::BoxSizer->new( &Wx::wxVERTICAL );
        $option_sizer[$nr]->AddSpacer( 2 );
        $option_sizer[$nr]->Add( $self->{'color_display'}[$nr],0, $all_attr, 3);
        $option_sizer[$nr]->Add( $self->{'color_marker'}[$nr], 0, $all_attr, 3);
        $state_sizer->Add( $option_sizer[$nr],                 0, $all_attr, 6);
        $state_sizer->AddSpacer( 1 );
    }
    $state_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->AddSpacer( 10 );
    $sizer->Add( $self->{'label'}{'color_set_store'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL,   0);
    $sizer->Add( $self->{'setpicker'},                0, $all_attr,                       10);
    $sizer->Add( Wx::StaticLine->new( $self, -1),     0, $all_attr,                        0);
    $sizer->AddSpacer( 10 );
    $sizer->Add( $self->{'label'}{'color_set_funct'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL,   0);
    $sizer->Add( $f_sizer,                            0, $all_attr,                       10);
    $sizer->Add( Wx::StaticLine->new( $self, -1),     0, $all_attr,                        0);
    $sizer->AddSpacer( 10 );
    $sizer->Add( $self->{'label'}{'used_colors'},     0, &Wx::wxALIGN_CENTER_HORIZONTAL,   0);
    $sizer->Add( $state_sizer,                        0, $std_attr,                        0);
    $sizer->Add( Wx::StaticLine->new( $self, -1),     0, $all_attr,                        0);
    $sizer->AddSpacer( 10 );
    $sizer->Add( $self->{'label'}{'selected_color'},  0, &Wx::wxALIGN_CENTER_HORIZONTAL,  10);
    $sizer->Add( $self->{'browser'},                  0, $next_attr, 10);
    $sizer->Add( Wx::StaticLine->new( $self, -1),     0, $next_attr, 10);
    $sizer->AddSpacer( 10 );
    $sizer->Add( $self->{'label'}{'color_store'},     0, &Wx::wxALIGN_CENTER_HORIZONTAL, 10);
    $sizer->Add( $self->{'picker'},                   0, $std_attr| &Wx::wxLEFT,         10);
    $sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    $self->SetSizer( $sizer );
    $self->set_active_color_count( $self->{'active_color_count'} );
    $self->set_current_color_nr ( $self->{'current_color_nr'} );
    $self->init;
    $self;
}

sub SetCallBack {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}

sub set_active_color_count {
    my ($self, $count) = @_;
    $self->{'active_color_count'} = $count;
    $self->{'color_marker'}[$_]->set_state('passive') for 0 .. $self->{'active_color_count'}-1;
    $self->{'color_marker'}[$_]->set_state('disabled') for $self->{'active_color_count'} .. $self->{'color_count'}-1;
    $self->{'color_marker'}[ $self->{'current_color_nr'} ]->set_state('active');
}

sub set_current_color_nr {
    my ($self, $nr) = @_;
    $nr //= $self->{'current_color_nr'};
    my $old_marker_state = ($self->{'current_color_nr'} < $self->{'active_color_count'}) ? 'passive' : 'disabled';
    $self->{'color_marker'}[$self->{'current_color_nr'}]->set_state( $old_marker_state );
    $self->{'color_marker'}[ $nr ]->set_state('active');
    $self->{'current_color_nr'} = $nr;
    $self->{'browser'}->set_data( $self->{'used_colors'}[$self->{'current_color_nr'}]->values(as => 'hash'), 'silent' );
}

sub init { $_[0]->set_settings( $default_settings ) }

sub set_settings {
    my ($self, $settings) = @_;
    return unless ref $settings eq 'HASH' and exists $settings->{'dynamic'};
    $self->{'widget'}{$_}->SetValue( $settings->{$_} // $default_settings->{$_} ) for qw/dynamic delta_S delta_L/;
    $self->set_all_colors( grep {defined $_} map {$settings->{$_}} 1 .. $self->{'color_count'} );
}

sub get_state    { $_[0]->get_settings }
sub get_settings {
    my ($self) = @_;
    my $data = {
        dynamic => $self->{'widget'}{'dynamic'}->GetValue,
        delta_S => $self->{'widget'}{'delta_S'}->GetValue,
        delta_L => $self->{'widget'}{'delta_L'}->GetValue,
    };
    $data->{$_} = $self->{'used_colors'}[$_-1]->values(as => 'hex') for 1 .. $self->{'color_count'};
    $data;
}

sub get_current_color {
    my ($self) = @_;
    $self->{'used_colors'}[$self->{'current_color_nr'}];
}

sub set_current_color {
    my ($self, $color) = @_;
    return unless ref $color eq 'HASH';
    $self->{'used_colors'}[$self->{'current_color_nr'}] = color( $color );
    $self->{'color_display'}[$self->{'current_color_nr'}]->set_color( $color );
    $self->{'browser'}->set_data( $color );
    $self->{'call_back'}->( 'color' ); # update whole app
}

sub set_all_colors {
    my ($self, @colors) = @_;
    return unless @colors;
    for my $i (0 .. $#colors){
        my $temp = $colors[ $i ];
        $colors[ $i ] = color( $temp ) if ref $temp ne 'Graphics::Toolkit::Color';
        return "value number $i: $temp is no color" if ref $colors[ $i ] ne 'Graphics::Toolkit::Color';
    }
    $self->{'used_colors'} = [@colors];
    $self->{'used_colors'}[$_] = color( $default_color_def ) for @colors .. $self->{'color_count'}-1;
    $self->{'color_display'}[$_]->set_color( $self->{'used_colors'}[$_]->values(as => 'hash') ) for 0 .. $self->{'color_count'}-1;
    $self->set_current_color_nr;
    $self->{'call_back'}->( 'color' ); # update whole app
}

sub get_all_colors { @{$_[0]->{'used_colors'}} }
sub get_active_colors { @{$_[0]->{'used_colors'}}[ 0 .. $_[0]->{'active_color_count'} - 1] }

sub update_config {
    my ($self) = @_;
    $self->{'config'}->set_value('color',     $self->{'picker'}->get_config);
    $self->{'config'}->set_value('color_set', $self->{'setpicker'}->get_config);
}



1;
