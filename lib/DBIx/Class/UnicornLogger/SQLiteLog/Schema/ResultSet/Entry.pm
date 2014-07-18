package DBIx::Class::UnicornLogger::SQLiteLog::Schema::ResultSet::Entry;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

use Time::HiRes;
use Devel::Dwarn;
use Devel::StackTrace;
use Digest::SHA ();
use namespace::autoclean;

our $FRAME_FILTER = sub {
    my $h = shift;
    return 0 if $h->{caller}[0] =~ /^DBIx::Class/;
    return 1;
};

my @inflight_query;
sub query_start {
    my ( $self, $q, @params ) = @_;
    push @inflight_query,
      [
        $q,
        \@params,
        Time::HiRes::time(),
        Devel::StackTrace->new(
            frame_filter => $FRAME_FILTER
        ) ];
}

sub query_end {
    my ( $self, $q, @params ) = @_;
    my $query = shift @inflight_query;
    my ( $qq, $params, $start_time, $stack_trace ) = @$query;
    my $runtime = Time::HiRes::time() - $start_time;
    my $frames  = [ map { $_->as_string } $stack_trace->frames ];
    my $hash    = Digest::SHA::sha1_hex( $stack_trace->as_string );
    my $schema  = $self->result_source->schema;
    my $guard   = $schema->txn_scope_guard;

    my $query_row = $schema->resultset("Query")->find_or_create(
        {
            query => $qq
        } );

    my $stacktrace_row = $schema->resultset("StackTrace")->find_or_create(
        {
            stacktrace_hash => $hash,
            data            => $frames,
        } );
    $self->create(
        {
            query      => $query_row,
            params     => $params,
            stacktrace => $stacktrace_row,
            runtime    => $runtime,
        } );
    $guard->commit;
}

1;
