package DBIx::Class::UnicornLogger::SQLiteLog::Schema::Result::Entry;

use strict;
use warnings;

use base 'DBIx::Class::Core';

use JSON::MaybeXS;
__PACKAGE__->load_components(qw[ InflateColumn TimeStamp ]);

__PACKAGE__->table('entry');

__PACKAGE__->add_columns(
    entry_id    => { data_type => 'integer',   is_auto_increment => 1 },
    query       => { data_type => 'text' },
    params      => { data_type => 'text',      default_value     => '[]' },
    stack_trace => { data_type => 'text',      default_value     => '[]' },
    runtime     => { data_type => 'float' },
    create_date => { data_type => 'timestamp', set_on_create     => 1 },
);

__PACKAGE__->set_primary_key('entry_id');
my $json_inflate = sub {
            my ( $raw_value_from_db, $result_object ) = @_;
            return decode_json($raw_value_from_db);
        };
my $json_deflate = sub {
    my ( $inflated_value_from_user, $result_object ) = @_;
    return encode_json($inflated_value_from_user);
};
__PACKAGE__->inflate_column(
    params => {
        inflate => $json_inflate,
        deflate => $json_deflate,
    },
);
__PACKAGE__->inflate_column(
    stack_trace => {
        inflate => $json_inflate,
        deflate => $json_deflate,
    },
);

1;
