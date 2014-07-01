package TestSchema::Result::Book;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('book');

__PACKAGE__->add_columns(
    book_id      => { data_type => 'integer', is_auto_increment => 1 },
    name         => { data_type => 'text', },
    author       => { data_type => 'text', },
    publish_date => { data_type => 'timestamp', },
);

1;
