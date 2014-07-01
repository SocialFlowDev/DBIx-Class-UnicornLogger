use strict;
use warnings;
use Plack::Builder;
use DBIx::Class::UnicornLogger::SQLiteLog::Schema;
use Plack::Request;
use JSON::MaybeXS;
use FindBin;
my $schema = DBIx::Class::UnicornLogger::SQLiteLog::Schema->connect(
    sprintf( "dbi:SQLite:dbname=%s", $ENV{DBICU_SQLITE_PATH} ) );
my $app = sub {
    my $req = Plack::Request->new(shift);
    my $res = $req->new_response(200);
    $res->content_type('text/javascript; charset=utf-8');
    my $rs = $schema->resultset("Entry");
    if( $req->parameters->{prev_entry_id} ) {
        $rs = $rs->search(
            {
                entry_id => { '>' => $req->parameters->{prev_entry_id} } } );
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
};
builder {
    enable "Plack::Middleware::Static",
        path => qr{^/(static)/},
        root => "$FindBin::Bin/./root";
    $app;
};

