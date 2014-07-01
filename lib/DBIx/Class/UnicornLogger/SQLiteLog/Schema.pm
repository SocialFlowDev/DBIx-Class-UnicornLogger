package DBIx::Class::UnicornLogger::SQLiteLog::Schema;

use warnings;
use strict;

use base 'DBIx::Class::Schema';

use Try::Tiny;
use Carp;
use namespace::autoclean;

our $VERSION = 1;

__PACKAGE__->load_namespaces();

sub deploy_if_needed {
    my $self = shift;
    my $rs   = $self->resultset("Entry");

    try {
        $rs->first;
    }
    catch {
        if (/no such table/i) {
            $self->deploy;
        }
        else {
            confess $_;
        }
    };
}

1;
