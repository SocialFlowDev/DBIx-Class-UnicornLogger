package DBIx::Class::UnicornLogger::SQLiteLog::Web;

use strict;
use warnings;

use Moo;
use DBIx::Class::UnicornLogger::SQLiteLog::Schema;
use JSON::MaybeXS;
use Plack::Request;

has schema => ( is => 'lazy' );

has entry_rs => ( is => 'lazy' );

sub _build_schema {
    my $schema = DBIx::Class::UnicornLogger::SQLiteLog::Schema->connect(
        sprintf( "dbi:SQLite:dbname=%s", $ENV{DBICU_SQLITE_PATH} ) );
}

sub _build_entry_rs {
    shift->schema->resultset("Entry")->search(
        undef,
        {
            prefetch => [qw/query stacktrace/] } );
}

sub get_page {
    my($self,$req) = @_;
    return $req->parameters->{page} || 1;
}

sub _data {
    my ($self,$parameters) = @_;
    my $dir      = $parameters->{dir}      // 'desc';
    my $order_by = $parameters->{order_by} // 'entry_id';
    my $page     = $parameters->{page}     // 1;
    my $rows = $parameters->{rows} // 100;
    $dir = "-$dir";
    my $attrs = {
            order_by => { $dir => $order_by },
            rows => $rows,
            page => $page,
    };
    my $rs = $self->entry_rs;
    return [
        map {
            my %h = $_->get_inflated_columns;
            $h{create_date} = $h{create_date}->epoch;
            $h{stack_trace} = $_->stacktrace->data;
            $h{query} = $_->query->query;
            \%h
        } $rs->search(undef,{order_by => {-desc => 'entry_id' }, rows => 300 })->all
      ]
}

sub _render {
    my ( $self, $req, $data ) = @_;
    my $res = $req->new_response(200);
    $res->content_type('text/javascript; charset=utf-8');
    $res->body( encode_json( $data ) );
    $res->finalize;
}
sub request {
    my ( $self, $env ) = @_;
    my $req = Plack::Request->new($env);
    my $path = $req->path;
    warn $path;
    return $self->_render( $req, $self->_data( $req->parameters ) );
}

sub query_rollups {
    my($self,$env) = @_;
    my $req = Plack::Request->new($env);
    my $res = $req->new_response(200);
    my $rs = $self->entry_rs;
    $res->content_type('text/javascript; charset=utf-8');
    my %rolled_up_data;
    for( $rs->all ) {
        my $canonical_stack_trace = join( "\n", $_->stack_trace );
        my $obj = $rolled_up_data{ $_->query } ||= {
            count       => 0,
            stack_trace => {},
            params      => [],
            runtime     => {
                total_time_in_query => 0,
                avg_time            => 0,
                max_time            => undef,
                min_time            => undef,
              }
        };
        $obj->{stack_trace}{$canonical_stack_trace} = $_->stack_trace;
        $obj->{runtime}{total_time_in_query} += $_->runtime;
        push( @{ $obj->{params} }, $_->params );
        my $base_avg = $obj->{count} * $obj->{runtime}{avg_time};
        $obj->{runtime}{avg_time} =
          ( $base_avg + $_->runtime ) / $obj->{count}+1;
        $obj->{count}++;
        if ( !defined $obj->{runtime}{min_time}
            || $_->runtime < $obj->{runtime}{min_time} )
        {
            $obj->{runtime}{min_time} = $obj->{runtime}{min_time};
        }
        if ( !defined $obj->{runtime}{max_time}
            || $_->runtime < $obj->{runtime}{max_time} )
        {
            $obj->{runtime}{max_time} = $obj->{runtime}{max_time};
        }
    }

    $res->body(
        encode_json(
            [
                map {
                    my %h = $_->get_inflated_columns;
                    $h{create_date} = $h{create_date}->epoch;
                    \%h
                } $rs->all
            ] ) );
    $res->finalize;
}

sub psgi_app {
    my $self = shift;
    return sub { $self->request(@_) };
}

1;
