use v5.12;
use warnings;
use Wx;
use utf8;
use FindBin;

package App::GUI::Harmonograph;
our $NAME = __PACKAGE__;
our $VERSION = '0.4_2';

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

push "Draw" (below right drawing board) to produce visible / full image

=item 5.

push "Save" (below left) to store image in a PNG / JPEG / SVG file

=item 6.

push "Write" (second row right) to safe settings into a INI file 
for tweaking them later

=back

=head1 DESCRIPTION

An Harmonograph is an apparatus of several connected pendula, creating
together spiraling pictures :


=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/wirbel.jpg"    alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/hose.png"      alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/wirbel_4.png"  alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/df.png"        alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/wolke.png"     alt=""  width="300" height="300">
</p>




=head1 Mechanics

This is a cybernetic recreation of an Prof. Blackburns invention with 
several enhancements:

=over 4

=item *

third pendulum can rotate

=item *

pendula can oscillate at none integer frequncies

=item *

changeable amplitude damping

=item *

changeable dot density and size

=item *

3 types of color changes with changeable speed and polynomial dynamics

=back



=head1 GUI

=head2 Pendulum

=head2 Line

=head2 Colors

=head1 Workflow

=head2 File Formats

=head2 File Series


=head1 AUTHOR

Herbert Breunung (lichtkind@cpan.org)

=head1 COPYRIGHT

Copyright(c) 2022 by Herbert Breunung

All rights reserved. 
This program is free software and can be used and distributed
under the GPL 3 licence.

=cut
