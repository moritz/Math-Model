use v6;

class Math::Model;

use Math::RungeKutta;

has %.derivatives;
has %.variables;
has %.initials;
has @.captures is rw;
has %!deriv-keying =  %.derivatives.keys Z=> 0..Inf;

my sub param-names(&c) {
    &c.signature.params».name».substr(1).grep: * !eq '_';
}

method integrate($from = 0, $to = 10, $min-resolution = ($to - $from) / 20) {
    my @derivs;
    my @initial;
    @initial[%!deriv-keying{.key}] = .value for %.initials.pairs;
    @derivs[%!deriv-keying{.key}]  = .value for %.derivatives.pairs;


    sub derivatives($time, @values) {
        my sub params-for(&c) {
            my %params;
            for param-names(&c) -> $p {
                my $value;
                if $p eq 'time' {
                    $value = $time;
                } elsif %.derivatives.exists($p) {
                    $value = @values[%!deriv-keying{$p}];
                } elsif %.variables.exists($p) {
                    my $c = %.variables{$p};
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
        @res;
    }

    adaptive-rk-integrate(
        :$from,
        :$to,
        :@initial,
        :derivative(&derivatives),
        :max-stepsize($min-resolution),
        :do(->$t, @v { say "$t\t@v[]"}),
    );
}

# vim: ft=perl6
