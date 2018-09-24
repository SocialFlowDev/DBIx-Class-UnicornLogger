package Catalyst::TraitFor::Model::DBIC::Schema::SQLiteDebug;

use strict;
use warnings;

use namespace::autoclean;
use Moose::Role;

use DBIx::Class::UnicornLogger::FromProfile;
use Devel::Dwarn;
has init => ( is => 'rw', default => 0 );

before ACCEPT_CONTEXT => sub {
    my ($self,$c) = @_;
    return if $self->init;
    my $debug_object =
      DBIx::Class::UnicornLogger::FromProfile->new(
        unicorn_profile => 'console' );
    $self->schema->storage->debugobj($debug_object);
    $self->init(1);
};

1;
