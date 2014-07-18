use strict;
use warnings;
use Plack::Builder;
use FindBin;
use DBIx::Class::UnicornLogger::SQLiteLog::Web;

my $web = DBIx::Class::UnicornLogger::SQLiteLog::Web->new;

builder {
    enable "Plack::Middleware::Static",
      path => qr{^/(static)/},
      root => "$FindBin::Bin/./root";
    $web->psgi_app;
};

