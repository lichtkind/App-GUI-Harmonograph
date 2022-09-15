use v5.12;
use warnings;
use Wx;
use utf8;
use FindBin;

package App::GUI::Harmonograph;
our $NAME = __PACKAGE__;
our $VERSION = '0.43';

use base qw/Wx::App/;
use App::GUI::Harmonograph::Frame;

sub OnInit {
    my $app   = shift;
    my $frame = App::GUI::Harmonograph::Frame->new( undef, 'Harmonograph '.$VERSION);
    $frame->Show(1);
    $frame->CenterOnScreen();
    $app->SetTopWindow($frame);
    1;
}
sub OnQuit { my( $self, $event ) = @_; $self->Close( 1 ); }
sub OnExit { my $app = shift;  1; }


1;

__END__

=pod

=head1 NAME

App::GUI::Harmonograph - sculpting beautiful circular drawings

=head1 SYNOPSIS 

=over 4

=item 1.

start the program (harmonograph)

=item 2.

push help buttons (down left) to understand GUI and mechanics

=item 3.

move knobs to interesting configuration

=item 4.

push "Draw" (below right drawing board) to produce full image

=item 5.

push "Save" (below left) to store image in a PNG / JPEG / SVG file

=item 6.

push "Write" (second row right) to safe settings into a INI file 
for tweaking them later

=back

Please note that quick preview gets only triggered by the pendulum
controls (section X, Y Z and R).

After first use of the program, a config file .harmonograph will be
created in you home directory. You may move it into "Documents" or your
local directory you start the app from.


=head1 DESCRIPTION

An Harmonograph is an apparatus with several connected pendula,
creating together spiraling pictures :


=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/wirbel.jpg"    alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/hose.png"      alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/wirbel_4.png"  alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/df.png"        alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/wolke.png"     alt=""  width="300" height="300">
</p>


This is a cybernetic recreation of an Prof. Blackburns invention with 
several enhancements:

=over 4

=item *

third pendulum can rotate

=item *

pendula can oscillate at none integer frequencies

=item *

changeable amplitude and damping

=item *

changeable dot density and dot size

=item *

3 types of color changes with changeable speed and polynomial dynamics

=back


=head1 Mechanics

The classic Harmonograph is sturdy metal rack which does not move 
while 3 pendula swing independently.
Let us call the first pendulum X, because it only moves along the x-axis
(left to right and back).
In the same fashion the second (Y) only moves up and down.
When both are connected to a pen, we get a combination of both movements.
As long as X and Y swing at the same speed, the result is a diagonal line.
Because when X goes right Y goes up and vice versa.
But if we start one pendulum at the center and the other 
at the upmost position we get a circle.
In other words: we added an offset of 90 degrees to Y (or X).
Our third pendulum Z moves the paper and does exactly 
the already described circular movement without rotating around its center.
If both circular movements (of X, Y and Z) are concurrent - 
the pen just stays at one point, If both are countercurrent - 
we get a circle. Interesting things start to happen, if we alter
the speed of of X, Y and Z. Than famous harmonic pattern appear.
And for even more complex drawings I added R, which is not really
a pendulum, but an additional rotary movement of Z around its center.
The pendula out of metal do of course fizzle out with time, 
which you can see in the drawing, in a spiraling movement toward the center.
We emulate this with a damping factor.


=head1 GUI

The general layout of the program has three parts,
which flow from the position of the drawing board.

=over 4

=item 1

In the left upper corner is the drawing board - showing the result of the Harmonograph.

=item 2

The whole right half of the window contains the settings, which guide the drawing operation.

=item 3

The lower left side contains buttons which are commands, mostly for in and output of data.

=back


Please mind the tool tips - short help texts which appear if the mouse
stands still over a button or slider. Also helpful are messages in the
status bar at the bottom: on left regarding images and right about settings.
When holting the Alt key you can see which Alt + letter combinations
trigger which button.

=head2 Pendulum

The upper half of settings define the properties of the 4 pendula
(X, Y, Z and R), which determine the shape of the drawing.
X moves the pen left - right (on the x axis), Y moves up - down,
Z does a circling movement, R is a rotation ( around Z's axis).
Each pendulum has the same three rows of controls. 

The first row contains first an on/off switch.
After that follows the pendulum's amplitude and damping.
Amplitudes define the size of the drawing and damping just means:
the drawings will spiral toward the center with time (line length).

The second row lets you dial in the speed (frequency).
The second combo control adds decimals for more complex drawings.

The third row has switches to invert (1/x) frequency or direction 
and can also change the starting position.
2 = 180 degree offset, 4 = 90 degree (both can be combined). 
The last slider adds an fine tuned offset.

=head2 Line

The next separated section below sets the properties of the pen.
First how many rotations will be drawn. Secondly the distance between dots. 
Greater distances, together with color changes, help to clearify
muddled up drawings. The third selector sets the dot size in pixel.

=head2 Colors

The right bottom corner provides options for colorization and has in itself three parts.
Topmost are the settings for the color change, which is set on default to "no".
In that case only the start (upper) color (below the color change section)
will be used, and not the end (target) color (which is even below that).

Both colors can be changed via controls for the red, green and blue value
(see labels "R", "G" and "B" ) or hue, saturation and lightness (HSL).
The result can be seen in the color monitor at the center of a color browser.

An one time or alternating gradient between both colors with different
dynamics (first in second row) can be employed. Circular gradients travel
around the rainbow through a complement color with saturation and lightness
of the target settings.
Steps size refers always to how maby circles are draw before the color changes.

=head2 Commands

Each row of command buttons has a topic.
The first row below the drawing board is concerned the the image.
Push "Draw" to create the picture with chosen settings.
This might take some seconds if line length and dot density are high.
"Save" stores the image in an arbitrary PNG, JPG or SVG file 
(the typed in file ending decides). 
The four item between "Save" and "Draw" are for series of files
with a common directory and file base name.
Push "Dir" to select the directory and type in directly the file base name -
the index is found automatically.
Push "Next" to save the image under the path:
 dir + base name + index + ending (set in config). The index automatically
 autoincrements when chnaging the settings.
Push "Next" in the row below to also save the settings of the current state
under same name with ending .ini.

The second button row deals with settings. 
"New" resets them to init state. 
"Open" loads an ini file and "Write" saves them.
The combo box in the middle of the second row allows a quick load of the
last stored settings.

Row three and four access the color store of config file .harmonograph.
The allow storing you favorite colors under a name and reloading or deleting them later.


=head1 AUTHOR

Herbert Breunung (lichtkind@cpan.org)

=head1 COPYRIGHT

Copyright(c) 2022 by Herbert Breunung

All rights reserved. 
This program is free software and can be used and distributed
under the GPL 3 licence.

=cut
