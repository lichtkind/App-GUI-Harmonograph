use v5.18;
use warnings;
use Wx;
use utf8;

package App::Harmonograph::GUI;
my $VERSION = 0.11;
use base qw/Wx::App/;
use App::Harmonograph::GUI::Board;
use App::Harmonograph::GUI::Pendulum;
use App::Harmonograph::GUI::Color::Constant;

sub OnInit {
    my $app   = shift;
    my $frame = Wx::Frame->new( undef, -1, 'Harmonograph '.$VERSION , [-1,-1], [-1,-1]);
    $frame->SetIcon( Wx::GetWxPerlIcon() );
    $frame->CreateStatusBar( 2 );
    $frame->SetStatusWidths(2, 800, 100);
    $frame->SetStatusText( "Harmonograph", 1 );

    my $btnw = 50; my $btnh = 35;# button width and height
    $frame->{'btn'}{'new'}   = Wx::Button->new( $frame, -1, '&New',    [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'open'}  = Wx::Button->new( $frame, -1, '&Open',   [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'write'} = Wx::Button->new( $frame, -1, '&Write',  [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'draw'}  = Wx::Button->new( $frame, -1, '&Draw',   [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'save'}  = Wx::Button->new( $frame, -1, '&Save',   [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'exit'}  = Wx::Button->new( $frame, -1, '&Exit',   [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'new'} ->SetToolTip('put all settings to default');
    $frame->{'btn'}{'open'}->SetToolTip('load image settings from a text file');
    $frame->{'btn'}{'write'}->SetToolTip('save image settings into text file');
    $frame->{'btn'}{'draw'}->SetToolTip('redraw the harmonographic image');
    $frame->{'btn'}{'save'}->SetToolTip('save image into SVG file');
    $frame->{'btn'}{'exit'}->SetToolTip('close the application');

    $frame->{'pendulum'}{'x'}  = App::Harmonograph::GUI::Pendulum->new( $frame, 'x','pendulum in x direction (left to right)', 1, 30);
    $frame->{'pendulum'}{'y'}  = App::Harmonograph::GUI::Pendulum->new( $frame, 'y','pendulum in y direction (left to right)', 1, 30);
    $frame->{'pendulum'}{'z'}  = App::Harmonograph::GUI::Pendulum->new( $frame, 'z','circular pendulum in z direction',        0, 30);
    $frame->{'cmb'}{'dr'} = App::Harmonograph::GUI::SliderCombo->new( $frame, 100, 'ΔR'  ,'damping factor',                        0,  100,   0);
    $frame->{'cmb'}{'t'}  = App::Harmonograph::GUI::SliderCombo->new( $frame, 100, ' T  ','length of drawing in full circles',     1,  150,  10);
    $frame->{'cmb'}{'dt'} = Wx::Slider->new( $frame, -1, 500, 10, 2000, [-1, -1], [120, -1], &Wx::wxSL_HORIZONTAL | &Wx::wxSL_BOTTOM );
    $frame->{'cmb'}{'dt'}->SetToolTip('pixel per circle');
    $frame->{'cmb'}{'ps'}  = Wx::ComboBox->new( $frame, -1, 1, [-1,-1],[65, -1], [1,2,3,4,5,6,7,8] );
    $frame->{'cmb'}{'ps'}->SetToolTip('dot size in pixel');
    $frame->{'cmb'}{'r'} =  App::Harmonograph::GUI::SliderCombo->new( $frame, 100, ' R  ', 'red part of color',    0, 255,  0);
    $frame->{'cmb'}{'g'} =  App::Harmonograph::GUI::SliderCombo->new( $frame, 100, ' G  ', 'green part of color',  0, 255,  0);
    $frame->{'cmb'}{'b'} =  App::Harmonograph::GUI::SliderCombo->new( $frame, 100, ' B  ', 'blue part of color',   0, 255,  0);
    $frame->{'cmb'}{'h'} =  App::Harmonograph::GUI::SliderCombo->new( $frame, 100, ' H  ', 'hue of color',         0, 359,  0);
    $frame->{'cmb'}{'s'} =  App::Harmonograph::GUI::SliderCombo->new( $frame, 100, ' S  ', 'green part of color',  0, 100,  0);
    $frame->{'cmb'}{'l'} =  App::Harmonograph::GUI::SliderCombo->new( $frame, 100, ' L  ', 'lightness of color',   0, 100,  0);

    my $rgb2hsl = sub {
        my $r = $frame->{'cmb'}{'r'}->GetValue;
        my $g = $frame->{'cmb'}{'g'}->GetValue;
        my $b = $frame->{'cmb'}{'b'}->GetValue;
        my ($h, $s, $l) = App::Harmonograph::GUI::Color::Value::hsl_from_rgb( $r, $g, $b);
        $frame->{'cmb'}{'h'}->SetValue( $h, 1 );
        $frame->{'cmb'}{'s'}->SetValue( $s, 1 );
        $frame->{'cmb'}{'l'}->SetValue( $l, 1 );
    };
    my $hsl2rgb = sub {
        my $h = $frame->{'cmb'}{'h'}->GetValue;
        my $s = $frame->{'cmb'}{'s'}->GetValue;
        my $l = $frame->{'cmb'}{'l'}->GetValue;
        my ($r, $g, $b) = App::Harmonograph::GUI::Color::Value::rgb_from_hsl( $h, $s, $l);
        $frame->{'cmb'}{'r'}->SetValue( $r, 1 );
        $frame->{'cmb'}{'g'}->SetValue( $g, 1 );
        $frame->{'cmb'}{'b'}->SetValue( $b, 1 );
     };
    $frame->{'cmb'}{'r'}->SetCallBack( $rgb2hsl );
    $frame->{'cmb'}{'g'}->SetCallBack( $rgb2hsl );
    $frame->{'cmb'}{'b'}->SetCallBack( $rgb2hsl );
    $frame->{'cmb'}{'h'}->SetCallBack( $hsl2rgb );
    $frame->{'cmb'}{'s'}->SetCallBack( $hsl2rgb );
    $frame->{'cmb'}{'l'}->SetCallBack( $hsl2rgb );
    
    $frame->{'board'}    = App::Harmonograph::GUI::Board->new($frame, 600, 600);

# color flow
# slower with damping

    Wx::ToolTip::Enable(1);
    Wx::Event::EVT_LEFT_DOWN( $frame->{'board'}, sub {  });
    Wx::Event::EVT_RIGHT_DOWN( $frame->{'board'}, sub {
        my ($panel, $event) = @_;
        return unless $frame->{'editable'};
        my ($mx, $my) = ($event->GetX, $event->GetY);
        my $c = 1 + int(($mx - 15)/52);
        my $r = 1 + int(($my - 16)/57);
        return if $r < 1 or $r > 9 or $c < 1 or $c > 9;
        return if $frame->{'game'}->cell_solution( $r, $c );
        my $cand_menu = Wx::Menu->new();
        $cand_menu->AppendCheckItem($_,$_) for 1..9;
        my $nr;
        for (1 .. 9) {$cand_menu->Check($_, 1),$nr++ if $frame->{'game'}->is_cell_candidate($r,$c,$_) }
        return if $nr < 2;
        my $digit = $panel->GetPopupMenuSelectionFromUser( $cand_menu, $event->GetX, $event->GetY);
        return unless $digit > 0;
        $frame->{'game'}->remove_candidate($r, $c, $digit, 'set by app user');
        update_game( $frame );
    });
    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'new'}, sub { $app->reset($frame) });
    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'open'}, sub {
        my $s = shift;
        my $dialog = Wx::FileDialog->new ( $frame, "Select a file", './beispiel', './beispiel/schwer.txt',
                   ( join '|', 'Sudoku files (*.txt)|*.txt', 'All files (*.*)|*.*' ), &Wx::wxFD_OPEN|&Wx::wxFD_MULTIPLE );
        if( $dialog->ShowModal == &Wx::wxID_CANCEL ) {}
        else {
            $frame->{'game'} = $frame->{'board'}{'game'} =  Games::Sudoku::Solver::Strategy::Game->new();
            my @paths = $dialog->GetPaths;
            $frame->{'game'}->load($paths[0]);
            $frame->SetStatusText( "loaded $paths[0]", 0 );
            update_game( $frame );
    }});
    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'write'},  sub {
        my $dialog = Wx::FileDialog->new ( $frame, "Select a file name to store data", '.', '',
                   ( join '|', 'SVG files (*.tsv)|*.tsv', 'All files (*.*)|*.*' ), &Wx::wxFD_SAVE );
        if( $dialog->ShowModal != &Wx::wxID_CANCEL ) {
            my @paths = $dialog->GetPaths;
            $frame->{'board'}->save_file( $paths[0] );
            # $frame->SetStatusText( "saved $paths[0]", 0 );
        }
    });
    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'draw'},  sub { $app->draw( $frame ) });
    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'save'},  sub {
        my $dialog = Wx::FileDialog->new ( $frame, "select a file name to save image", '.', '',
                   ( join '|', 'SVG files (*.svg)|*.svg', 'All files (*.*)|*.*' ), &Wx::wxFD_SAVE );
        if( $dialog->ShowModal != &Wx::wxID_CANCEL ) {
            my @paths = $dialog->GetPaths;
            $frame->{'board'}->save_file( $paths[0] );
            $frame->SetStatusText( "saved $paths[0]", 0 );
        }
    });
    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'exit'},  sub { $frame->Close; } );


    my $cmd_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $cmd_sizer->Add( 5, 0, &Wx::wxEXPAND);
    $cmd_sizer->Add( $frame->{'btn'}{$_}, 0, &Wx::wxALL, 10 ) for qw/new open write draw save exit/;
    $cmd_sizer->Insert( 4, 0, 40, 0);
    $cmd_sizer->Insert( 7, 0, 40, 0);
    $cmd_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $board_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $board_sizer->Add( $frame->{'board'}, 1, &Wx::wxEXPAND|&Wx::wxALL, 10);
    $board_sizer->Add( 0, 4, 0);
    $board_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $t_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $t_sizer->Add( $frame->{'cmb'}{'t'},  0, &Wx::wxALIGN_LEFT| &Wx::wxGROW | &Wx::wxRIGHT, 0);
    $t_sizer->Add( Wx::StaticText->new($frame, -1, 'Dense', [-1, -1], [-1, -1]), 
                      0, &Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW|&Wx::wxALL, 12);
    $t_sizer->Add( $frame->{'cmb'}{'dt'}, 0, &Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW| &Wx::wxRIGHT, 5);
    $t_sizer->Add( Wx::StaticText->new($frame, -1, 'Px', [-1, -1], [-1, -1]), 
                      0, &Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW|&Wx::wxALL, 12);
    $t_sizer->Add( $frame->{'cmb'}{'ps'}, 0, &Wx::wxALIGN_LEFT|&Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW, 0);
    $t_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $rh_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $rh_sizer->Add( $frame->{'cmb'}{'r'},  0, &Wx::wxGROW|&Wx::wxLEFT, 10);
    $rh_sizer->Add( $frame->{'cmb'}{'h'},  0, &Wx::wxGROW|&Wx::wxLEFT, 50);
    $rh_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $gs_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $gs_sizer->Add( $frame->{'cmb'}{'g'},  0, &Wx::wxGROW|&Wx::wxLEFT, 10);
    $gs_sizer->Add( $frame->{'cmb'}{'s'},  0, &Wx::wxGROW|&Wx::wxLEFT, 50);
    $gs_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $bl_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $bl_sizer->Add( $frame->{'cmb'}{'b'},  0, &Wx::wxGROW|&Wx::wxLEFT, 10);
    $bl_sizer->Add( $frame->{'cmb'}{'l'},  0, &Wx::wxGROW|&Wx::wxLEFT, 50);
    $bl_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $setting_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $setting_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    $setting_sizer->Add( $frame->{'pendulum'}{'x'},  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxALL, 10);
    $setting_sizer->Add( $frame->{'pendulum'}{'y'},  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxALL, 10);
    $setting_sizer->Add( $frame->{'pendulum'}{'z'},  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxALL, 10);
    $setting_sizer->Add( $frame->{'cmb'}{'dr'},      0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxALL, 10);
    $setting_sizer->Add( $t_sizer,                   0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxALL, 10);
    $setting_sizer->Add( $rh_sizer,                  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxTOP, 20);
    $setting_sizer->Add( $gs_sizer,                  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW, 0);
    $setting_sizer->Add( $bl_sizer,                  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW, 0);
    $setting_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $main_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $main_sizer->Add( $cmd_sizer, 0, &Wx::wxEXPAND, 0);
    $main_sizer->Add( $board_sizer, 0, &Wx::wxEXPAND, 0);
    $main_sizer->Add( $setting_sizer, 0, &Wx::wxEXPAND, 0);
    $main_sizer->Add( 0, 0, &Wx::wxEXPAND|&Wx::wxGROW);

    $frame->SetSizer($main_sizer);
    $frame->SetAutoLayout( 1 );
    $frame->{'btn'}{'draw'}->SetFocus;
    my $size = [1300,700];
    $frame->SetSize($size);
    $frame->SetMinSize($size);
    $frame->SetMaxSize($size);
    $frame->Show(1);
    $frame->CenterOnScreen();
    $app->SetTopWindow($frame);
    $app->reset( $frame );
    1;
}

sub draw {
    my ($app, $frame) = @_;
    $frame->SetStatusText( "drawing .....", 0 );
    $frame->{'board'}->set_data( { 
        x => $frame->{'pendulum'}{'x'}->get_data,
        y => $frame->{'pendulum'}{'y'}->get_data,
        z => $frame->{'pendulum'}{'z'}->get_data,
        color => {
            r => $frame->{'cmb'}{'r'}->GetValue,
            g => $frame->{'cmb'}{'g'}->GetValue,
            b => $frame->{'cmb'}{'b'}->GetValue,
        },
        map { $_ => $frame->{'cmb'}{$_}->GetValue } qw/dr t dt ps/, 
    }, );
    $frame->{'board'}->Refresh;
    $frame->SetStatusText( "done", 0 );
}
sub reset {
    my ($app, $frame) = @_;
    $frame->{'pendulum'}{$_}->init() for qw/x y z/;
    $frame->{'cmb'}{'ps'}->SetValue(1);
    $frame->{'cmb'}{'dt'}->SetValue(500);
    $frame->{'cmb'}{'dr'}->SetValue(0);
    $frame->{'cmb'}{'t'}->SetValue(10);
    $frame->{'cmb'}{'r'}->SetValue(20, 1);
    $frame->{'cmb'}{'g'}->SetValue(20, 1);
    $frame->{'cmb'}{'b'}->SetValue(110);
    $app->draw( $frame );
}


sub OnQuit { my( $self, $event ) = @_; $self->Close( 1 ); }
sub OnExit { my $app = shift;  1; }

1;

__END__
    #$frame->{'list'}{'sol'}->DeleteAllItems();
    #$frame->{'list'}{'sol'}->InsertStringItem( 0, "$_->[0],$_->[1] : $_->[2]") for reverse @{$frame->{'game'}{'solution_stack'}};
    #$frame->{'btn'}{'exit'}   = Wx::ToggleButton->new($frame,-1,'&Exit',[-1,-1],[$btnw, $btnh] );
    #$frame->{'list'}{'cand'}  = Wx::ListCtrl->new( $frame, -1, [-1,-1],[290,-1], &Wx::wxLC_ICON );
    # EVT_TOGGLEBUTTON( $frame, $frame->{'btn'}{'edit'}, sub { $frame->{'editable'} = $_[1]->IsChecked() } );
    # Wx::Event::EVT_LIST_ITEM_SELECTED( $frame, $frame->{'list'}{'cand'}, sub {$frame->{'txt'}{'comment'}->SetValue($frame->{'game'}{'candidate_stack'}[ $_[1]->GetIndex() ][3]) } );
