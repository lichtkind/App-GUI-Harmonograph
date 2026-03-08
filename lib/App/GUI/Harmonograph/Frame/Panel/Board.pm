
# painting area on left side

package App::GUI::Harmonograph::Frame::Panel::Board;
use v5.12;
use warnings;
use utf8;
use Wx;
use base qw/Wx::Panel/;
use App::GUI::Harmonograph::Compute::Drawing;

sub new {
    my ( $class, $parent, $x, $y ) = @_;
    my $self = $class->SUPER::new( $parent, -1, [-1,-1], [$x+5, $y+5] );
    $self->{'menu_size'} = 27;
    $self->{'size'}{'x'} = $x;
    $self->{'size'}{'y'} = $y;
    $self->{'center'}{'x'} = $x / 2;
    $self->{'center'}{'y'} = $y / 2;
    $self->{'hard_radius'} = ($x > $y ? $self->{'center'}{'y'} : $self->{'center'}{'x'});
    $self->{'dc'} = Wx::MemoryDC->new( );
    $self->{'bmp'} = Wx::Bitmap->new( $self->{'size'}{'x'} + 10, $self->{'size'}{'y'} +10 + $self->{'menu_size'}, 24);
    $self->{'dc'}->SelectObject( $self->{'bmp'} );
    $self->{'tab'}{'constraint'} = '';
    $self->{'never_painted'} = 1;

    Wx::Event::EVT_PAINT( $self, sub {
        my( $self, $event ) = @_;
        return if exists $self->{'never_painted'};

        $self->{'x_pos'} = $self->GetPosition->x;
        $self->{'y_pos'} = $self->GetPosition->y;
        if (exists $self->{'draw_args'}) {

            $self->{'dc'}->Blit (0, 0, # x y destination
                                 $self->{'size'}{'x'} + $self->{'x_pos'},                        # width
                                 $self->{'size'}{'y'} + $self->{'y_pos'}, # height
                                 $self->paint( Wx::PaintDC->new( $self ), $self->{'size'} ), # source 
                                 0, $self->{'menu_size'}, 
                                 &Wx::wxCOPY ); # x y source
                                 
        } else {
            Wx::PaintDC->new( $self )->Blit (0, 0, # dest
                                             $self->{'size'}{'x'},  $self->{'size'}{'y'}, # size
                                             $self->{'dc'}, 5, 5);
        }

        1;
    });

    return $self;
}

sub draw {
    my( $self, $settings, $progress_bar ) = @_;
    return unless ref $settings eq 'HASH' and ref $progress_bar;
    delete  $self->{'never_painted'};
    $self->{'draw_args'} = {settings => $settings, progress_bar => $progress_bar, redraw => 1 };
    $self->Refresh;
}
sub sketch {
    my( $self, $settings, $progress_bar ) = @_;
    return unless ref $settings eq 'HASH' and ref $progress_bar;
    delete  $self->{'never_painted'};
    $self->{'draw_args'} = {settings => $settings, progress_bar => $progress_bar, redraw => 1, sketch => 1};
    $self->Refresh;
}


sub paint {
    my( $self, $dc, $size) = @_;
    return unless ref $size eq 'HASH' and exists $self->{'draw_args'}{'settings'};
    $dc->SetBackground( Wx::Brush->new( Wx::Colour->new( 255, 255, 255 ), &Wx::wxBRUSHSTYLE_SOLID ) );
    $dc->Clear();

    my $image_width = (exists $size->{'width'})  ? ($size->{'width'} / 2)  : $self->{'center'}{'x'};
    my $image_height = (defined $size->{'height'}) ? ($size->{'height'} / 2) : $self->{'center'}{'y'};
    my $paint_area_size = (defined $size->{'height'}) 
                        ? ($size->{'width'} > $size->{'height'} ? $image_width : $image_height)
                        : $self->{'hard_radius'};
    $paint_area_size -= 15;

    my $code_ref = App::GUI::Harmonograph::Compute::Drawing::compile( $self->{'draw_args'}, $paint_area_size );
    $code_ref->( $dc, $image_width, $image_height ) if ref $code_ref;
    delete $self->{'draw_args'};
    $dc;
}

sub save_file {
    my( $self, $file_name, $format, $size, $settings, $progress_bar) = @_;
    $size = { width => $size, height => $size };
    $self->{'draw_args'} = {settings => $settings, progress_bar => $progress_bar, redraw => 1};
    $format = lc $format;
    my $dot_pos = index $file_name, '.';
    $file_name = substr( $file_name, 0, $dot_pos) if $dot_pos > -1;
    $file_name .= '.' . $format;
    if    ($format eq 'svg')                     { $self->save_svg_file( $file_name, $size ) }
    elsif ($format eq 'png' or $format eq 'jpg') { $self->save_bmp_file( $file_name, $size, $format, $settings ) }
    else                                         { return "unknown image file format (use png,jpg and svg): '$format'" }
}

sub save_svg_file {
    my( $self, $file_name, $size ) = @_;
    my $dc = Wx::SVGFileDC->new( $file_name, $size->{'width'}, $size->{'height'}, 250 );  #  250 dpi
    $self->paint( $dc, $size);
}
 

sub save_bmp_file {
    my( $self, $file_name, $size, $format, $settings) = @_;
    my $bmp = Wx::Bitmap->new( $size->{'width'}, $size->{'height'}, 24); # bit depth
    my $dc = Wx::MemoryDC->new( );
    $dc->SelectObject( $bmp );
    $self->paint( $dc, $size);
    $dc->SelectObject( &Wx::wxNullBitmap );
    $bmp->SaveFile( $file_name, $format eq 'png' ? &Wx::wxBITMAP_TYPE_PNG : &Wx::wxBITMAP_TYPE_JPEG );
}

1;
