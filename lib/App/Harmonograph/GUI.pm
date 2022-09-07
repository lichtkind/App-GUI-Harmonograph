use v5.12;
use warnings;
use utf8;

# state config save PNG
# overwrite protection
#   
# X Y sync ? , undo ?

package App::Harmonograph::GUI;
use base qw/Wx::Frame/;
use App::Harmonograph::GUI::Part::Pendulum;
use App::Harmonograph::GUI::Part::ColorFlow;
use App::Harmonograph::GUI::Part::ColorBrowser;
use App::Harmonograph::GUI::Part::ColorPicker;
use App::Harmonograph::GUI::Part::PenLine;
use App::Harmonograph::GUI::Part::Board;
use App::Harmonograph::Settings;
use App::Harmonograph::Config;

sub new {
    my ( $class, $parent, $title ) = @_;
    my $self = $class->SUPER::new( $parent, -1, $title );
    $self->SetIcon( Wx::GetWxPerlIcon() );
    $self->CreateStatusBar( 2 );
    $self->SetStatusWidths(2, 800, 100);
    $self->SetStatusText( "no file loaded", 1 );
    $self->{'config'} = App::Harmonograph::Config->new();
    Wx::ToolTip::Enable( $self->{'config'}->get_value('tips') );
    Wx::InitAllImageHandlers();

    my $btnw = 50; my $btnh     = 40;# button width and height
    $self->{'btn'}{'new'}       = Wx::Button->new( $self, -1, '&New',  [-1,-1],[$btnw, $btnh] );
    $self->{'btn'}{'open'}      = Wx::Button->new( $self, -1, '&Open', [-1,-1],[$btnw, $btnh] );
    $self->{'btn'}{'write'}     = Wx::Button->new( $self, -1, '&Write',[-1,-1],[$btnw, $btnh] );
    $self->{'btn'}{'dir'}       = Wx::Button->new( $self, -1, 'Dir',   [-1,-1],[$btnw, $btnh] );
    $self->{'btn'}{'write_next'}= Wx::Button->new( $self, -1, '&Next', [-1,-1],[$btnw, $btnh] );
    $self->{'btn'}{'draw'}      = Wx::Button->new( $self, -1, '&Draw', [-1,-1],[$btnw, $btnh] );
    $self->{'btn'}{'save'}      = Wx::Button->new( $self, -1, '&Save', [-1,-1],[$btnw, $btnh] );
    $self->{'btn'}{'save_next'} = Wx::Button->new( $self, -1, 'Ne&xt', [-1,-1],[$btnw, $btnh] );
    $self->{'btn'}{'tips'}      = Wx::ToggleButton->new( $self, -1,'&Tool Tips',[-1,-1],[-1, $btnh], 1 );
    $self->{'btn'}{'tips'}->SetValue( $self->{'config'}->get_value('tips') );
    $self->{'btn'}{'knobs'}     = Wx::Button->new( $self, -1, '&Knobs',[-1,-1], [-1, $btnh] );
    $self->{'btn'}{'math'}      = Wx::Button->new( $self, -1, '&Function',[-1,-1], [-1, $btnh] );
    $self->{'btn'}{'about'}     = Wx::Button->new( $self, -1, '&About',[-1,-1], [-1, $btnh] );
    $self->{'btn'}{'exit'}      = Wx::Button->new( $self, -1, '&Exit', [-1,-1],[$btnw, $btnh] );
    $self->{'txt'}{'file_bname'}= Wx::TextCtrl->new( $self,-1, $self->{'config'}->get_value('file_base_name'), [-1,-1], [170, -1] );
    $self->{'txt'}{'file_bnr'}  = Wx::TextCtrl->new( $self,-1, $self->{'config'}->get_value('file_base_counter'), [-1,-1], [ 36, -1], &Wx::wxTE_READONLY );
    $self->{'cmb'}{'last'}      = Wx::ComboBox->new( $self,-1, 'select settings file to load', [-1,-1], [225, -1], $self->{'config'}{'data'}{'last_settings'} );

    $self->{'btn'}{'new'} ->SetToolTip('put all settings to default (start values)');
    $self->{'btn'}{'open'}->SetToolTip('load image settings from a text file');
    $self->{'btn'}{'write'}->SetToolTip('save image settings into text file');
    $self->{'btn'}{'dir'}->SetToolTip('directory to save file series: '.$self->{'config'}->get_value('file_base_dir'));
    $self->{'btn'}{'write_next'}->SetToolTip('save current image settings into text file with name seen in text field with added number and file ending .ini');
    $self->{'btn'}{'draw'}->SetToolTip('redraw the harmonographic image');
    $self->{'btn'}{'save'}->SetToolTip('save image into SVG file');
    $self->{'btn'}{'save_next'}->SetToolTip('save current image into SVG file with name seen in text field with added number and file ending .svg');
    $self->{'btn'}{'tips'}->SetToolTip('you can read this tool tip because the toggle button below is switched on');
    $self->{'btn'}{'knobs'}->SetToolTip('explaining the layout of the program - what knob does what');
    $self->{'btn'}{'math'}->SetToolTip('explaining the math behind the knobs');
    $self->{'btn'}{'about'}->SetToolTip('introduction and overview text');
    $self->{'btn'}{'exit'}->SetToolTip('close the application');
    $self->{'txt'}{'file_bname'}->SetToolTip("file base name (without ending) for a series of files you save (settings and images)");
    $self->{'txt'}{'file_bnr'}->SetToolTip("index of file base name,\nwhen pushing Next button, image or settings are saved under Dir + File + Index + Ending");
    $self->{'cmb'}{'last'}->SetToolTip("last saved configuration, select to reload them");

    $self->{'pendulum'}{'x'}  = App::Harmonograph::GUI::Part::Pendulum->new( $self, 'x','pendulum in x direction (left to right)', 1, 30);
    $self->{'pendulum'}{'y'}  = App::Harmonograph::GUI::Part::Pendulum->new( $self, 'y','pendulum in y direction (left to right)', 1, 30);
    $self->{'pendulum'}{'z'}  = App::Harmonograph::GUI::Part::Pendulum->new( $self, 'z','circular pendulum',        0, 30);
    $self->{'pendulum'}{'r'}  = App::Harmonograph::GUI::Part::Pendulum->new( $self, 'R','rotating pendulum',        0, 30);
    
    $self->{'color'}{'start'} = App::Harmonograph::GUI::Part::ColorBrowser->new( $self, 'start', { red => 20, green => 20, blue => 110 } );
    $self->{'color'}{'end'}   = App::Harmonograph::GUI::Part::ColorBrowser->new( $self, 'end',  { red => 110, green => 20, blue => 20 } );
    
    $self->{'color'}{'startio'} = App::Harmonograph::GUI::Part::ColorPicker->new( $self, 'Start Color', $self->{'config'}->get_value('color') , 162, 1);
    $self->{'color'}{'endio'}   = App::Harmonograph::GUI::Part::ColorPicker->new( $self, 'End Color', $self->{'config'}->get_value('color') , 162, 7);

    $self->{'color_flow'} = App::Harmonograph::GUI::Part::ColorFlow->new( $self );
    $self->{'line'} = App::Harmonograph::GUI::Part::PenLine->new( $self );

    $self->{'board'}    = App::Harmonograph::GUI::Part::Board->new($self, 600, 600);



    Wx::Event::EVT_COMBOBOX( $self, $self->{'cmb'}{'last'}, sub { 
        my $path = $_[1]->GetString;
        $path = App::Harmonograph::Settings::expand_path( $path );
        return $self->SetStatusText( "could not find file: ".$path, 0 ) unless -r $path;
        $self->open_setting_file( $path );
        $self->SetStatusText( "loaded settings from ".$path, 1) 
    });
    Wx::Event::EVT_TOGGLEBUTTON( $self, $self->{'btn'}{'tips'},  sub { Wx::ToolTip::Enable( $_[1]->IsChecked ) });

    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'new'},  sub { $self->init });
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'open'}, sub { 
        my $dialog = Wx::FileDialog->new ( $self, "Select a settings file to load", $self->{'config'}->get_value('open_dir'), '',
                   ( join '|', 'INI files (*.ini)|*.ini', 'All files (*.*)|*.*' ), &Wx::wxFD_OPEN );
        return if $dialog->ShowModal == &Wx::wxID_CANCEL;
        my $path = $dialog->GetPath;
        my $ret = $self->open_setting_file ( $path );
        if (not ref $ret) { $self->SetStatusText( $ret, 0) }
        else { 
            my $dir = App::Harmonograph::Settings::extract_dir( $path );
            $self->{'config'}->set_value('save_dir', $dir);
            $self->SetStatusText( "loaded settings from ".$dialog->GetPath, 1) 
        }
    });
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'dir'},  sub { $self->get_dir }) ;
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'write'},sub { 
        my $dialog = Wx::FileDialog->new ( $self, "Select a file name to store data",$self->{'config'}->get_value('write_dir'), '',
               ( join '|', 'INI files (*.ini)|*.ini', 'All files (*.*)|*.*' ), &Wx::wxFD_SAVE );
        return if $dialog->ShowModal == &Wx::wxID_CANCEL;
        my $path = $dialog->GetPath;
        #my $i = rindex $path, '.';
        #$path = substr($path, 0, $i - 1 ) if $i > -1;
        #$path .= '.ini' unless lc substr ($path, -4) eq '.ini';
        $self->write_settings_file( $path );
        my $dir = App::Harmonograph::Settings::extract_dir( $path );
        $self->{'config'}->set_value('write_dir', $dir);
        $path = App::Harmonograph::Settings::shrink_path( $path);
        $self->{'config'}->add_setting_file( $path );
        $self->update_last_saved();
        $self->{'cmb'}{'last'}->SetSelection( $self->{'cmb'}{'last'}->GetCount() );
    });
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'write_next'},  sub {
        my $base = $self->{'txt'}{'file_base'}->GetValue();
        return $self->{'txt'}{'file_base'}->SetFocus, $self->SetStatusText( "please remove file ending", 0 ) if $base =~ /\./ and substr( $base, 0, 1) ne '.';
        return $self->{'txt'}{'file_base'}->SetFocus, $self->SetStatusText( "please add file name without ending", 0 ) if substr( $base, -1 ) eq '/';
        while (1){
            last unless -e $base.'_'.$self->{'file_base_cc'}.'.ini';
            $self->{'file_base_cc'}++;
        }
        my $data = get_data( $self );
        $self->{'file_base_cc'}++ unless App::Harmonograph::Settings::are_equal( $self->{'last_file_settings'}, $data );
        write_settings_file( $self, $base.'_'.$self->{'file_base_cc'}.'.ini' );
        $self->{'last_file_settings'} = $data;
        $self->update_last_saved();
    });
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'save_next'},  sub {
        my $base = $self->{'txt'}{'file_base'}->GetValue();
        return $self->{'txt'}{'file_base'}->SetFocus, $self->SetStatusText( "please remove file ending", 0 ) if $base =~ /\./ and substr( $base, 0, 1) ne '.';
        return $self->{'txt'}{'file_base'}->SetFocus, $self->SetStatusText( "please add file name without ending", 0 ) if substr( $base, -1 ) eq '/';
        while (1){
            last unless -e $base.'_'.$self->{'file_base_cc'}.'.svg';
            $self->{'file_base_cc'}++;
        }
        my $data = get_data( $self );
        $self->{'file_base_cc'}++ unless App::Harmonograph::Settings::are_equal( $self->{'last_file_settings'}, $data );
        write_image( $self, $base.'_'.$self->{'file_base_cc'}.'.svg' );
        $self->{'last_file_settings'} = $data;
    });
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'draw'},  sub { draw( $self ) });
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'save'},  sub {
        my $dialog = Wx::FileDialog->new ( $self, "select a file name to save image", $self->{'config'}->get_value('save_dir'), '',
                   ( join '|', 'SVG files (*.svg)|*.svg', 'All files (*.*)|*.*' ), &Wx::wxFD_SAVE );
        return if $dialog->ShowModal == &Wx::wxID_CANCEL;
        my $path = $dialog->GetPath;
        $self->write_image( $path );
        my $dir = App::Harmonograph::Settings::extract_dir( $path );
        $self->{'config'}->set_value('save_dir', $dir);
    });
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'exit'},  sub { $self->Close; } );
    Wx::Event::EVT_CLOSE( $self, sub {$self->{'config'}->save(); $_[1]->Skip(1) });

    my $std_attr = &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxALIGN_CENTER_HORIZONTAL;
    my $vert_attr = $std_attr | &Wx::wxTOP;
    my $vset_attr = $std_attr | &Wx::wxTOP| &Wx::wxBOTTOM;
    my $horiz_attr = $std_attr | &Wx::wxLEFT;
    my $all_attr    = $std_attr | &Wx::wxALL;
    my $line_attr    = $std_attr | &Wx::wxLEFT | &Wx::wxRIGHT ;
    
    my $cmdi_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    my $image_lbl = Wx::StaticText->new( $self, -1, 'Image:' );
    $cmdi_sizer->Add( $image_lbl,     0, $all_attr, 20 );
    $cmdi_sizer->AddSpacer( 12 );
    $cmdi_sizer->Add( $self->{'btn'}{'save'},      0, $vset_attr,10 );
    $cmdi_sizer->Add( $self->{'btn'}{'dir'},       0, $all_attr, 10 );
    $cmdi_sizer->Add( $self->{'txt'}{'file_bname'},0, $all_attr, 10 );
    $cmdi_sizer->Add( $self->{'txt'}{'file_bnr'},  0, $all_attr, 10 );
    $cmdi_sizer->Add( $self->{'btn'}{'save_next'}, 0, $all_attr, 10 );
    $cmdi_sizer->Add( $self->{'btn'}{'draw'},      0, $all_attr, 10 );
    $cmdi_sizer->AddSpacer( 10 );
    $cmdi_sizer->Add( Wx::StaticLine->new( $self, -1, [-1,-1], [ 2, 46] ),  0, $horiz_attr, 0);
    $cmdi_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $cmds_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    my $settings_lbl  = Wx::StaticText->new( $self, -1, 'Settings:' );
    $cmds_sizer->Add( $settings_lbl,       0, $all_attr, 20 );
    $cmds_sizer->Add( $self->{'btn'}{'new'},0, $vset_attr, 10 );
    $cmds_sizer->Add( $self->{'btn'}{'open'}, 0, $all_attr, 10 );
    $cmds_sizer->Add( $self->{'cmb'}{'last'},   0, $all_attr, 10 );
    $cmds_sizer->Add( $self->{'btn'}{'write_next'}, 0, $all_attr, 10 );
    $cmds_sizer->Add( $self->{'btn'}{'write'},    0, $all_attr, 10 );
    $cmds_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $help_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    my $help_lbl  = Wx::StaticText->new($self, -1, 'Help:' );
    $help_sizer->Add( $help_lbl,              0, $all_attr,  20 );
    $help_sizer->AddSpacer( 4 );
    $help_sizer->Add( $self->{'btn'}{'tips'}, 0, $all_attr,  10 );
    $help_sizer->Add( $self->{'btn'}{'about'}, 0, $all_attr,  10 );
    $help_sizer->Add( $self->{'btn'}{'knobs'}, 0, $all_attr,  10 );
    $help_sizer->Add( $self->{'btn'}{'math'}, 0, $all_attr,  10 );
    $help_sizer->Add( $self->{'btn'}{'exit'}, 0, $all_attr,  10 );
    $help_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $board_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $board_sizer->Add( $self->{'board'}, 0, $all_attr,  10);
    $board_sizer->Add( $cmdi_sizer,      0, $vert_attr,  5);
    $board_sizer->Add( 0, 5);
    $board_sizer->Add( Wx::StaticLine->new( $self, -1, [-1,-1], [ 125, 2] ),  0, $line_attr, 20);
    $board_sizer->Add( $cmds_sizer,       0, $vert_attr,  5);
    $board_sizer->Add( $self->{'color'}{'startio'}, 0, $vert_attr,  5);
    $board_sizer->Add( $self->{'color'}{'endio'},   0, $vert_attr,  5);
    $board_sizer->Add( 0, 5);
    $board_sizer->Add( Wx::StaticLine->new( $self, -1, [-1,-1], [ 125, 2] ),  0, $line_attr, 20);
    $board_sizer->Add( $help_sizer,       0, $vert_attr,  10);
    $board_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $setting_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $setting_sizer->Add( $self->{'pendulum'}{'x'},   0, $vert_attr, 20);
    $setting_sizer->Add( $self->{'pendulum'}{'y'},   0, $vert_attr, 10);
    $setting_sizer->Add( $self->{'pendulum'}{'z'},   0, $vert_attr, 10);
    $setting_sizer->Add( $self->{'pendulum'}{'r'},   0, $vert_attr, 10);
    $setting_sizer->Add( Wx::StaticLine->new( $self, -1, [-1,-1], [ 135, 2] ),  0, $vert_attr,  5);
    $setting_sizer->Add( $self->{'line'},             0, $vert_attr, 10);
    $setting_sizer->Add( Wx::StaticLine->new( $self, -1, [-1,-1], [ 135, 2] ),  0, $vert_attr, 10);
    $setting_sizer->Add( $self->{'color_flow'},       0, $vert_attr, 15);
    $setting_sizer->Add( Wx::StaticLine->new( $self, -1, [-1,-1], [ 135, 2] ),  0, $vert_attr, 10);
    $setting_sizer->Add( $self->{'color'}{'start'},   0, $vert_attr, 10);
    $setting_sizer->Add( $self->{'color'}{'end'},     0, $vert_attr, 20);
    $setting_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $main_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $main_sizer->Add( $board_sizer, 0, &Wx::wxEXPAND, 0);
    $main_sizer->Add( $setting_sizer, 0, &Wx::wxEXPAND|&Wx::wxLEFT, 10);
    $main_sizer->Add( 0, 0, &Wx::wxEXPAND);

    $self->SetSizer($main_sizer);
    $self->SetAutoLayout( 1 );
    $self->{'btn'}{'draw'}->SetFocus;
    my $size = [1300, 1040];
    $self->SetSize($size);
    $self->SetMinSize($size);
    $self->SetMaxSize($size);
    $self->init();
    $self;
}

sub init {
    my ($self) = @_;
    $self->{'pendulum'}{$_}->init() for qw/x y z r/;
    $self->{'color'}{$_}->init() for qw/start end/;
    $self->{ $_ }->init() for qw/color_flow line/;
    $self->draw( );
}

sub get_data {
    my $self = shift;
    { 
        x => $self->{'pendulum'}{'x'}->get_data,
        y => $self->{'pendulum'}{'y'}->get_data,
        z => $self->{'pendulum'}{'z'}->get_data,
        r => $self->{'pendulum'}{'r'}->get_data,
        start_color => $self->{'color'}{'start'}->get_data,
        end_color => $self->{'color'}{'end'}->get_data,
        color_flow => $self->{'color_flow'}->get_data,
        line => $self->{'line'}->get_data,
    }
}

sub set_data {
    my ($self, $data) = @_;
    return unless ref $data eq 'HASH';
    $self->{'pendulum'}{$_}->set_data( $data->{$_} ) for qw/x y z r/;
    $self->{'color'}{$_}->set_data( $data->{ $_.'_color' } ) for qw/start end/;
    $self->{ $_ }->set_data( $data->{ $_ } ) for qw/color_flow line/;
}

sub draw {
    my ($self) = @_;
    $self->SetStatusText( "drawing .....", 0 );
    $self->{'board'}->set_data( $self->get_data );
    $self->{'board'}->Refresh;
    $self->SetStatusText( "done drawing", 0 );
}

sub update_last_saved {
    my ($self) = @_;
    my $files = $self->{'config'}->get_value('last_settings');
    $self->{'cmb'}{'last'}->Clear ();
    $self->{'cmb'}{'last'}->Append( $_) for @$files; 
}

sub open_setting_file {
    my ($self, $path) = @_;
    my $data = App::Harmonograph::Settings::load( $path );
    return $data unless ref $data;
    $self->set_data( $data );
    $self->draw;
    my $dir = App::Harmonograph::Settings::extract_dir( $path );
    $self->{'config'}->set_value('open_dir', $dir);
    $data;
}

sub get_dir {
    my $self = shift;
    my $dialog = Wx::DirDialog->new ( $self, "Select a directory to store a series of files", $self->{'config'}->get_value('file_base_dir'));
    return if $dialog->ShowModal == &Wx::wxID_CANCEL;
    my $path = $dialog->GetPath;
    $path = App::Harmonograph::Settings::shrink_path( $path ) . '/';
    $self->{'btn'}{'dir'}->SetToolTip('directory to save file series: '.$path);
    $self->{'config'}->set_value('file_base_dir', $path);
    $self->{'config'}->set_value('file_base_counter', 1);
    $self->{'txt'}{'file_bnr'}->SetValue(1);
}

sub write_settings_file {
    my ($self, $file)  = @_;
    my $ret = App::Harmonograph::Settings::write( $file, $self->get_data );
    if ($ret){ $self->SetStatusText( $ret, 0 ) }
    else     { $self->SetStatusText( "saved settings into file $file", 1 ) }
}

sub write_image {
    my ($self, $file)  = @_;
    $self->{'board'}->save_file( $file );
    $self->SetStatusText( "saved image under $file", 0 );
}



1;

__END__

    #$self->{'list'}{'sol'}->DeleteAllItems();
    #$self->{'list'}{'sol'}->InsertStringItem( 0, "$_->[0],$_->[1] : $_->[2]") for reverse @{$self->{'game'}{'solution_stack'}};
    #$self->{'list'}{'cand'}  = Wx::ListCtrl->new( $self, -1, [-1,-1],[290,-1], &Wx::wxLC_ICON );
   # Wx::Event::EVT_LIST_ITEM_SELECTED( $self, $self->{'list'}{'cand'}, sub {$self->{'txt'}{'comment'}->SetValue($self->{'game'}{'candidate_stack'}[ $_[1]->GetIndex() ][3]) } );

    # Wx::Event::EVT_LEFT_DOWN( $self->{'board'}, sub {  });
    # Wx::Event::EVT_RIGHT_DOWN( $self->{'board'}, sub {
    #    my ($panel, $event) = @_;
    #    return unless $self->{'editable'};
    #    my ($mx, $my) = ($event->GetX, $event->GetY);
    #    my $c = 1 + int(($mx - 15)/52);
    #    my $r = 1 + int(($my - 16)/57);
    #    return if $r < 1 or $r > 9 or $c < 1 or $c > 9;
    #    return if $self->{'game'}->cell_solution( $r, $c );
    #    my $cand_menu = Wx::Menu->new();
    #    $cand_menu->AppendCheckItem($_,$_) for 1..9;
    #    my $nr;
    #    for (1 .. 9) {$cand_menu->Check($_, 1),$nr++ if $self->{'game'}->is_cell_candidate($r,$c,$_) }
    #    return if $nr < 2;
    #    my $digit = $panel->GetPopupMenuSelectionFromUser( $cand_menu, $event->GetX, $event->GetY);
    #    return unless $digit > 0;
    #    $self->{'game'}->remove_candidate($r, $c, $digit, 'set by app user');
    #});
