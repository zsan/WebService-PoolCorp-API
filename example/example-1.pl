#!/usr/bin/env perl
use Modern::Perl;
use WebService::PoolCorp::API;
use Data::Dumper;

my $poolcorp = WebService::PoolCorp::API->new(
  username => 'username',
  password => 'password'
);

$poolcorp->auth or die $poolcorp->error_str;

say $poolcorp->token;

my $departments = $poolcorp->getmcdepartments or die $poolcorp->error_str;

for my $d (@$departments) {
  say join "\t", ($d->name, $d->id, $d->total, $d->r);
  my $sub_departments = $poolcorp->getmcproductlines($d->id);

  for my $sub_dep (@$sub_departments) {
    say join "\t", ($sub_dep->name, $sub_dep->r, $sub_dep->total);
    
    while (my $row = $poolcorp->search($sub_dep->r)){    
      for my $product(@$row) {
        say $product->sku;
        # say $product->name;
        # say $product->mfg;
        # say $product->listprice;
        # say $product->img;
        # say $product->description;
        # say $product->pid;
        # say $product->mannum;

        my $info = $poolcorp->getproduct($product->pid);

        say $info->upc;
        say $info->department;
        say $info->uom;
        say $info->superceding;
        say $info->sku;
        say $info->mfg;
        say $info->img;
        say $info->homebranchavailability;
        say $info->variantid;
        say $info->retailprice;
        say $info->supercedes;
        say $info->listprice;
        say $info->name;
        say $info->description;
        say $info->superceeduredate;
        say $info->obsolete;
        say $info->productline;
        say $info->mannum;
        say $info->price;
        say $info->productid;


        my $relationship = $poolcorp->doesproducthaverelationships($product->pid);
        say $relationship->product_id;
        say $relationship->hassub;
        say $relationship->hasinfo;
        say $relationship->hasparts;
        say $relationship->hasother;
        say $relationship->hasacces;

        my $availability = $poolcorp->getproductavailability($product->pid);
        for my $avail (@$availability) {
          say $avail->number;
          say $avail->name;
          say $avail->available;
        }
      }
    }
  }
}
