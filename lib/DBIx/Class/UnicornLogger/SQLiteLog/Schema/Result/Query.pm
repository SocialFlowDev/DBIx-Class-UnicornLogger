package DBIx::Class::UnicornLogger::SQLiteLog::Schema::Result::Query;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('query');
__PACKAGE__->load_components(qw[ InflateColumn TimeStamp ]);
__PACKAGE__->add_columns(
    query_id    => { data_type => 'integer',   is_auto_increment => 1 },
    query       => { data_type => 'text' },
    create_date => { data_type => 'timestamp', set_on_create     => 1 },
);

__PACKAGE__->set_primary_key('query_id');
__PACKAGE__->add_unique_constraint( ['query'] );

__PACKAGE__->has_many(
    entries => 'DBIx::Class::UnicornLogger::SQLiteLog::Schema::Result::Entry',
    'query_id'
);

1;
