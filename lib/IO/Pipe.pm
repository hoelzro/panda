use nqp;

class IO::Pipe {
    has $.path;
    has $.in;
    has $.out;
    has $.err;
    has $.pid;

    submethod BUILD(
      :$!path;
      :$in,
      :$out,
      :$err,
      :$bin,
      :$chomp = True,
      :$enc   = 'utf8',
      :$nl    = "\n",
    ) {
        fail (X::IO::Directory.new(:$!path, :trying<pipe>))
            if $!path.e && $!path.d;

        my ($in_fh, $out_fh, $err_fh);
        my int $flags;

        if $in === $*IN {
            $in_fh := nqp::null();
            $flags += nqp::const::PIPE_INHERIT_IN;
        }
        elsif $in === True {
            $!in    = IO::Handle.new( :$chomp, :$nl );
            $in_fh := nqp::syncpipe();
            nqp::setinputlinesep($in_fh, nqp::unbox_s($nl));
            nqp::setencoding($in_fh, NORMALIZE_ENCODING($enc)) unless $bin;
            nqp::bindattr(nqp::decont($!in), IO::Handle, '$!PIO', $in_fh);
            nqp::bindattr(nqp::decont($!in), IO::Handle, '$!chomp', $chomp);
            nqp::bindattr_i(nqp::decont($!in), IO::Handle, '$!pipe', 1);
            $flags += nqp::const::PIPE_CAPTURE_IN;
        }
        else {
            $in_fh := nqp::null();
            $flags += nqp::const::PIPE_IGNORE_IN;
        }

        if $out === $*OUT {
            $out_fh := nqp::null();
            $flags  += nqp::const::PIPE_INHERIT_OUT;
        }
        elsif $out === True {
            $!out    = IO::Handle.new( :$chomp, :$nl );
            $out_fh := nqp::syncpipe();
            nqp::setinputlinesep($out_fh, nqp::unbox_s($nl));
            nqp::setencoding($out_fh, NORMALIZE_ENCODING($enc)) unless $bin;
            nqp::bindattr(nqp::decont($!out), IO::Handle, '$!PIO', $out_fh);
            nqp::bindattr(nqp::decont($!out), IO::Handle, '$!chomp', $chomp);
            nqp::bindattr_i(nqp::decont($!out), IO::Handle, '$!pipe', 1);
            $flags += nqp::const::PIPE_CAPTURE_OUT;
        }
        else {
            $out_fh := nqp::null();
            $flags  += nqp::const::PIPE_IGNORE_OUT;
        }

        if $err === $*ERR {
            $err_fh := nqp::null();
            $flags  += nqp::const::PIPE_INHERIT_ERR;
        }
        elsif $err === True {
            $!err    = IO::Handle.new( :$chomp, :$nl );
            $err_fh := nqp::syncpipe();
            nqp::setinputlinesep($err_fh, nqp::unbox_s($nl));
            nqp::setencoding($err_fh, NORMALIZE_ENCODING($enc)) unless $bin;
            nqp::bindattr(nqp::decont($!err), IO::Handle, '$!PIO', $err_fh);
            nqp::bindattr(nqp::decont($!err), IO::Handle, '$!chomp', $chomp);
            nqp::bindattr_i(nqp::decont($!err), IO::Handle, '$!pipe', 1);
            $flags += nqp::const::PIPE_CAPTURE_ERR;
        }
        else {
            $err_fh := nqp::null();
            $flags  += nqp::const::PIPE_IGNORE_ERR;
        }

        $!pid = nqp::openpipe(
          nqp::unbox_s($!path.Str),
          nqp::unbox_s($*CWD.Str),
          CLONE-HASH-DECONTAINERIZED(%*ENV),
          $in_fh, $out_fh, $err_fh,
          $flags
        );
    }

    method close {
        Proc::Status.new(:exitcode(0), :signal(0), :$!pid) # a shim, for now
    }
}

sub pipe($cmd, |c) is export {
    IO::Pipe.new(:path($cmd.IO), |c)
}

# Example:
# $ perl6 -Ilib -e 'use IO::Pipe; my $p = pipe("wc", :in, :out); $p.in.say: "hello world\nabc"; say $p.in.close; say $p.out.slurp-rest'
# Proc::Status.new(exitcode => 0, pid => Any, signal => 0)
#       2       3      16
