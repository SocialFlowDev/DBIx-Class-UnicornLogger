use strict;
use warnings;

use Test::More;
use lib "t/lib";
use DBIx::Class::UnicornLogger::FromProfile;
use DBIx::Class::UnicornLogger::SQLiteLog::Schema;
use TestSchema;

my $test_dsn = sub { return "dbi:SQLite:dbname=:memory:", "", "" };
ok my $log_schema =
  DBIx::Class::UnicornLogger::SQLiteLog::Schema->connect( $test_dsn->() );
$log_schema->deploy_if_needed;

ok my $test_schema = TestSchema->connect( $test_dsn->() ),"connected to test schema";

my $debug_obj = DBIx::Class::UnicornLogger::FromProfile->new(
    unicorn_profile => 'demo',
    log_schema      => $log_schema
);
$test_schema->storage->debug(1);
$test_schema->storage->debugobj($debug_obj);

$test_schema->deploy;

my $book_rs = $test_schema->resultset("Book");
$book_rs->all;
$book_rs->all;
$book_rs->all;
