use v5.18;
use warnings;
use Wx;

package App::Harmonograph::GUI;
my $VERSION = 0.1;
use base qw/Wx::App/;
use Wx::Event qw(EVT_PAINT EVT_MENU EVT_BUTTON EVT_TOGGLEBUTTON EVT_LEFT_DOWN EVT_RIGHT_DOWN EVT_LIST_ITEM_SELECTED);
use App::Harmonograph::GUI::Board;
use App::Harmonograph::GUI::SliderCombo;

sub OnInit {
	my $app   = shift;
	my $frame = Wx::Frame->new( undef, -1, 'Harmonograph '.$VERSION , [-1,-1], [-1,-1]);
    $frame->SetIcon( Wx::GetWxPerlIcon() );
    $frame->CreateStatusBar( 2 );
    $frame->SetStatusWidths(2, 800, 100);
    $frame->SetStatusText( "Harmonograph", 1 );

    my $btnw = 50; my $btnh = 35;# button width

    $frame->{'btn'}{'new'}  = Wx::Button->new( $frame, -1, '&New',    [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'open'} = Wx::Button->new( $frame, -1, '&Open',   [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'save'} = Wx::Button->new( $frame, -1, '&Save',   [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'keep'} = Wx::Button->new( $frame, -1, '&Rem',   [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'exit'} = Wx::Button->new( $frame, -1, '&Exit',   [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'new'} ->SetToolTip('put all settings to default');
    $frame->{'btn'}{'open'}->SetToolTip('load image settings from a text file');
    $frame->{'btn'}{'keep'}->SetToolTip('save image settings into text file');
    $frame->{'btn'}{'save'}->SetToolTip('save image into SVG file');
    $frame->{'btn'}{'exit'}->SetToolTip('close the application');
    #$frame->{'btn'}{'exit'}   = Wx::ToggleButton->new($frame,-1,'&Exit',[-1,-1],[$btnw, $btnh] );

    $frame->{'cmb'}{'x'} = App::Harmonograph::GUI::SliderCombo->new( $frame, 'X','frequence in x direction', 1, 20, 1);
    $frame->{'cmb'}{'y'} = App::Harmonograph::GUI::SliderCombo->new( $frame, 'Y','frequence in y direction', 1, 20, 1);
    $frame->{'cmb'}{'z'} = App::Harmonograph::GUI::SliderCombo->new( $frame, 'Z','frequence of rotation of board', 0, 20, 1);
    $frame->{'cmb'}{'t'} = App::Harmonograph::GUI::SliderCombo->new( $frame, 'T','length of drawing',       2, 1000, 20, 20);
    
    $frame->{'board'}         = App::Harmonograph::GUI::Board->new($frame, 500, 500);

    $frame->{'list'}{'cand'}  = Wx::ListCtrl->new( $frame, -1, [-1,-1],[290,-1], &Wx::wxLC_ICON );
    Wx::ToolTip::Enable(1);

    EVT_LEFT_DOWN( $frame->{'board'}, sub {
        my ($panel, $event) = @_;
        return unless $frame->{'editable'};
        my ($mx, $my) = ($event->GetX, $event->GetY);
        my $c = 1 + int(($mx - 15)/52);
        my $r = 1 + int(($my - 16)/57);
        return if $r < 1 or $r > 9 or $c < 1 or $c > 9;
        return if $frame->{'game'}->cell_solution( $r, $c );
        my $sol_menu = Wx::Menu->new();
        for (1 .. 9) {$sol_menu->Append($_, $_) if $frame->{'game'}->is_cell_candidate($r,$c,$_)}
        my $digit = $panel->GetPopupMenuSelectionFromUser( $sol_menu, $event->GetX, $event->GetY);
        return unless $digit > 0;
        $frame->{'game'}->solve_cell($r, $c, $digit, 'set by app user');
        $frame->SetStatusText( "set $digit at row $r, col $c", 1 );
        update_game( $frame );
    });
    EVT_RIGHT_DOWN( $frame->{'board'}, sub {
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
    EVT_BUTTON( $frame, $frame->{'btn'}{'new'},  sub {
        $frame->{'board'}{'game'} = $frame->{'game'} = Games::Sudoku::Solver::Strategy::Game->new();
        update_game( $frame );
        $frame->SetStatusText( "new game created", 0 );
    } );
    EVT_BUTTON( $frame, $frame->{'btn'}{'open'}, sub {
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
    EVT_BUTTON( $frame, $frame->{'btn'}{'save'}, sub {
        my $dialog = Wx::FileDialog->new ( $frame, "Select a file", '.', '',
                   ( join '|', 'Sudoku files (*.txt)|*.txt', 'All files (*.*)|*.*' ), &Wx::wxFD_SAVE );
        if( $dialog->ShowModal == &Wx::wxID_CANCEL ) {}
        else {
            my @paths = $dialog->GetPaths;
            $frame->{'game'}->save( $paths[0] );
            $frame->SetStatusText( "saved $paths[0]", 0 );
            $frame->Refresh;
    }});
    EVT_BUTTON( $frame, $frame->{'btn'}{'keep'},  sub {
       
    } );
    EVT_BUTTON( $frame, $frame->{'btn'}{'exit'},  sub { $frame->Close; } );
    # EVT_TOGGLEBUTTON( $frame, $frame->{'btn'}{'edit'}, sub { $frame->{'editable'} = $_[1]->IsChecked() } );

    EVT_LIST_ITEM_SELECTED( $frame, $frame->{'list'}{'cand'}, sub {$frame->{'txt'}{'comment'}->SetValue($frame->{'game'}{'candidate_stack'}[ $_[1]->GetIndex() ][3]) } );
    EVT_LIST_ITEM_SELECTED( $frame, $frame->{'list'}{'sol'},   sub {$frame->{'txt'}{'comment'}->SetValue($frame->{'game'}{'solution_stack'}[ $_[1]->GetIndex() ][3])  });
    EVT_LIST_ITEM_SELECTED( $frame, $frame->{'list'}{'history'},sub {$frame->{'txt'}{'comment'}->SetValue($frame->{'game'}{'solving_steps'}[ $_[1]->GetIndex() ][4])  });

    my $cmd_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $cmd_sizer->Add( 5, 0, &Wx::wxEXPAND);
    $cmd_sizer->Add( $frame->{'btn'}{$_}, 0, &Wx::wxALL, 10 ) for qw/new open keep save exit/;
    $cmd_sizer->Insert( 4, 0, 40, 0);
    $cmd_sizer->Insert( 6, 0, 40, 0);
    $cmd_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $board_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $board_sizer->Add( $frame->{'board'}, 0, &Wx::wxEXPAND);
    $board_sizer->Add( 0, 4, 0);
    $board_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);


    my $setting_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $setting_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    $setting_sizer->Add( $frame->{'cmb'}{'x'}, 1, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxALL, 10);
    $setting_sizer->Add( $frame->{'cmb'}{'y'}, 1, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxALL, 10);
    $setting_sizer->Add( $frame->{'cmb'}{'z'}, 1, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxALL, 10);
    $setting_sizer->Add( $frame->{'cmb'}{'t'}, 1, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxALL, 10);
    $setting_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $main_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $main_sizer->Add( $cmd_sizer, 0, &Wx::wxEXPAND, 0);
    $main_sizer->Add( $board_sizer, 0, &Wx::wxEXPAND, 0);
    $main_sizer->Add( $setting_sizer, 0, &Wx::wxEXPAND, 0);
    $main_sizer->Add( 0, 0, &Wx::wxEXPAND|&Wx::wxGROW);

    $frame->SetSizer($main_sizer);
    $frame->SetAutoLayout( 1 ); # say $frame->GetSize->GetHeight, ' ', $frame->GetSize->GetWidth;
    $frame->{'btn'}{'new'}->SetFocus;
    my $size = [1230,672];
    $frame->SetSize($size);
    $frame->SetMinSize($size);
    $frame->SetMaxSize($size);
    $frame->Show(1);
    $frame->CenterOnScreen();
    $app->SetTopWindow($frame);
    1;
}

sub reload_lists {
    my( $frame, $game ) = shift;
    $frame->{'list'}{'sol'}->DeleteAllItems();
    $frame->{'list'}{'sol'}->InsertStringItem( 0, "$_->[0],$_->[1] : $_->[2]") for reverse @{$frame->{'game'}{'solution_stack'}};
}

sub OnQuit { my( $self, $event ) = @_; $self->Close( 1 ); }
sub OnExit { my $app = shift;  1; }

1;


__END__
