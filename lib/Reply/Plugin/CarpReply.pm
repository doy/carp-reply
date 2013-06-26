package Reply::Plugin::CarpReply;
use strict;
use warnings;
# ABSTRACT: plugin that implements most of the functionality of Carp::Reply

use base 'Reply::Plugin';

use Devel::StackTrace::WithLexicals;

=head1 SYNOPSIS

  Reply->new(plugins => ['CarpReply'])->run;

=head1 DESCRIPTION

This plugin implements the L<Reply> shell commands to support L<Carp::Reply>'s
behavior. It currently isn't incredibly useful on its own as part of a config
file, but can be useful if you want more control over creating a
Carp::Reply-like shell.

See the L<Carp::Reply> docs for a description of the commands provided by this
plugin.

=cut

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);
    $self->{stacktrace} = Devel::StackTrace::WithLexicals->new(
        ignore_class => ['Reply', 'Carp::Reply', __PACKAGE__],
    );
    $self->{frame_index} = 0;

    return $self;
}

sub compile {
    my $self = shift;
    my ($next, $line, %opts) = @_;

    $opts{environment} = $self->_frame->lexicals;
    $opts{package}     = $self->_frame->package;

    return $next->($line, %opts);
}

sub command_backtrace {
    my $self = shift;
    print "Backtrace:\n";
    print $self->{stacktrace};
    return '';
}

sub command_top {
    my $self = shift;
    $self->_frame_index($self->{stacktrace}->frame_count - 1);
    return '';
}

sub command_bottom {
    my $self = shift;
    $self->_frame_index(0);
    return '';
}

sub command_up {
    my $self = shift;
    $self->_frame_index($self->{frame_index} + 1);
    return '';
}

sub command_down {
    my $self = shift;
    $self->_frame_index($self->{frame_index} - 1);
    return '';
}

sub command_list {
    my $self = shift;
    my $file = $self->_frame->filename;
    my $line = $self->_frame->line;
    if (open my $fh, '<', $file) {
        my @code = <$fh>;
        chomp @code;

        my $min = $line - 6;
        my $max = $line + 4;
        $min = 0 if $min < 0;
        $max = $#code if $max > $#code;

        print "File $file:\n";
        for my $cur ($min..$max) {
            next unless defined $code[$cur];
            printf "%s%*d: %s\n",
                $cur + 1 == $line ? '*' : ' ',
                length($max + 1),
                $cur + 1,
                $code[$cur];
        }
    }
    else {
        print "Unable to open $file for reading: $!";
    }

    return '';
}

sub command_env {
    my $self = shift;

    our $env = $self->_frame->lexicals;

    return '$' . __PACKAGE__ . '::env';
}

sub command_trace { shift->command_backtrace(@_) }
sub command_bt    { shift->command_backtrace(@_) }
sub command_t     { shift->command_top(@_)       }
sub command_b     { shift->command_bottom(@_)    }
sub command_u     { shift->command_up(@_)        }
sub command_d     { shift->command_down(@_)      }
sub command_l     { shift->command_list(@_)      }

sub _frame_index {
    my $self = shift;
    my ($index) = @_;

    if ($index < 0) {
        print "You're already at the bottom frame.\n";
    }
    elsif ($index >= $self->{stacktrace}->frame_count) {
        print "You're already at the top frame.\n";
    }
    else {
        $self->{frame_index} = $index;
        printf "Now at %s:%s (frame $index)\n",
            $self->_frame->filename,
            $self->_frame->line;
    }
}

sub _frame {
    my $self = shift;
    return $self->{stacktrace}->frame($self->{frame_index});
}

=begin Pod::Coverage

  command_backtrace
  command_trace
  command_bt
  command_top
  command_t
  command_bottom
  command_b
  command_up
  command_u
  command_down
  command_d
  command_list
  command_l
  command_env

=end Pod::Coverage

=cut

1;
