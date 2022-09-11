use v5.12;
use warnings;
use Wx;
use utf8;
use FindBin;

package App::GUI::Harmonograph;
our $VERSION = '0.4_1';

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


    1: start the program (harmonograph.pl )
    
    2. push help buttons (down left) to understand GUI and mechanics
    
    3. move knobs to interesting configuration
    
    4. push "Draw" to produce visible image

    5. push "Save" to store image in a file
    
    6. push "Write" to safe settings into a file for tweaking them later

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



=head1 AUTHOR

Herbert Breunung (lichtkind@cpan.org)

=head1 COPYRIGHT

Copyright(c) 2022 by Herbert Breunung

All rights reserved. 
This program is free software and can be used and distributed
under the GPL 3 licence.

=cut
