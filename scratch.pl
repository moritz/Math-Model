use v6;
BEGIN { @*INC.push: 'lib' };

use Math::Model;;


model(
    derivatives => {
        force       => { $:mass * $:velocity },
        velocity    => { $:height },
    },
    variables   => {
        mass        => { 10 },
        height      => { -$:force },
    },
    initials    => {
        force       => 10,
        velocity    => 0,
    },
);

