use v5.18;
use warnings;
use Wx;
use utf8;
use FindBin;

# fix circular pendulum
# speicher für farben,  state config
# X Y sync ?  undo ? additional pendulum ?

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
    $frame->{'file_base_cc'} = 1;

    my $btnw = 50; my $btnh = 40;# button width and height
    $frame->{'btn'}{'new'}    = Wx::Button->new( $frame, -1, '&New',    [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'open'}   = Wx::Button->new( $frame, -1, '&Open',   [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'write'}  = Wx::Button->new( $frame, -1, '&Write',  [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'dir'}  = Wx::Button->new( $frame, -1, 'Dir',   [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'write_next'} = Wx::Button->new( $frame, -1, '&Next', [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'draw'}   = Wx::Button->new( $frame, -1, '&Draw',   [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'save'}   = Wx::Button->new( $frame, -1, '&Save',   [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'save_next'}  = Wx::Button->new( $frame, -1, 'Ne&xt', [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'lstart'} = Wx::Button->new( $frame, -1, 'Load',    [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'sstart'} = Wx::Button->new( $frame, -1, 'Save',    [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'lend'}   = Wx::Button->new( $frame, -1, 'Load',    [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'send'}   = Wx::Button->new( $frame, -1, 'Save',    [-1,-1],[$btnw, $btnh] );
    #$frame->{'btn'}{'exit'}  = Wx::Button->new( $frame, -1, '&Exit',   [-1,-1],[$btnw, $btnh] );
    #$frame->{'btn'}{'tips'}  = Wx::ToggleButton->new($frame,-1,'&Tips',[-1,-1],[$btnw, $btnh] );
    $frame->{'txt'}{'file_base'} = Wx::TextCtrl->new($frame,-1, '', [-1,-1], [225, -1] );
    $frame->{'cmb'}{'last'}   = Wx::ComboBox->new( $frame, -1, 1, [-1,-1],[185, -1], [] );


    $frame->{'btn'}{'new'} ->SetToolTip('put all settings to default (start values)');
    $frame->{'btn'}{'open'}->SetToolTip('load image settings from a text file');
    $frame->{'btn'}{'write'}->SetToolTip('save image settings into text file');
    $frame->{'btn'}{'dir'}->SetToolTip('select directory and add later file base name (without ending) for a series of files in the text');
    $frame->{'btn'}{'write_next'}->SetToolTip('save current image settings into text file with name seen in text field with added number and file ending .ini');
    $frame->{'btn'}{'draw'}->SetToolTip('redraw the harmonographic image');
    $frame->{'btn'}{'save'}->SetToolTip('save image into SVG file');
    $frame->{'btn'}{'save_next'}->SetToolTip('save current image into SVG file with name seen in text field with added number and file ending .svg');
    #$frame->{'btn'}{'exit'}->SetToolTip('close the application');
    $frame->{'txt'}{'file_base'}->SetToolTip("file base name (without ending) for a series of files in the text\n 1. select directory via Dir button\n 2, add fila base name directly in text");

    $frame->{'pendulum'}{'x'}  = App::Harmonograph::GUI::Part::Pendulum->new( $frame, 'x','pendulum in x direction (left to right)', 1, 30);
    $frame->{'pendulum'}{'y'}  = App::Harmonograph::GUI::Part::Pendulum->new( $frame, 'y','pendulum in y direction (left to right)', 1, 30);
    $frame->{'pendulum'}{'z'}  = App::Harmonograph::GUI::Part::Pendulum->new( $frame, 'z','circular pendulum',        0, 30);
    $frame->{'pendulum'}{'r'}  = App::Harmonograph::GUI::Part::Pendulum->new( $frame, 'R','rotating pendulum',        0, 30);
    
    $frame->{'color'}{'start'} = App::Harmonograph::GUI::Part::Color->new( $frame, 'start', { red => 20, green => 20, blue => 110 } );
    $frame->{'color'}{'end'}   = App::Harmonograph::GUI::Part::Color->new( $frame, 'end',  { red => 110, green => 20, blue => 20 } );

    $frame->{'color_flow'} = App::Harmonograph::GUI::Part::ColorFlow->new( $frame );
    $frame->{'line'} = App::Harmonograph::GUI::Part::PenLine->new( $frame );

    $frame->{'board'}    = App::Harmonograph::GUI::Part::Board->new($frame, 600, 600);

    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'new'},  sub { init( $frame ) });
    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'open'}, sub { load_setting_file ( $frame) } );
    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'dir'},  sub { get_dir ($frame) } ) ;
    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'write'},sub { 
        my $dialog = Wx::FileDialog->new ( $frame, "Select a file name to store data", '.', '',
               ( join '|', 'INI files (*.ini)|*.ini', 'All files (*.*)|*.*' ), &Wx::wxFD_SAVE );
        write_settings_file( $frame, $dialog->GetPath) unless $dialog->ShowModal == &Wx::wxID_CANCEL; 
    });
    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'write_next'},  sub {
        my $base = $frame->{'txt'}{'file_base'}->GetValue();
        return $frame->{'txt'}{'file_base'}->SetFocus, $frame->SetStatusText( "please remove file ending", 0 ) if $base =~ /\./ and substr( $base, 0, 1) ne '.';
        return $frame->{'txt'}{'file_base'}->SetFocus, $frame->SetStatusText( "please add file name without ending", 0 ) if substr( $base, -1 ) eq '/';
        while (1){
            last unless -e $base.'_'.$frame->{'file_base_cc'}.'.ini';
            $frame->{'file_base_cc'}++;
        }
        my $data = get_data( $frame );
        $frame->{'file_base_cc'}++ unless hash_eq( $frame->{'last_file_settings'}, $data );
        write_settings_file( $frame, $base.'_'.$frame->{'file_base_cc'}.'.ini' );
        $frame->{'last_file_settings'} = $data;
    });
    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'save_next'},  sub {
        my $base = $frame->{'txt'}{'file_base'}->GetValue();
        return $frame->{'txt'}{'file_base'}->SetFocus, $frame->SetStatusText( "please remove file ending", 0 ) if $base =~ /\./ and substr( $base, 0, 1) ne '.';
        return $frame->{'txt'}{'file_base'}->SetFocus, $frame->SetStatusText( "please add file name without ending", 0 ) if substr( $base, -1 ) eq '/';
        while (1){
            last unless -e $base.'_'.$frame->{'file_base_cc'}.'.svg';
            $frame->{'file_base_cc'}++;
        }
        my $data = get_data( $frame );
        $frame->{'file_base_cc'}++ unless hash_eq( $frame->{'last_file_settings'}, $data );
        write_image( $frame, $base.'_'.$frame->{'file_base_cc'}.'.svg' );
        $frame->{'last_file_settings'} = $data;
    });
    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'draw'},  sub { draw( $frame ) });
    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'save'},  sub {
        my $dialog = Wx::FileDialog->new ( $frame, "select a file name to save image", '.', '',
                   ( join '|', 'SVG files (*.svg)|*.svg', 'All files (*.*)|*.*' ), &Wx::wxFD_SAVE );
        write_image( $frame, $dialog->GetPath ) unless $dialog->ShowModal == &Wx::wxID_CANCEL;
    });
    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'exit'},  sub { $frame->Close; } );


    my $std_attr = &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxALIGN_CENTER_HORIZONTAL;
    my $vert_attr = $std_attr | &Wx::wxTOP;
    my $horiz_attr = $std_attr | &Wx::wxLEFT;
    my $all_attr    = $std_attr | &Wx::wxALL;
    my $line_attr    = $std_attr | &Wx::wxLEFT | &Wx::wxRIGHT ;
    
    my $cmdi_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    my $image_lbl  = Wx::StaticText->new($frame, -1, 'Image:' );
    $cmdi_sizer->Add( $image_lbl,               0, $all_attr, 21 );
    $cmdi_sizer->Add( $frame->{'btn'}{'save'},   0, $all_attr, 10 );
    $cmdi_sizer->Add( $frame->{'btn'}{'dir'},     0, $all_attr, 10 );
    $cmdi_sizer->Add( $frame->{'txt'}{'file_base'},0, $all_attr, 10 );
    $cmdi_sizer->Add( $frame->{'btn'}{'save_next'}, 0, $all_attr, 10 );
    $cmdi_sizer->Add( $frame->{'btn'}{'draw'},      0, $all_attr, 10 );
    $cmdi_sizer->Add( 0, 0, 10);
    $cmdi_sizer->Add( Wx::StaticLine->new( $frame, -1, [-1,-1], [ 2, 46] ),  0, $horiz_attr, 0);
    $cmdi_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $cmds_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    my $settings_lbl  = Wx::StaticText->new($frame, -1, 'Settings:' );
    $cmds_sizer->Add( $settings_lbl,       0, $all_attr, 21 );
    $cmds_sizer->Add( $frame->{'btn'}{'new'},0, $all_attr, 10 );
    $cmds_sizer->Add( $frame->{'btn'}{'open'}, 0, $all_attr, 10 );
    $cmds_sizer->Add( $frame->{'cmb'}{'last'},   0, $all_attr, 10 );
    $cmds_sizer->Add( $frame->{'btn'}{'write'},    0, $all_attr, 10 );
    $cmds_sizer->Add( $frame->{'btn'}{'write_next'}, 0, $all_attr, 10 );
    $cmds_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);
    
    my $cmdc_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    my $scolor_lbl  = Wx::StaticText->new($frame, -1, 'Start Color:' );
    my $ecolor_lbl  = Wx::StaticText->new($frame, -1, 'End Color:' );
    $cmdc_sizer->Add( $scolor_lbl,                0, $all_attr, 21 );
    $cmdc_sizer->Add( $frame->{'btn'}{'lstart'}, 0, $all_attr, 10 );
    $cmdc_sizer->Add( $frame->{'btn'}{'sstart'}, 0, $all_attr, 10 );
    #$cmdc_sizer->Add( 0, 0, 500);
    $cmdc_sizer->Add( $ecolor_lbl,               0, $all_attr, 21 );
    $cmdc_sizer->Add( $frame->{'btn'}{'lend'},   0, $all_attr, 10 );
    $cmdc_sizer->Add( $frame->{'btn'}{'send'},   0, $all_attr, 10 );
    $cmdc_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $board_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $board_sizer->Add( $frame->{'board'}, 0, $all_attr,  10);
    $board_sizer->Add( $cmdi_sizer,       0, $vert_attr,  0);
    $board_sizer->Add( 0, 5);
    $board_sizer->Add( Wx::StaticLine->new( $frame, -1, [-1,-1], [ 125, 2] ),  0, $line_attr, 20);
    $board_sizer->Add( $cmds_sizer,       0, $vert_attr,  5);
    $board_sizer->Add( $cmdc_sizer,       0, $vert_attr,  5);
    $board_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $setting_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $setting_sizer->Add( $frame->{'pendulum'}{'x'},   0, $vert_attr, 20);
    $setting_sizer->Add( $frame->{'pendulum'}{'y'},   0, $vert_attr, 10);
    $setting_sizer->Add( $frame->{'pendulum'}{'z'},   0, $vert_attr, 10);
    $setting_sizer->Add( $frame->{'pendulum'}{'r'},   0, $vert_attr, 10);
    $setting_sizer->Add( Wx::StaticLine->new( $frame, -1, [-1,-1], [ 135, 2] ),  0, $vert_attr, 5);
    $setting_sizer->Add( $frame->{'line'},            0, $vert_attr, 10);
    $setting_sizer->Add( Wx::StaticLine->new( $frame, -1, [-1,-1], [ 135, 2] ),  0,$vert_attr, 10);
    $setting_sizer->Add( $frame->{'color_flow'},      0, $vert_attr, 15);
    $setting_sizer->Add( Wx::StaticLine->new( $frame, -1, [-1,-1], [ 135, 2] ),  0, $vert_attr, 10);
    $setting_sizer->Add( $frame->{'color'}{'start'},  0, $vert_attr, 10);
    $setting_sizer->Add( $frame->{'color'}{'end'},    0, $vert_attr, 20);
    $setting_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $main_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $main_sizer->Add( $board_sizer, 0, &Wx::wxEXPAND, 0);
    $main_sizer->Add( $setting_sizer, 0, &Wx::wxEXPAND|&Wx::wxLEFT, 10);
    $main_sizer->Add( 0, 0, &Wx::wxEXPAND);

    $frame->SetSizer($main_sizer);
    $frame->SetAutoLayout( 1 );
    $frame->{'btn'}{'draw'}->SetFocus;
    my $size = [1300, 1040];
    $frame->SetSize($size);
    $frame->SetMinSize($size);
    $frame->SetMaxSize($size);
    $frame->Show(1);
    $frame->CenterOnScreen();
    $app->SetTopWindow($frame);
    init( $frame );
    1;
}
sub OnQuit { my( $self, $event ) = @_; $self->Close( 1 ); }
sub OnExit { my $app = shift;  1; }

sub get_dir {
    my $frame = shift;
    my $dialog = Wx::DirDialog->new ( $frame, "Select a directory to store a series of files", '.');
    if( $dialog->ShowModal == &Wx::wxID_CANCEL ) {}
    else {
        my $path = $dialog->GetPath;
        my $i = index($path, $FindBin::Bin );
        $path = '.'.substr $path, length $FindBin::Bin if $i > -1;
        $i = index($path, $ENV{HOME} );
        $path = '~'.substr $path, length $ENV{HOME} if $i > -1;
        $path .= '/';
        $frame->{'txt'}{'file_base'}->SetValue( $path );
        $frame->{'file_base_cc'} = 1;
    }
}

sub get_data {
    my $frame = shift;
    { 
        x => $frame->{'pendulum'}{'x'}->get_data,
        y => $frame->{'pendulum'}{'y'}->get_data,
        z => $frame->{'pendulum'}{'z'}->get_data,
        r => $frame->{'pendulum'}{'r'}->get_data,
        start_color => $frame->{'color'}{'start'}->get_data,
        end_color => $frame->{'color'}{'end'}->get_data,
        color_flow => $frame->{'color_flow'}->get_data,
        line => $frame->{'line'}->get_data,
    }
}

sub set_data {
    my ($frame, $data) = @_;
    return unless ref $data eq 'HASH';
    $frame->{'pendulum'}{$_}->set_data( $data->{$_} ) for qw/x y z r/;
    $frame->{'color'}{$_}->set_data( $data->{ $_.'_color' } ) for qw/start end/;
    $frame->{ $_ }->set_data( $data->{ $_ } ) for qw/color_flow line/;
}

sub draw {
    my ($frame) = @_;
    $frame->SetStatusText( "drawing .....", 0 );
    $frame->{'board'}->set_data( get_data( $frame ) );
    $frame->{'board'}->Refresh;
    $frame->SetStatusText( "done drawing", 0 );
}
sub init {
    my ($frame) = @_;
    $frame->{'pendulum'}{$_}->init() for qw/x y z r/;
    $frame->{'color'}{$_}->init() for qw/start end/;
    $frame->{ $_ }->init() for qw/color_flow line/;
    draw( $frame );
}

sub load_setting_file {
    my $frame = shift;
    my $dialog = Wx::FileDialog->new ( $frame, "Select a settings file to load", '.', '',
                   ( join '|', 'INI files (*.ini)|*.ini', 'All files (*.*)|*.*' ), &Wx::wxFD_OPEN );
    unless( $dialog->ShowModal == &Wx::wxID_CANCEL ) {
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
        draw( $frame );
    }
}

sub write_settings_file {
    my ($frame, $file)  = @_;
    my $data = get_data($frame);
    open my $FH, '>', $file or return $frame->SetStatusText( "could not write $file: $!", 0 );
    for my $main_key (sort keys %$data){
        say $FH "\n  [$main_key]\n";
        my $subhash = $data->{$main_key};
        next unless ref $subhash eq 'HASH';
        for my $key (sort keys %$subhash){
            say $FH "$key = $subhash->{$key}";
        }
    }
    close $FH;
    $frame->SetStatusText( "saved settings into file $file", 0 );
}

sub write_image {
    my ($frame, $file)  = @_;
    $frame->{'board'}->save_file( $file );
    $frame->SetStatusText( "saved image under $file", 0 );
}

sub hash_eq {
    my ($h1, $h2)  = @_;
    return 0 unless ref $h1 eq 'HASH' and $h2 eq 'HASH';
    for my $key (keys %$h1){
        next if not ref $h1->{$key} and exists $h2->{$key} and not ref $h2->{$key} and $h1->{$key} eq $h2->{$key};
        next if hash_eq( $h1->{$key}, $h2->{$key} );
        return 0;
    }
}

1;

__END__

    #$frame->{'list'}{'sol'}->DeleteAllItems();
    #$frame->{'list'}{'sol'}->InsertStringItem( 0, "$_->[0],$_->[1] : $_->[2]") for reverse @{$frame->{'game'}{'solution_stack'}};
    #$frame->{'btn'}{'exit'}   = Wx::ToggleButton->new($frame,-1,'&Exit',[-1,-1],[$btnw, $btnh] );
    #$frame->{'list'}{'cand'}  = Wx::ListCtrl->new( $frame, -1, [-1,-1],[290,-1], &Wx::wxLC_ICON );
    # EVT_TOGGLEBUTTON( $frame, $frame->{'btn'}{'edit'}, sub { $frame->{'editable'} = $_[1]->IsChecked() } );
    # Wx::Event::EVT_LIST_ITEM_SELECTED( $frame, $frame->{'list'}{'cand'}, sub {$frame->{'txt'}{'comment'}->SetValue($frame->{'game'}{'candidate_stack'}[ $_[1]->GetIndex() ][3]) } );
    # Wx::InitAllImageHandlers();

    # Wx::Event::EVT_LEFT_DOWN( $frame->{'board'}, sub {  });
    # Wx::Event::EVT_RIGHT_DOWN( $frame->{'board'}, sub {
    #    my ($panel, $event) = @_;
    #    return unless $frame->{'editable'};
    #    my ($mx, $my) = ($event->GetX, $event->GetY);
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
