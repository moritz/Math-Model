use v6;
BEGIN { @*INC.push: 'lib' };

use Math::Model;


my $m = Math::Model.new(
    derivatives => {
        force       => { $:mass * $:velocity },
        velocity    => { $:height },
    },
    variables   => {
        mass        => { 1 },
        height      => { -$:force },
    },
    initials    => {
        force       => 1,
        velocity    => 0,
    },
    captures    => <height velocity force>,
);

$m.integrate(:to(5), :min-resolution(0.5));
$m.render-svg('spring.svg');
