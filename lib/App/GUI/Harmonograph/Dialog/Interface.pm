use v5.12;
use warnings;
use Wx;

package App::GUI::Harmonograph::Dialog::Interface;
use base qw/Wx::Dialog/;

sub new {
    my ( $class, $parent) = @_;
    my $self = $class->SUPER::new( $parent, -1, 'Which Knob does what?' );

    my @lblb_pro = ( [-1,-1], [-1,-1], &Wx::wxALIGN_CENTRE_HORIZONTAL );
    my $layout  = Wx::StaticText->new( $self, -1, 'The general layout of the program has three parts, which flow from the position of the drawing board.');
    my $layout1 = Wx::StaticText->new( $self, -1, '1. In the left upper corner is the drawing board - showing the result of the Harmonograph.');
    my $layout2 = Wx::StaticText->new( $self, -1, '2. The whole right half of the window contains the settings, which guide the drawing operation.');
    my $layout3 = Wx::StaticText->new( $self, -1, '3. The lower left side contains buttons which are commands, mostly for in and output of data.' );
    my $layout4 = Wx::StaticText->new( $self, -1, 'Please mind the tool tips - short help texts which appear if the mouse stands still over a button or slider.' );
    my $layout5 = Wx::StaticText->new( $self, -1, 'Also helpful are messages in the status bar at the bottom: on left regarding images and right about settings.' );
    my $layout6 = Wx::StaticText->new( $self, -1, 'When holting the Alt key you can see which Alt + letter combinations trigger which button.' );

    my $settings  = Wx::StaticText->new( $self, -1, 'The upper half of settings define the properties of the 4 pendula (X, Y, Z and R), which create the shapes.');
    my $settings1 = Wx::StaticText->new( $self, -1, 'X moves the pen left - right (on the x axis), Y moves up - down, Z does a circling movement, R = rotation.');
    my $settings2 = Wx::StaticText->new( $self, -1, 'Each pendulum has three rows of controls - first come: the on/off switch, amplitude and (amp.) damping.');
    my $settings3 = Wx::StaticText->new( $self, -1, 'Amplitudes define the size of the drawing and damping just means the drawings will get smaller with time.');
    my $settings4 = Wx::StaticText->new( $self, -1, 'The second row lets you dial in the speed (frequency) - add there decimals for more complex drawings.');
    my $settings5 = Wx::StaticText->new( $self, -1, 'The third row has switches to invert (1/x) frequency or direction and can also change the starting position.');
    my $settings6 = Wx::StaticText->new( $self, -1, '2 = 180 degree offset, 4 = 90 degree (both can be combined). The last slider adds even more offset.');
    my $settings7 = Wx::StaticText->new( $self, -1, 'The next separated section below sets the properties of the pen: First how many rotations will be drawn.');
    my $settings8 = Wx::StaticText->new( $self, -1, 'Secondly the distance between dots and thirdly the dot size may also be changed for artistic purposes.');
    my $settings9 = Wx::StaticText->new( $self, -1, 'The right bottom corner provides options for colorization and has in itself three parts:');
    my $settings10 = Wx::StaticText->new( $self,-1, 'Topmost are the settings for the color change, which is set on default to "no"');
    my $settings11 = Wx::StaticText->new( $self,-1, 'In that case only the start (upper) color will be used, and not the lower end (target) color.');
    my $settings12 = Wx::StaticText->new( $self,-1, 'Both allows instant change of red, green and blue value or hue, saturation and lightness.');
    my $settings13 = Wx::StaticText->new( $self,-1, 'An one time or alternating gradient between both colors with different dynamics can be employed too.');
    my $settings14 = Wx::StaticText->new( $self,-1, 'Circular gradients travel around the rainbow through complement with saturation and lightness of the target.');
    my $settings15 = Wx::StaticText->new( $self,-1, 'Steps size refers always to how maby circles are draw before the color changes .');

    my $commands  = Wx::StaticText->new( $self, -1, 'Each row of command buttons has a topic, the first row below the drawing board is concerned the the image.');
    my $commands1 = Wx::StaticText->new( $self, -1, '"Save" stores the image in an arbitrary PNG, JPG or SVG file (the typed in file ending decides).');
    my $commands2 = Wx::StaticText->new( $self, -1, '"Draw" creates the picture in full length. This might take some seconds if line length and dot density are high.');
    my $commands3 = Wx::StaticText->new( $self, -1, 'The four item between "Save" and "Draw" are for series of files with a common directory and file base name.');
    my $commands4 = Wx::StaticText->new( $self, -1, 'Push "Dir" to select the directory and type in directly the file base name - the index is found automatically.');
    my $commands5 = Wx::StaticText->new( $self, -1, 'Push "Next" to save the image under the path: dir + base name + index + ending (set in config) - index will ++.');
    my $commands6 = Wx::StaticText->new( $self, -1, 'Push "Next" in the row below to also save the settings of the current state under same name with ending .ini.');
    my $commands7 = Wx::StaticText->new( $self, -1, 'The second button row deals with settings. "New" resets them to init and "Open" and "Write" loads and stores them.');
    my $commands8 = Wx::StaticText->new( $self, -1, 'The combo box in the middle of the second row allows a quick load of the last stored settings.');
    my $commands9 = Wx::StaticText->new( $self, -1, 'Row 3 and 4 access the color store (of config file .harmonograph) and their exchange with start and end color.');

    $self->{'close'} = Wx::Button->new( $self, -1, '&Close', [10,10], [-1, -1] );
    Wx::Event::EVT_BUTTON( $self, $self->{'close'},  sub { $self->EndModal(1) });

    my $sizer = Wx::BoxSizer->new( &Wx::wxVERTICAL );
    my $t_attrs = &Wx::wxGROW | &Wx::wxLEFT | &Wx::wxALIGN_LEFT;
    $sizer->AddSpacer( 10 );
    $sizer->Add( $layout,          0, $t_attrs, 20 );
    $sizer->Add( $layout1,         0, $t_attrs, 40 );
    $sizer->Add( $layout2,         0, $t_attrs, 40 );
    $sizer->Add( $layout3,         0, $t_attrs, 40 );
    $sizer->Add( $layout4,         0, $t_attrs, 20 );
    $sizer->Add( $layout5,         0, $t_attrs, 20 );
    $sizer->Add( $layout6,         0, $t_attrs, 20 );
    $sizer->AddSpacer( 20 );
    $sizer->Add( $settings,        0, $t_attrs, 20 );
    $sizer->Add( $settings1,       0, $t_attrs, 20 );
    $sizer->Add( $settings2,       0, $t_attrs, 20 );
    $sizer->Add( $settings3,       0, $t_attrs, 20 );
    $sizer->Add( $settings4,       0, $t_attrs, 20 );
    $sizer->Add( $settings5,       0, $t_attrs, 20 );
    $sizer->Add( $settings6,       0, $t_attrs, 20 );
    $sizer->AddSpacer( 10 );
    $sizer->Add( $settings7,       0, $t_attrs, 20 );
    $sizer->Add( $settings8,       0, $t_attrs, 20 );
    $sizer->AddSpacer( 10 );
    $sizer->Add( $settings9,       0, $t_attrs, 20 );
    $sizer->Add( $settings10,      0, $t_attrs, 20 );
    $sizer->Add( $settings11,      0, $t_attrs, 20 );
    $sizer->Add( $settings12,      0, $t_attrs, 20 );
    $sizer->Add( $settings13,      0, $t_attrs, 20 );
    $sizer->Add( $settings14,      0, $t_attrs, 20 );
    $sizer->Add( $settings15,      0, $t_attrs, 20 );
    $sizer->AddSpacer( 20 );
    $sizer->Add( $commands,        0, $t_attrs, 20 );
    $sizer->Add( $commands1,       0, $t_attrs, 20 );
    $sizer->Add( $commands2,       0, $t_attrs, 20 );
    $sizer->Add( $commands3,       0, $t_attrs, 20 );
    $sizer->Add( $commands4,       0, $t_attrs, 20 );
    $sizer->Add( $commands5,       0, $t_attrs, 20 );
    $sizer->AddSpacer( 10 );
    $sizer->Add( $commands6,       0, $t_attrs, 20 );
    $sizer->Add( $commands7,       0, $t_attrs, 20 );
    $sizer->Add( $commands8,       0, $t_attrs, 20 );
    $sizer->AddSpacer( 10 );
    $sizer->Add( $commands9,       0, $t_attrs, 20 );
    $sizer->Add( 0,                1, &Wx::wxEXPAND | &Wx::wxGROW);
    $sizer->Add( $self->{'close'}, 0, &Wx::wxGROW | &Wx::wxALL, 25 );
    $self->SetSizer( $sizer );
    $self->SetAutoLayout( 1 );
    $self->SetSize( 700, 720 );
    return $self;
}

1;
