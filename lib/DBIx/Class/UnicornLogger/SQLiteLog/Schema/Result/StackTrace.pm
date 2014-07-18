package DBIx::Class::UnicornLogger::SQLiteLog::Schema::Result::StackTrace;

use strict;
use warnings;

use base 'DBIx::Class::Core';

use Digest::SHA ();
use JSON::MaybeXS;

__PACKAGE__->load_components(qw[ InflateColumn TimeStamp ]);

__PACKAGE__->table('stacktrace');

__PACKAGE__->add_columns(
    stacktrace_id   => { data_type => 'integer',   is_auto_increment => 1 },
    stacktrace_hash => { data_type => 'text' },
    data            => { data_type => 'text',      default_value     => '[]' },
    create_date     => { data_type => 'timestamp', set_on_create     => 1 },
);

sub hash_for {
    my($self,$str) = @_;
    return Digest::SHA::sha1_hex($str);
}

__PACKAGE__->set_primary_key('stacktrace_id');

__PACKAGE__->add_unique_constraint(['stacktrace_hash']);

__PACKAGE__->has_many(
    entries => 'DBIx::Class::UnicornLogger::SQLiteLog::Schema::Result::Entry',
    'entry_id'
);

my $json_inflate = sub {
    my ( $raw_value_from_db, $result_object ) = @_;
    return decode_json($raw_value_from_db);
};

my $json_deflate = sub {
    my ( $inflated_value_from_user, $result_object ) = @_;
    return encode_json($inflated_value_from_user);
};

__PACKAGE__->inflate_column(
    data => {
        inflate => $json_inflate,
        deflate => $json_deflate,
    },
);

1;
