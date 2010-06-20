use v6;
BEGIN { @*INC.push: 'lib' };

use Math::Model;


my $m = Math::Model.new(
    derivatives => {
        velocity     => 'height',
        acceleration => 'velocity',
    },
    variables   => {
        acceleration    => { $:force / $:mass },
        mass            => { 1 },
        force           => { - $:height - 0.2 * $:velocity * abs($:velocity) + $:generator },
        generator       => { 0.1 * sin(2.05 * pi * $:time) },
    },
    initials    => {
        height      => 1,
        velocity    => 0,
    },
    captures    => [<height>],
);

$m.integrate(:from(0), :to(100), :min-resolution(1));
$m.render-svg('spring.svg');
