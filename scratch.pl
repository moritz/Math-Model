use v6;
BEGIN { @*INC.push: 'lib' };

use Math::Model;


my $m = Math::Model.new(
    derivatives => {
        velocity    => 'height',
    },
    variables   => {
        velocity    => { 1 },
    },
    initials    => {
        height      => 0,
    },
    captures    => <height velocity>,
);

$m.integrate(:to(2), :min-resolution(0.5));
$m.render-svg('spring.svg');
