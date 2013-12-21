#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::PoolCorp::API' ) || print "Bail out!
";
}

diag( "Testing WebService::PoolCorp::API $WebService::PoolCorp::API::VERSION, Perl $], $^X" );
