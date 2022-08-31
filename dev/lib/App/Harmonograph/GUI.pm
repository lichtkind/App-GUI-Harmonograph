use v5.18;
use warnings;
use Wx;
use utf8;

# Dyn end check
# X Y sync
# additional pendulum ?
# undo
# speicher für serien von graphiken und farben

package App::Harmonograph::GUI;
my $VERSION = 0.14;
use base qw/Wx::App/;
use App::Harmonograph::GUI::Part::Pendulum;
use App::Harmonograph::GUI::Part::ColorFlow;
use App::Harmonograph::GUI::Part::Color;
use App::Harmonograph::GUI::Part::PenLine;
use App::Harmonograph::GUI::Part::Board;

sub OnInit {
    my $app   = shift;
    my $frame = Wx::Frame->new( undef, -1, 'Harmonograph '.$VERSION , [-1,-1], [-1,-1]);
    $frame->SetIcon( Wx::GetWxPerlIcon() );
    $frame->CreateStatusBar( 2 );
    $frame->SetStatusWidths(2, 800, 100);
    $frame->SetStatusText( "Harmonograph", 1 );
    Wx::ToolTip::Enable(1);

    my $btnw = 50; my $btnh = 40;# button width and height
    $frame->{'btn'}{'new'}   = Wx::Button->new( $frame, -1, '&New',    [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'open'}  = Wx::Button->new( $frame, -1, '&Open',   [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'write'} = Wx::Button->new( $frame, -1, '&Write',  [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'write_next'} = Wx::Button->new( $frame, -1, '&Next',  [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'draw'}  = Wx::Button->new( $frame, -1, '&Draw',   [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'save'}  = Wx::Button->new( $frame, -1, '&Save',   [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'save_next'}  = Wx::Button->new( $frame, -1, 'Ne&xt',   [-1,-1],[$btnw, $btnh] );
    #$frame->{'btn'}{'exit'}  = Wx::Button->new( $frame, -1, '&Exit',   [-1,-1],[$btnw, $btnh] );
    #$frame->{'btn'}{'tips'}  = Wx::ToggleButton->new($frame,-1,'&Tips',[-1,-1],[$btnw, $btnh] );
    $frame->{'txt'}{'setting_base'} = Wx::TextCtrl->new($frame,-1, '',[-1,-1],[220, -1] );
    $frame->{'txt'}{'image_base'} = Wx::TextCtrl->new($frame,-1, '',[-1,-1],[220, -1] );

    $frame->{'btn'}{'new'} ->SetToolTip('put all settings to default');
    $frame->{'btn'}{'open'}->SetToolTip('load image settings from a text file');
    $frame->{'btn'}{'write'}->SetToolTip('save image settings into text file');
    $frame->{'btn'}{'write_next'}->SetToolTip('save current image settings into text file with name seen in text field with number added');
    $frame->{'btn'}{'draw'}->SetToolTip('redraw the harmonographic image');
    $frame->{'btn'}{'save'}->SetToolTip('save image into SVG file');
    $frame->{'btn'}{'save_next'}->SetToolTip('save current image into SVG file with name seen in text field with number added');
    #$frame->{'btn'}{'exit'}->SetToolTip('close the application');

    $frame->{'pendulum'}{'x'}  = App::Harmonograph::GUI::Part::Pendulum->new( $frame, 'x','pendulum in x direction (left to right)', 1, 30);
    $frame->{'pendulum'}{'y'}  = App::Harmonograph::GUI::Part::Pendulum->new( $frame, 'y','pendulum in y direction (left to right)', 1, 30);
    $frame->{'pendulum'}{'z'}  = App::Harmonograph::GUI::Part::Pendulum->new( $frame, 'z','circular pendulum in z direction',        0, 30);
    
    $frame->{'color'}{'start'} = App::Harmonograph::GUI::Part::Color->new( $frame, 'start', { red => 20, green => 20, blue => 110 } );
    $frame->{'color'}{'end'}   = App::Harmonograph::GUI::Part::Color->new( $frame, 'end',  { red => 110, green => 20, blue => 20 } );

    $frame->{'color_flow'} = App::Harmonograph::GUI::Part::ColorFlow->new( $frame );
    $frame->{'line'} = App::Harmonograph::GUI::Part::PenLine->new( $frame );

    $frame->{'board'}    = App::Harmonograph::GUI::Part::Board->new($frame, 600, 600);

    # Wx::Event::EVT_LEFT_DOWN( $frame->{'board'}, sub {  });
    #Wx::Event::EVT_RIGHT_DOWN( $frame->{'board'}, sub {
    #    my ($panel, $event) = @_;
    #    return unless $frame->{'editable'};
   #     my ($mx, $my) = ($event->GetX, $event->GetY);
    #    my $c = 1 + int(($mx - 15)/52);
    #    my $r = 1 + int(($my - 16)/57);
    #    return if $r < 1 or $r > 9 or $c < 1 or $c > 9;
    #    return if $frame->{'game'}->cell_solution( $r, $c );
    #    my $cand_menu = Wx::Menu->new();
    #    $cand_menu->AppendCheckItem($_,$_) for 1..9;
    #    my $nr;
    #    for (1 .. 9) {$cand_menu->Check($_, 1),$nr++ if $frame->{'game'}->is_cell_candidate($r,$c,$_) }
    #    return if $nr < 2;
    #    my $digit = $panel->GetPopupMenuSelectionFromUser( $cand_menu, $event->GetX, $event->GetY);
    #    return unless $digit > 0;
    #    $frame->{'game'}->remove_candidate($r, $c, $digit, 'set by app user');
    #});
    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'new'}, sub { $app->reset($frame) });
    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'open'}, sub {
        my $s = shift;
        my $dialog = Wx::FileDialog->new ( $frame, "Select a file", './beispiel', './beispiel/schwer.txt',
                   ( join '|', 'INI files (*.ini)|*.ini', 'All files (*.*)|*.*' ), &Wx::wxFD_OPEN|&Wx::wxFD_MULTIPLE );
        if( $dialog->ShowModal == &Wx::wxID_CANCEL ) {}
        else {
            my @paths = $dialog->GetPaths;
            open my $FH, '<', $paths[0] or return $frame->SetStatusText( "could not red $paths[0]", 0 );
            my $data = {};
            my $cat = '';
            while (<$FH>) {
                chomp;
                next unless $_ or substr( $_, 0, 1) eq '#';
                if    (/\s*\[(\w+)\]/)           { $cat = $1 }
                elsif (/\s*(\w+)\s*=\s*(.+)\s*$/){ $data->{$cat}{$1} = $2 }
            }
            close $FH;
            set_data( $frame, $data );
            $frame->SetStatusText( "loaded $paths[0]", 0 );
            $app->draw( $frame );
    }});
    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'write'},  sub {
        my $dialog = Wx::FileDialog->new ( $frame, "Select a file name to store data", '.', '',
                   ( join '|', 'INI files (*.ini)|*.ini', 'All files (*.*)|*.*' ), &Wx::wxFD_SAVE );
        if( $dialog->ShowModal != &Wx::wxID_CANCEL ) {
            my @paths = $dialog->GetPaths;
            open my $FH, '>', $paths[0] or return $frame->SetStatusText( "could not write $paths[0]", 0 );
            my $data = get_data($frame);
            for my $main_key (sort keys %$data){
                say $FH "\n  [$main_key]\n";
                my $subhash = $data->{$main_key};
                next unless ref $subhash eq 'HASH';
                for my $key (sort keys %$subhash){
                    say $FH "$key = $subhash->{$key}";
                }
            }
            close $FH;
            $frame->SetStatusText( "saved data into $paths[0]", 0 );
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

    my $cmd1_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $cmd1_sizer->Add( 5, 0, &Wx::wxEXPAND);
    $cmd1_sizer->Add( $frame->{'btn'}{'new'}, 0, &Wx::wxGROW|&Wx::wxALL, 10 );
    $cmd1_sizer->Add( $frame->{'btn'}{'open'}, 0, &Wx::wxGROW|&Wx::wxALL, 10 );
    $cmd1_sizer->Add( $frame->{'btn'}{'write'}, 0, &Wx::wxGROW|&Wx::wxALL, 10 );
    $cmd1_sizer->Add( $frame->{'btn'}{'write_next'}, 0, &Wx::wxGROW|&Wx::wxALL, 10 );
    $cmd1_sizer->Add( $frame->{'txt'}{'setting_base'}, 0, &Wx::wxGROW|&Wx::wxALL|&Wx::wxALIGN_CENTER_HORIZONTAL, 10 );
    $cmd1_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);
    
    my $cmd2_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $cmd2_sizer->Add( 5, 0, &Wx::wxEXPAND);
    $cmd2_sizer->Add( $frame->{'btn'}{'save'}, 0, &Wx::wxGROW|&Wx::wxALL, 10 );
    $cmd2_sizer->Add( $frame->{'btn'}{'save_next'}, 0, &Wx::wxGROW|&Wx::wxALL, 10 );
    $cmd2_sizer->Add( $frame->{'txt'}{'image_base'}, 0, &Wx::wxGROW|&Wx::wxALL|&Wx::wxALIGN_CENTER_HORIZONTAL, 10 );
    $cmd2_sizer->Add( $frame->{'btn'}{'draw'}, 0, &Wx::wxGROW|&Wx::wxALL, 10 );
    $cmd2_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);
    

    my $board_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $board_sizer->Add( $frame->{'board'}, 0, &Wx::wxGROW|&Wx::wxALL, 10);
    $board_sizer->Add( $cmd1_sizer,        0, &Wx::wxEXPAND, 0);
    $board_sizer->Add( $cmd2_sizer,        0, &Wx::wxEXPAND, 0);
    $board_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $s_attr = &Wx::wxALIGN_LEFT|&Wx::wxEXPAND|&Wx::wxGROW|&Wx::wxTOP;
    my $setting_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $setting_sizer->Add( $frame->{'pendulum'}{'x'},   0, $s_attr, 20);
    $setting_sizer->Add( $frame->{'pendulum'}{'y'},   0, $s_attr, 10);
    $setting_sizer->Add( $frame->{'pendulum'}{'z'},   0, $s_attr, 10);
    $setting_sizer->Add( Wx::StaticLine->new( $frame, -1, [-1,-1], [ 135, 2] ),  0, $s_attr|&Wx::wxALIGN_CENTER_HORIZONTAL, 10);
    $setting_sizer->Add( $frame->{'line'},            0, $s_attr, 10);
    $setting_sizer->Add( Wx::StaticLine->new( $frame, -1, [-1,-1], [ 135, 2] ),  0, $s_attr|&Wx::wxALIGN_CENTER_HORIZONTAL, 10);
    $setting_sizer->Add( $frame->{'color_flow'},      0, $s_attr, 15);
    $setting_sizer->Add( Wx::StaticLine->new( $frame, -1, [-1,-1], [ 135, 2] ),  0, $s_attr|&Wx::wxALIGN_CENTER_HORIZONTAL, 10);
    $setting_sizer->Add( $frame->{'color'}{'start'},  0, $s_attr, 10);
    $setting_sizer->Add( $frame->{'color'}{'end'},    0, $s_attr, 10);
    $setting_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $main_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $main_sizer->Add( $board_sizer, 0, &Wx::wxEXPAND, 0);
    $main_sizer->Add( $setting_sizer, 0, &Wx::wxEXPAND|&Wx::wxLEFT, 10);
    $main_sizer->Add( 0, 0, &Wx::wxEXPAND);

    $frame->SetSizer($main_sizer);
    $frame->SetAutoLayout( 1 );
    $frame->{'btn'}{'draw'}->SetFocus;
    my $size = [1300, 900];
    $frame->SetSize($size);
    $frame->SetMinSize($size);
    $frame->SetMaxSize($size);
    $frame->Show(1);
    $frame->CenterOnScreen();
    $app->SetTopWindow($frame);
    $app->reset( $frame );
    1;
}

sub get_data {
    my $frame = shift;
    { 
        x => $frame->{'pendulum'}{'x'}->get_data,
        y => $frame->{'pendulum'}{'y'}->get_data,
        z => $frame->{'pendulum'}{'z'}->get_data,
        start_color => $frame->{'color'}{'start'}->get_data,
        end_color => $frame->{'color'}{'end'}->get_data,
        color_flow => $frame->{'color_flow'}->get_data,
        line => $frame->{'line'}->get_data,
    }
}

sub set_data {
    my ($frame, $data) = @_;
    return unless ref $data eq 'HASH';
    $frame->{'pendulum'}{$_}->set_data( $data->{$_} ) for qw/x y z/;
    $frame->{'color'}{$_}->set_data( $data->{ $_.'_color' } ) for qw/start end/;
    $frame->{ $_ }->set_data( $data->{ $_ } ) for qw/color_flow line/;
}

sub draw {
    my ($app, $frame) = @_;
    $frame->SetStatusText( "drawing .....", 0 );
    $frame->{'board'}->set_data( get_data( $frame ) );
    $frame->{'board'}->Refresh;
    $frame->SetStatusText( "done drawing", 0 );
}
sub reset {
    my ($app, $frame) = @_;
    $frame->{'pendulum'}{$_}->init() for qw/x y z/;
    $frame->{'color'}{$_}->init() for qw/start end/;
    $frame->{ $_ }->init() for qw/color_flow line/;
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
    # Wx::InitAllImageHandlers();
