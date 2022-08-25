use v5.18;
use warnings;
use Wx;

package App::Harmonograph::GUI::SliderCombo;
my $VERSION = 0.01;
use base qw/Wx::Panel/;

sub new {
    my ( $class, $parent, $label, $help, $min, $max, $init_value, $delta ) = @_;
    return unless defined $max;

    my $self = $class->SUPER::new( $parent, -1, [-1,-1], [-1, -1] );
    my $lbl  = Wx::StaticText->new($self, -1, $label, [-1, -1], [-1, 15], &Wx::wxALIGN_LEFT);
    $lbl->SetToolTip( $help );
    $self->{'min'} = $min;
    $self->{'max'} = $max;
    $self->{'value'} = $init_value // $min;
    $self->{'delta'} = $delta // 1;
  
    $self->{'txt'}      = Wx::TextCtrl->new( $self, -1, $init_value, [-1,-1], [35 + 4 * int(log $max),-1], &Wx::wxTE_RIGHT);
    $self->{'btn'}{'-'} = Wx::Button->new( $self, -1, '-', [-1,-1],[30, 30] );
    $self->{'btn'}{'+'} = Wx::Button->new( $self, -1, '+', [-1,-1],[30, 30] );

    $self->{'slider'} = Wx::Slider->new( $self, -1, $init_value, $min, $max, [-1, -1], [200, -1],
                                                &Wx::wxSL_HORIZONTAL | &Wx::wxSL_BOTTOM );
    
    my $main_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $main_sizer->Add( $lbl,  0, &Wx::wxALL| &Wx::wxALIGN_CENTER_VERTICAL, 14);
    $main_sizer->Add( $self->{'txt'}, 0, &Wx::wxGROW | &Wx::wxTOP | &Wx::wxBOTTOM | &Wx::wxALIGN_CENTER_VERTICAL, 5);
    $main_sizer->Add( $self->{'btn'}{'-'}, 0, &Wx::wxGROW | &Wx::wxTOP | &Wx::wxBOTTOM | &Wx::wxALIGN_CENTER_VERTICAL, 5);
    $main_sizer->Add( $self->{'btn'}{'+'}, 0, &Wx::wxGROW | &Wx::wxTOP | &Wx::wxBOTTOM | &Wx::wxALIGN_CENTER_VERTICAL, 5);
    $main_sizer->Add( $self->{'slider'}, 0, &Wx::wxGROW | &Wx::wxALL| &Wx::wxALIGN_CENTER_VERTICAL, 7);
    $main_sizer->Add( 0,     1, &Wx::wxEXPAND|&Wx::wxGROW);
    $self->SetSizer($main_sizer);    
    
    Wx::Event::EVT_TEXT( $self, $self->{'txt'}, sub {
        my ($self, $cmd) = @_;
        my $value = $cmd->GetString;
        $value = $self->{'min'} if not defined $value or not $value or $value < $self->{'min'};
        if ($value > $self->{'max'}) {
            my $pos = index $value, $self->GetValue();
            $value = substr ($value, 0, $pos) . substr ($value, $pos + length( $self->GetValue() )) if $pos > -1;
            $value = $self->{'max'} if $value > $self->{'max'};
        }
        $self->SetValue( $value);
    });
    
   
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'-'}, sub {
        my $value = $self->{'value'};
         $value -= ($value % $self->{'delta'} ? $value % $self->{'delta'} : $self->{'delta'});
        $value = $self->{'min'} if $value < $self->{'min'};
        $self->SetValue( $value );
    });
    
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'+'}, sub {
        my $value = $self->{'value'};
        $value += $self->{'delta'} - ($value % $self->{'delta'});
        $value = $self->{'max'} if $value > $self->{'max'};
        $self->SetValue( $value );
    });
    
    Wx::Event::EVT_SLIDER( $self, $self->{'slider'}, sub {
        my ($self, $cmd) = @_;
        $self->SetValue( $cmd->GetInt );
    });

    return $self;
}

sub SetValue { 
    my ( $self, $value) = @_;
    $value = $self->{'min'} if $value < $self->{'min'};
    $value = $self->{'max'} if $value > $self->{'max'};
    $self->{'value'} = $value;
    $self->{'txt'}->SetValue( $value ) unless $value == $self->{'txt'}->GetValue;
    $self->{'slider'}->SetValue( $value ) unless $value == $self->{'slider'}->GetValue;
}

sub GetValue { $_[0]->{'value'} }

1;

__END__

    $self->{'spin'}  = Wx::SpinCtrl->new( $self, -1, $init_value, [-1, -1], [130, -1], 
                                                &Wx::wxSP_VERTICAL | &Wx::wxSP_ARROW_KEYS, $min, $max, $init_value );
