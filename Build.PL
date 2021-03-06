use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
  module_name         => 'WebService::PoolCorp::API',
  license             => 'perl',
  dist_author         => q{Zakarias Santanu <zaksantanu@gmail.com>},
  dist_version_from   => 'lib/WebService/PoolCorp/API.pm',
  build_requires => {
    'Test::More' => 0,
    'Data::OpenStruct::Deep' => 0,
    'LWP::UserAgent' => 0,
    'Moose' => 0,
    'Data::URIEncode' => 0,
    'JSON::XS' => 0
  },
  add_to_cleanup      => [ 'WebService-PoolCorp-API-*' ],
  create_makefile_pl => 'traditional',
);

$builder->create_build_script();
