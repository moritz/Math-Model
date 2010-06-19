use v6;

class Math::Model;

use Math::RungeKutta;
# TODO: only load when needed
use SVG;
use SVG::Plot;

has %.derivatives;
has %.variables;
has %.initials;
has @.captures is rw;

has %!inv = %.derivatives.invert;
# in Math::Model all variables are accessible by name
# in contrast Math::RungeKutta uses vectors, so we need
# to define an (arbitrary) ordering
# @!deriv-names holds the names of the derivatives in a fixed
# order, sod @!deriv-names[$number] turns the number into a name
# %!deriv-keying{$name} translates a name into the corresponding index
has @!deriv-names  =  %!inv.keys;
has %!deriv-keying =  @!deriv-names Z=> 0..Inf;

# snapshot of all variables in the current model
has %!current-values;

has %.results;
has @.time;

my sub param-names(&c) {
    &c.signature.params».name».substr(1).grep: * !eq '_';
}

method !params-for(&c) {
    param-names(&c).map( {; $_ => %!current-values{$_} } ).hash;
}

method topo-sort(*@a) {
    my %seen;
    my @order;
    sub topo(*@a) {
        for @a {
            die "Circular dependency involving $_" if %seen{$_};
            topo(param-names(%.variables{$_})) unless %.derivatives.exists($_);
            @order.push: $_ unless %seen{$_};
            ++%seen{$_};
        }
    }
    topo(@a);
    @order;
}


method integrate($from = 0, $to = 10, $min-resolution = ($to - $from) / 20) {
    for %.derivatives -> $d {
        die "There must be a variable defined for each derivative, missiing for '$d.key()'"
            unless %.variables.exists($d.key) || %!inv.exists($d.key);
        die "There must be an initial value defined for each derivative target, missing for '$d.value()'"
            unless %.initials.exists($d.value);
    }

    my %vars               = %.variables.pairs.grep: { ! %!inv.exists(.key) };
    say "Vars: %vars.perl()";

    %!current-values       = %.initials;
    %!current-values<time> = $from;

    my @vars-topo          = @.topo-sort(%vars.keys);
    sub update-current-values($time, @values) {
        %!current-values<time>          = $time;
        %!current-values{@!deriv-names} = @values;
        for @vars-topo {
            my $c = %vars{$_};
            %!current-values{$_} = $c.(|self!params-for($c));
        }
    }
    say "Deriv names: @!deriv-names.perl()";
    say "Start values: %.initials{@!deriv-names}.perl()";
    update-current-values($from, %.initials{@!deriv-names});
    say "Start values: %!current-values.perl()";

    my @initial = %.initials{@!deriv-names};

    sub derivatives($time, @values) {
        update-current-values($time, @values);
        my @r;
        for @!deriv-names {
            my $v = %.variables{$_};
            if defined $v {
                @r.push: $v(|self!params-for($v));
            } else {
                @r.push: %!current-values{$_};
            }
        }
        say "Derivatives at time $time: @r.perl()";
        @r;
    }

    @!time = ();
    for @.captures {
        say "Initializing record for '$_'";
        %!results{$_} = [];
    }

    sub record($time, @values) {
        update-current-values($time, @values);
        @!time.push: $time;

        for @.captures {
            %!results{$_}.push: %!current-values{$_};;
        }
    }

    adaptive-rk-integrate(
        :$from,
        :$to,
        :@initial,
        :derivative(&derivatives),
        :max-stepsize($min-resolution),
        :do(&record),
    );
    %!results;
}

method render-svg($filename) {
    my $f = open $filename, :w
            or die "Can't open file '$filename' for writing: $!";
    my @data = map { %!results{$_} }, @.captures;
    say %!results.perl;
    my $svg = SVG::Plot.new(
        width   => 800,
        height  => 600,
        x       => @!time,
        values  => @data,
        title   => 'Model output',
    ).plot(:xy-lines);
    $f.say(SVG.serialize($svg));
    $f.close;
    say "Wrote ouput to '$filename'";
}

# vim: ft=perl6
