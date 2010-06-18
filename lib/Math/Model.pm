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

method !params-for(&c, $time, @values) {
    my %params;
    for param-names(&c) -> $p {
        %params{$p} = self!value-for-name($time, $p, @values);
    }
    return %params;
}

method !value-for-name($time, $name, @values) {
    if $name eq 'time' {
        return $time;
    } elsif %.derivatives.exists($name) {
        return @values[%!deriv-keying{$name}];
    } elsif %.variables.exists($name) {
        my $c = %.variables{$name};
        return $c.(|self!params-for($c, $time, @values));
    } else {
        die "Don't know where to get '$name' from.";
    }
}

method integrate($from = 0, $to = 10, $min-resolution = ($to - $from) / 20) {
    my @derivs;
    my @initial;
    @initial[%!deriv-keying{.key}] = .value for %.initials.pairs;
    @derivs[%!deriv-keying{.key}]  = .value for %.derivatives.pairs;


    sub derivatives($time, @values) {

        my @res = @values.keys.map: -> $i {
            my $d      = @derivs[$i];
            my %params = self!params-for($d, $time, @values);
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
