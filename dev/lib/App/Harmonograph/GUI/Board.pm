use v5.18;
use warnings;
use Wx;

package App::Harmonograph::GUI::Board;
my $VERSION = 0.01;
use base qw/Wx::Panel/;
use Wx::Event qw(EVT_PAINT);

sub new {
    my ( $class, $parent, $x, $y ) = @_;
    my $self = $class->SUPER::new( $parent, -1, [-1,-1], [$x, $y] );
    # Wx::InitAllImageHandlers();
    
    EVT_PAINT( $self, \&paint_board );

    return $self;
}

sub paint_board {
    my( $self, $event ) = @_;
    my $dc = Wx::PaintDC->new( $self );
    my $gct = $self->{'grco'} = Wx::GraphicsContext::Create( $dc );
    my $path = $gct->CreatePath;
    my ($top, $left) = (12, 12);
    my $gridcol = Wx::Colour->new( 20, 20, 110 );
    $dc->SetPen(Wx::Pen->new( $gridcol, 3, &Wx::wxPENSTYLE_SOLID));
    $dc->DrawLine( $_, 13, $_,527) for 10, 169, 327, 486;
    $dc->DrawLine( 11, $_,484, $_) for 13, 186, 359, 528;
    $dc->SetPen(Wx::Pen->new( Wx::Colour->new(20, 20, 110), 1, &Wx::wxPENSTYLE_DOT));
    $dc->DrawLine( $_, 12, $_,527) for 65, 115, 223, 273, 381, 431;
    $dc->DrawLine( 10, $_,484, $_) for 72, 127, 245, 300, 418, 473;

    my $os = Wx::wxMAC() ? 1 : Wx::wxMSW() ? 3 : 2;

    my $candfond = Wx::Font->new(($os == 1 ? 12 : 10), &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_NORMAL, 0, 'Helvetica');
    $gct->SetFont( $gct->CreateFont( $candfond , Wx::Colour->new( 120, 120, 120 )));
    
    my $solfond = Wx::Font->new(($os == 1 ? 25 : 22), &Wx::wxFONTFAMILY_DEFAULT,&Wx::wxFONTSTYLE_NORMAL,&Wx::wxFONTWEIGHT_NORMAL,0,'Arial' );
    $gct->SetFont( $gct->CreateFont( $solfond , $gridcol));
    
    1;
}


1;
__END__

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



    $frame->{'label'}{'sol'}   = Wx::StaticText->new($frame, -1, 'Solved:',      [-1, -1], [44, 15], &Wx::wxALIGN_LEFT);
    $frame->{'label'}{'cand'}  = Wx::StaticText->new($frame, -1, 'Candidates:', [-1, -1], [69, 15], &Wx::wxALIGN_LEFT);
    $frame->{'label'}{'conflicts'}= Wx::StaticText->new($frame,-1,'Conflicts:',[-1, -1], [57, 15], &Wx::wxALIGN_LEFT);
    $frame->{'label'}{'state'} = Wx::StaticText->new($frame, -1, 'State:',    [-1, -1], [36, 15], &Wx::wxALIGN_LEFT);
    $frame->{'txt'}{'sol'}    = Wx::TextCtrl->new( $frame, -1, "0",          [-1,-1],[32,-1], &Wx::wxTE_READONLY|&Wx::wxTE_CENTRE);
    $frame->{'txt'}{'cand'}   = Wx::TextCtrl->new( $frame, -1, "729",       [-1,-1],[39,-1], &Wx::wxTE_READONLY|&Wx::wxTE_CENTRE);
    $frame->{'txt'}{'conflicts'} = Wx::TextCtrl->new( $frame, -1, "0",     [-1,-1],[26,-1], &Wx::wxTE_READONLY|&Wx::wxTE_CENTRE);
    $frame->{'txt'}{'state'}  = Wx::TextCtrl->new( $frame, -1, "new",     [-1,-1],[70,-1], &Wx::wxTE_READONLY|&Wx::wxTE_CENTRE);
	$frame->{'txt'}{'comment'}= Wx::TextCtrl->new( $frame, -1, "",       [-1,-1],[90,-1], &Wx::wxTE_READONLY|&Wx::wxTE_CENTRE);
    $frame->{'btn'}{'new'}    = Wx::Button->new( $frame, -1, '&New',    [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'open'}   = Wx::Button->new( $frame, -1, '&Open',   [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'save'}   = Wx::Button->new( $frame, -1, '&Save',   [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'exit'}   = Wx::ToggleButton->new($frame,-1,'&Exit',[-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'solve'}  = Wx::Button->new( $frame, -1, '&Solve',  [-1,-1],[$btnw, $btnh] );

    $frame->{'board'}         = Wx::Panel->new( $frame, -1, [-1,-1],[500,530]);
    $frame->{'board'}{'game'} = $frame->{'game'};
    $frame->{'list'}{'cand'}  = Wx::ListCtrl->new( $frame, -1, [-1,-1],[290,-1], &Wx::wxLC_ICON );
	$frame->{'list'}{'sol'}   = Wx::ListCtrl->new( $frame, -1, [-1,-1],[170,-1], &Wx::wxLC_ICON );
	$frame->{'list'}{'history'} = Wx::ListCtrl->new( $frame, -1, [-1,-1],[240,-1], &Wx::wxLC_ICON);
	Wx::ToolTip::Enable(1);
	$frame->{'list'}{'sol'}->SetToolTip('cells that can be solved with (row. column) : digit');
	$frame->{'list'}{'cand'}->SetToolTip('candidates that can be removed on (row. column) : digit');
	$frame->{'list'}{'history'}->SetToolTip('history of steps to solve current game');
	$frame->{'txt'}{'comment'}->SetToolTip('comment text of the selected solving step');
	$frame->{'btn'}{'open'}->SetToolTip('load image settings from a text file');
	$frame->{'btn'}{'save'}->SetToolTip('save image settings into text file');
	$frame->{'btn'}{'new'}->SetToolTip('start new empty game (previous gets lost)');
	$frame->{'btn'}{'exit'}->SetToolTip('close the application');
	$frame->{'btn'}{'solve'}->SetToolTip('solve whole gamewith forking algorithm (takes time for many solutions)');
	$frame->{'btn'}{'scand'}->SetToolTip('remove only candidate of selected step');
	$frame->{'btn'}{'ncand'}->SetToolTip('remove only next suggested candidate');
	$frame->{'btn'}{'scand'}->SetToolTip('remove only candidate of selected suggestion');
	$frame->{'btn'}{'acand'}->SetToolTip('remove all suggested candidates');
	$frame->{'btn'}{'nsol'}->SetToolTip('solve only with next suggested step');
	$frame->{'btn'}{'ssol'}->SetToolTip('solve only with selected step');
	$frame->{'btn'}{'asol'}->SetToolTip('solve with all suggested steps');

    EVT_PAINT( $frame->{'board'}, \&paint_board );
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
    EVT_BUTTON( $frame, $frame->{'btn'}{'new'},  sub {
        $frame->{'board'}{'game'} = $frame->{'game'} = Games::Sudoku::Solver::Strategy::Game->new();
        update_game( $frame );
        $frame->SetStatusText( "new game created", 0 );
    } );
    # EVT_TOGGLEBUTTON( $frame, $frame->{'btn'}{'edit'}, sub { $frame->{'editable'} = $_[1]->IsChecked() } );

    EVT_LIST_ITEM_SELECTED( $frame, $frame->{'list'}{'cand'}, sub {$frame->{'txt'}{'comment'}->SetValue($frame->{'game'}{'candidate_stack'}[ $_[1]->GetIndex() ][3]) } );
	EVT_LIST_ITEM_SELECTED( $frame, $frame->{'list'}{'sol'},   sub {$frame->{'txt'}{'comment'}->SetValue($frame->{'game'}{'solution_stack'}[ $_[1]->GetIndex() ][3])  });
	EVT_LIST_ITEM_SELECTED( $frame, $frame->{'list'}{'history'},sub {$frame->{'txt'}{'comment'}->SetValue($frame->{'game'}{'solving_steps'}[ $_[1]->GetIndex() ][4])  });

    my $board_state_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $board_state_sizer->Add( 1, 0, 0);
    for my $name (qw/sol cand conflicts state/){
        $board_state_sizer->Add( $frame->{'label'}{$name}, 0, &Wx::wxLEFT|&Wx::wxALIGN_CENTER_VERTICAL, 10 );
        $board_state_sizer->Add( $frame->{'txt'}{$name}, 0, &Wx::wxLEFT|&Wx::wxRIGHT, 3 );
	}
    $board_state_sizer->Add( 0, 0, &Wx::wxEXPAND| &Wx::wxGROW);

    my $board_cmd_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $board_cmd_sizer->Add( 5, 0, &Wx::wxEXPAND);
    $board_cmd_sizer->Add( $frame->{'btn'}{$_}, 0, &Wx::wxALL, 6 ) for qw/open save new edit solve undo redo/;
    $board_cmd_sizer->Insert( 3, 20, 0, 0);
    $board_cmd_sizer->Insert( 7, 20, 0, 0);
    $board_cmd_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

	my $board_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $board_sizer->Add( $board_state_sizer, 0, &Wx::wxTOP|&Wx::wxEXPAND, 10);
    $board_sizer->Add( $frame->{'board'}, 0, &Wx::wxEXPAND);
    $board_sizer->Add( 0, 4, 0);
    $board_sizer->Add( $board_cmd_sizer, 0, &Wx::wxTOP|&Wx::wxEXPAND, 5);
    $board_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);


    my $cslist_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $cslist_sizer->Add( $frame->{'list'}{'cand'}, 0, &Wx::wxEXPAND);
    $cslist_sizer->Add( $frame->{'list'}{'sol'}, 0, &Wx::wxLEFT|&Wx::wxEXPAND, 5);

	my $step_btn_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $step_btn_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    $step_btn_sizer->Add( $frame->{'btn'}{$_}, 0, &Wx::wxTOP|&Wx::wxBOTTOM|&Wx::wxLEFT, 10 ) for qw/ncand scand acand nsol ssol asol/;

	my $step_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	$step_sizer->Add( $cslist_sizer, 1, &Wx::wxEXPAND|&Wx::wxGROW, 0);
    $step_sizer->Add( $step_btn_sizer, 0, &Wx::wxTOP|&Wx::wxEXPAND, 5);

	my $list_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $list_sizer->Add( $step_sizer, 0, &Wx::wxEXPAND, 0);
	$list_sizer->Add( $frame->{'list'}{'history'}, 1, &Wx::wxLEFT|&Wx::wxEXPAND, 10);
    $list_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

	my $left_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	$left_sizer->Add( $frame->{'txt'}{'comment'}, 0, &Wx::wxTOP|&Wx::wxBOTTOM|&Wx::wxRIGHT|&Wx::wxEXPAND,10);
    $left_sizer->Add( $list_sizer, 1, &Wx::wxEXPAND|&Wx::wxGROW, 0);

    my $main_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $main_sizer->Add( $board_sizer, 0, &Wx::wxEXPAND, 0);
	$main_sizer->Add( $left_sizer, 0, &Wx::wxEXPAND, 0);
    $main_sizer->Add( 0, 0, &Wx::wxEXPAND|&Wx::wxGROW);

	$frame->SetSizer($main_sizer);
    $frame->SetAutoLayout( 1 ); # say $frame->GetSize->GetHeight, ' ', $frame->GetSize->GetWidth;
	$frame->{'btn'}{'solve'}->SetFocus;
	my $size = [1230,672];
    $frame->SetSize($size);
    $frame->SetMinSize($size);
    $frame->SetMaxSize($size);
	$frame->Show(1);
	$frame->CenterOnScreen();
	$app->SetTopWindow($frame);
	1;
}

sub paint_board {
    my( $self, $event ) = @_;
    my $dc = Wx::PaintDC->new( $self );
    my $gct = $self->{'grco'} = Wx::GraphicsContext::Create( $dc );
    my $path = $gct->CreatePath;
    my ($top, $left) = (12, 12);
    my $gridcol = Wx::Colour->new( 20, 20, 110 );
    $dc->SetPen(Wx::Pen->new( $gridcol, 3, &Wx::wxPENSTYLE_SOLID));
    $dc->DrawLine( $_, 13, $_,527) for 10, 169, 327, 486;
    $dc->DrawLine( 11, $_,484, $_) for 13, 186, 359, 528;
    $dc->SetPen(Wx::Pen->new( Wx::Colour->new(20, 20, 110), 1, &Wx::wxPENSTYLE_DOT));
    $dc->DrawLine( $_, 12, $_,527) for 65, 115, 223, 273, 381, 431;
    $dc->DrawLine( 10, $_,484, $_) for 72, 127, 245, 300, 418, 473;

    my $os = Wx::wxMAC() ? 1 : Wx::wxMSW() ? 3 : 2;

    my $candfond = Wx::Font->new(($os == 1 ? 12 : 10), &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_NORMAL, 0, 'Helvetica');
    $gct->SetFont( $gct->CreateFont( $candfond , Wx::Colour->new( 120, 120, 120 )));
    
    my $solfond = Wx::Font->new(($os == 1 ? 25 : 22), &Wx::wxFONTFAMILY_DEFAULT,&Wx::wxFONTSTYLE_NORMAL,&Wx::wxFONTWEIGHT_NORMAL,0,'Arial' );
    $gct->SetFont( $gct->CreateFont( $solfond , $gridcol));
    1;
}

sub reload_lists {
    my( $frame, $game ) = shift;
    $frame->{'list'}{'sol'}->DeleteAllItems();
    $frame->{'list'}{'sol'}->InsertStringItem( 0, "$_->[0],$_->[1] : $_->[2]") for reverse @{$frame->{'game'}{'solution_stack'}};
}

sub new_game {
    my( $frame ) = shift;
    
}

sub update_game {
    my( $frame, $game ) = shift;
    $frame->{'board'}->Refresh;
    reload_lists($frame);
    $frame->{'txt'}{'sol'}->SetValue( int $frame->{'game'}->progress() );
    $frame->{'txt'}{'cand'}->SetValue( int $frame->{'game'}->candidates() );
    $frame->{'txt'}{'conflicts'}->SetValue( $frame->{'game'}->conflicts() );
	$frame->{'txt'}{'comment'}->SetValue('');
    return $frame->{'txt'}{'state'}->SetValue( 'broken' ) unless $frame->{'game'}->consistent;
    return $frame->{'txt'}{'state'}->SetValue( 'stuck' )  if $frame->{'game'}->stuck;
    return $frame->{'txt'}{'state'}->SetValue( 'solved' ) if $frame->{'game'}->solved;
    $frame->{'txt'}{'state'}->SetValue( 'progress' );
}

sub OnQuit { my( $self, $event ) = @_; $self->Close( 1 ); }
sub OnExit { my $app = shift;  1; }

1;


__END__
