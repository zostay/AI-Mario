package AI::Mario::Config;
use Moose::Role;

requires qw( reset );

has map_zoom_level => (
    is        => 'rw',
    isa       => 'Int',
    default   => 1,
    predicate => 'sets_map_zoom_level',
);

has enemies_zoom_level => (
    is        => 'rw',
    isa       => 'Int',
    default   => 0,
    predicate => 'sets_enemies_zoom_level',
);

has visualization => (
    is        => 'rw',
    isa       => 'Bool',
    default   => 1,
    predicate => 'sets_visualization',
);

has view_always_on_top => (
    is        => 'rw',
    isa       => 'Bool',
    default   => 0,
    predicate => 'sets_view_always_on_top',
);

has time_limit => (
    is        => 'rw',
    isa       => 'Int',
    default   => 200,
    predicate => 'sets_time_limit',
);

has timer => (
    is        => 'rw',
    isa       => 'Bool',
    default   => 1,
    predicate => 'sets_timer',
);

has stop_on_first_win => (
    is        => 'rw',
    isa       => 'Bool',
    default   => 0,
    predicate => 'sets_stop_on_first_win',
);

has maximum_fps => (
    is        => 'rw',
    isa       => 'Bool',
    default   => 0,
    predicate => 'sets_maximum_fps',
);

has matlab_report_name => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'sets_matlab_report_name',
);

has stop_on_simulation_end => (
    is        => 'rw',
    isa       => 'Bool',
    default   => 1,
    predicate => 'sets_stop_on_simulation_end',
);

has level_difficulty => (
    is        => 'rw',
    isa       => 'Int',
    default   => 0,
    predicate => 'sets_level_difficulty',
);

use constant FIRE_MARIO  => 2;
use constant LARGE_MARIO => 1;
use constant SMALL_MARIO => 0;

has mario_mode => (
    is        => 'rw',
    isa       => 'Int',
    default   => FIRE_MARIO,
    predicate => 'sets_mario_mode',
);

use constant OVERGROUND  => 0;
use constant UNDERGROUND => 1;
use constant CASTLE      => 2;

has level_type => (
    is        => 'rw',
    isa       => 'Int',
    default   => OVERGROUND,
    predicate => 'sets_level_type',
);

has level_length => (
    is        => 'rw',
    isa       => 'Int',
    default   => 320,
    predicate => 'sets_level_length',
);

has pause_world => (
    is        => 'rw',
    isa       => 'Bool',
    default   => 0,
    predicate => 'sets_pause_world',
);

has level_seed => (
    is        => 'rw',
    isa       => 'Int',
    default   => 1,
    predicate => 'sets_level_seed',
);

has enable_power_restoration => (
    is        => 'rw',
    isa       => 'Bool',
    default   => 0,
    predicate => 'sets_enable_power_restoration',
);

# TODO Handle this with attribute traits?
my %option_names = (
    map_zoom_level           => 'zm',
    enemies_zoom_level       => 'ze',
    visualization            => 'vis',
    view_always_on_top       => 'vaot',
    time_limit               => 'tl',
    timer                    => 't',
    stop_on_first_win        => 'ssiw',
    maximum_fps              => 'maxFPS',
    matlab_report_name       => 'm',
    stop_on_simulation_end   => 'ewf',
    level_difficulty         => 'ld',
    mario_mode               => 'mm',
    level_type               => 'lt',
    level_length             => 'll',
    pause_world              => 'pw',
    level_seed               => 'ls',
    enable_power_restoration => 'pr',
);

sub as_string {
    my $self = shift;
    my $string = '';

    for my $attribute ($self->meta->get_all_attributes) {

        my $name = $attribute->name;
        next unless defined $option_names{ $name };
        
        my $has_setting = 'sets_' . $name;
        next unless $self->$has_setting;

        $string .= '-' . $option_names{ $name } . ' ';
        my $type = $attribute->type_constraint;

        if ($type->equals('Int')) {
            $string .= $attribute->get_value($self);
        }
        elsif ($type->equals('Bool')) {
            $string .= $attribute->get_value($self) ? 'on' : 'off';
        }
        elsif ($type->equals('Str')) {
            $string .= $attribute->get_value($self);
        }
        else {
            die "unexpected type @{[$type->name]} of attribute @{[$attribute->name]}\n";
        }

        $string .= ' ';
    }

    return $string;
}

1;
