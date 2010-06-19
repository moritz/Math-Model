use v6;
BEGIN { @*INC.push: 'lib' };

use Math::Model;


my $m = Math::Model.new(
    derivatives => {
        velocity     => 'height',
        acceleration => 'velocity',
    },
    variables   => {
        acceleration    => { -$:height },
    },
    initials    => {
        height      => 1,
        velocity    => 0,
    },
    captures    => <height velocity acceleration>,
);

$m.integrate(:to(2), :min-resolution(0.5));
$m.render-svg('spring.svg');
