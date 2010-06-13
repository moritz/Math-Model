use v6;
BEGIN { @*INC.push: '../Math-RungeKutta/lib' };

use Math::RungeKutta;


my %model = {
    derivatives => {
        force       => { $:mass * $:velocity },
        velocity    => { $:height },
    },
    variables   => {
        mass        => { 10 },
        height      => { -$:force },
    },
    initial     => {
        force       => 10,
        velocity    => 0,
    },
};


{

    my %deriv-keying = %model<derivatives>.keys Z=> 0..Inf;
    my @derivs;
    my @initial;
    for %model<initial>.pairs {
        @initial[%deriv-keying{.key}] = .value;
    }
    for %model<derivatives>.pairs {
        @derivs[%deriv-keying{.key}]  = .value;
    }

    my sub param-names(&c) {
        &c.signature.params».name».substr(1).grep: * !eq '_';
    }

    sub derivatives($time, @values) {
        my sub params-for(&c) {
            my %params;
            for param-names(&c) -> $p {
                my $value;
                if $p eq 'time' {
                    $value = $time;
                } elsif %model<derivatives>.exists($p) {
                    $value = @values[%deriv-keying{$p}];
                } elsif %model<variables>.exists($p) {
                    my $c = %model<variables>.{$p};
                    $value = $c.(|params-for($c));
                } else {
                    die "Don't know where to get '$p' from.";
                }
                %params{$p} = $value;
            }
            return %params;
        }
        my @res = @values.keys.map: -> $i {
            my $d      = @derivs[$i];
            my %params = params-for($d);
            $d(|%params);
        };
        say @res.perl;
    }
    derivatives(0, @initial);
    
}

# vim: ft=perl6
