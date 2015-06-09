class Panda::Tester {
use Panda::Common;
use IO::Pipe;

method test($where, :$bone, :$prove-command = 'prove') {
    indir $where, {
        my Bool $run-default = True;
        if "Build.pm".IO.f {
            @*INC.push('file#.');   # TEMPORARY !!!
            GLOBAL::<Build>:delete;
            require 'Build.pm';
            if ::('Build').isa(Panda::Tester) {
                $run-default = False;
                ::('Build').new.test($where, :$prove-command);
            }
            @*INC.pop;
        }

        if $run-default && 't'.IO ~~ :d {
            withp6lib {
                my $cmd    = "$prove-command -e \"$*EXECUTABLE -Ilib\" -r t/";

                my $p = pipe($cmd, :out, :err);
                my $output = '';
                my $err = '';
                for $p.out.lines {
                    .chars && .say;
                    $output ~= "$_\n";
                }
                for $p.err.lines {
                    .chars && .say;
                    $err ~= "$_\n";
                }
                my $passed = $p.close.status == 0;

                if $bone {
                    $bone.test-output = $output;
                    $bone.test-error  = $err;
                    $bone.test-passed = $passed;
                }

                fail "Tests failed" unless $passed;
            }
        }
    };
    return True;
}

}

# vim: ft=perl6
