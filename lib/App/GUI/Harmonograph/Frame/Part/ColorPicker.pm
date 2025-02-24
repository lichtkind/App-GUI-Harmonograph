use v5.12;
use warnings;
use Wx;

package App::GUI::Harmonograph::Frame::Part::ColorPicker;
use base qw/Wx::Panel/;
use App::GUI::Harmonograph::Widget::ColorDisplay;

my %colors;
my @color_names;
my @color_update_callbacks;

sub get_colors { \%colors }
sub set_colors {
    my $colors = shift;
    return unless ref $colors eq 'HASH';
    %colors = %$colors;
    colors_changed();
}
sub colors_changed {
    @color_names = sort keys %colors;
    $_->() for @color_update_callbacks;
}


sub new {
    my ( $class, $parent, $browser, $label, $length, $space ) = @_;
    return unless defined $label;

    my $self = $class->SUPER::new( $parent, -1 );
    $self->{'browser'}     = $browser; # picker is connected to color $browser
    $self->{'color_index'} = 0;
    $self->{'target'}      = lc ((split ' ', $label)[0]);
    $length //= 170;
    $space //= 0;
    push @color_update_callbacks, sub { $self->update_color_list };

    my $btnw = 50; my $btnh = 35;# button width and height
    $self->{'label'}  = Wx::StaticText->new( $self, -1, $label );
    $self->{'select'} = Wx::ComboBox->new( $self, -1, $self->current_color_name, [-1,-1], [$length, -1], [@color_names]);
    $self->{'<'}    = Wx::Button->new( $self, -1, '<',       [-1,-1], [ 30, 18] );
    $self->{'>'}    = Wx::Button->new( $self, -1, '>',       [-1,-1], [ 30, 18] );
    $self->{'load'} = Wx::Button->new( $self, -1, 'Load',    [-1,-1], [$btnw, $btnh] );
    $self->{'del'}  = Wx::Button->new( $self, -1, 'Del',     [-1,-1], [$btnw, $btnh] );
    $self->{'save'} = Wx::Button->new( $self, -1, 'Save',    [-1,-1], [$btnw, $btnh] );
    $self->{'display'} = App::GUI::Harmonograph::Widget::ColorDisplay->new( $self, 25, 10, $self->current_color );

    $self->{'label'}->SetToolTip("access to internal color storage for $self->{'target'} color");
    $self->{'select'}->SetToolTip("select color in list directly");
    $self->{'<'}->SetToolTip("go to previous color in list");
    $self->{'>'}->SetToolTip("go to next color in list");
    $self->{'load'}->SetToolTip("use displayed color on the right side as $self->{'target'} color");
    $self->{'save'}->SetToolTip("copy current $self->{'target'} color here (into color storage)");
    $self->{'del'}->SetToolTip("delete displayed color from storage)");
    $self->{'display'}->SetToolTip("color monitor");

    Wx::Event::EVT_COMBOBOX( $self, $self->{'select'}, sub {
        my ($win, $evt) = @_;                            $self->{'color_index'} = $evt->GetInt; $self->update_displayed_color });
    Wx::Event::EVT_BUTTON( $self, $self->{'<'},    sub { $self->{'color_index'}--;              $self->update_displayed_color });
    Wx::Event::EVT_BUTTON( $self, $self->{'>'},    sub { $self->{'color_index'}++;              $self->update_displayed_color });
    Wx::Event::EVT_BUTTON( $self, $self->{'load'}, sub { $self->{'browser'}->set_settings( $self->current_color ) });
    Wx::Event::EVT_BUTTON( $self, $self->{'del'},  sub { delete $colors{ $self->current_color_name }; colors_changed();       });
    Wx::Event::EVT_BUTTON( $self, $self->{'save'}, sub {
        my $dialog = Wx::TextEntryDialog->new ( $self, "Please insert the color name", 'Request Dialog');
        return if $dialog->ShowModal == &Wx::wxID_CANCEL;
        my $color_name = $dialog->GetValue();
        return $self->GetParent->SetStatusText( "color name '$color_name' already taken ") if exists $colors{ $color_name };
        my $current_color = $self->{'browser'}->get_settings;
        $colors{ $color_name } = [ $current_color->{'red'}, $current_color->{'green'}, $current_color->{'blue'} ];
        colors_changed();
        for (0 .. $#color_names ){  $self->{'color_index'} = $_ if $color_name eq $color_names[$_] }
        $self->update_displayed_color;
    });

    my $vset_attr = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxGROW | &Wx::wxTOP| &Wx::wxBOTTOM;
    my $all_attr  = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxGROW | &Wx::wxALL;
    my $sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $sizer->AddSpacer( 10 );
    $sizer->Add( $self->{'label'},  0, $all_attr,  9 );
    $sizer->AddSpacer( $space + 3 );
    $sizer->Add( $self->{'select'}, 0, $vset_attr, 0 );
    $sizer->Add( $self->{'<'},      0, $vset_attr, 0 );
    $sizer->Add( $self->{'>'},      0, $vset_attr, 0 );
    $sizer->AddSpacer( 20 );
    $sizer->Add( $self->{'display'},0, $vset_attr, 0);
    $sizer->AddSpacer( 20 );
    $sizer->Add( $self->{'load'},   0, $all_attr,  0 );
    $sizer->AddSpacer( 10 );
    $sizer->Add( $self->{'save'},   0, $all_attr,  0 );
    $sizer->AddSpacer( 10 );
    $sizer->Add( $self->{'del'},    0, $all_attr,  0 );
    $sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);
    $self->SetSizer($sizer);

    $self;
}

sub current_color_name { $color_names[ $_[0]->{'color_index'} ] }
sub current_color {
    my ( $self ) = @_;
    my $values = $colors{ $self->current_color_name };
    { red=> $values->[0], green=> $values->[1], blue=> $values->[2] };
}

sub update_color_list {
    $_[0]->{'select'}->Set( [@color_names] );
    $_[0]->update_displayed_color();
}

sub update_displayed_color {
    my ( $self ) = @_;
    $self->{'color_index'} = $#color_names if $self->{'color_index'} < 0;
    $self->{'color_index'} = 0             if $self->{'color_index'} > $#color_names;
    $self->{'select'}->SetSelection( $self->{'color_index'} );
    $self->{'display'}->set_color( $self->current_color );
}

1;
