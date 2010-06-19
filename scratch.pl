use v6;
BEGIN { @*INC.push: 'lib' };

use Math::Model;


my $m = Math::Model.new(
    derivatives => {
        velocity    => 'height',
        force       => 'momentum'
    },
    variables   => {
        mass        => { 1 },
        velocity    => { $:force / $:mass },
        force       => { -$:height },
    },
    initials    => {
        height      => 1,
        momentum    => 0,
    },
    captures    => <height velocity force>,
);

$m.integrate(:to(5), :min-resolution(0.5));
$m.render-svg('spring.svg');
