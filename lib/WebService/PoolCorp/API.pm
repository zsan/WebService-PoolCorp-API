package WebService::PoolCorp::API;

use warnings;
use strict;
use Moose;
use LWP::UserAgent;
use JSON::XS;
use Data::OpenStruct::Deep;
use Data::URIEncode qw/complex_to_query/;

=head1 NAME

WebService::PoolCorp::API - Perl interface to the poolcorop.com's webservice

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use WebService::PoolCorp::API;

    my $poolcorp = WebService::PoolCorp::API->new(
      username => 'foo',
      password => 'bar',
    );

    $poolcorp->auth or die $poolcorp->error_str;


=head1 ATTRIBUTES

=head2 username

Poolcorp's username

=head2 password

Poolcorp's password

=head2 auth

Its a lazy builder, you can run this when username and password are set, will return
C<< undef >>, also C<< error_str >> will be set, otherwise it will return token's string.

=head2 token

You need C<< token >> for every requests and you can call C<< auth >> to get 
C<< token >> with this library.

=head2 service_path

Poolcorp's URL path

=cut

has username     => (is => 'rw', isa => 'Str', required => 1);
has password     => (is => 'rw', isa => 'Str', required => 1);
has auth         => (is => 'ro', lazy_build => 1, init_arg => undef);
has token        => (is => 'rw', isa => 'Str');
has search_page  => (is => 'rw', isa => 'Str', writer =>'set_search_page');
has end_of_page  => (is => 'rw', isa => 'Str', writer =>'set_end_of_page');
has error_str    => (is => 'rw', writer => 'set_error');

has service_path => (
  is => 'ro',
  default => 'https://pool360.poolcorp.com/Services/MobileService.svc/Process?'
);

has ua => (
  isa     => 'Object',
  is      => 'rw',
  default => sub { LWP::UserAgent->new },
  handles => { get => 'get' },
);

around 'get' => sub {
  my $original_method = shift;
  my $self = shift;

  my $res = $self->$original_method(@_);
  
  unless ($res->is_success) {
    $self->set_error($res->status_line);
    return undef;
  }

  return $res;
};

=head1 SUBROUTINES/METHODS

=head2 _build_auth

You do not need to call this method manually, it will be called automatically when
you call C<< auth >>. When it failed then will return C<< undef >> 
and C<< error_str >> will be set, otherwise will return token's string.

=cut


sub _build_auth {
  my $self = shift;

  my $query = {
    process => 'authenticateuser',
    user    => $self->username,
    pass    => $self->password
  };

  my $res = $self->get($self->service_path . complex_to_query($query));
  
  return undef if $self->error_str;

  my $decoded = decode_json $res->content;

  if (defined $decoded->{exmsg} && $decoded->{exmsg} =~ /(Unable.*)/i) {
    $self->set_error($1);
    return undef;
  }
    
  $self->token($decoded->{responsebody}{tk});
}


=head2 getproduct

Will get detailed information from the product and you need to pass product ID to
this method.

Will return L<< Data::OpenStruct::Deep >>'s object

  my $info = $poolcorp->getproduct($pid);

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
=cut

sub getproduct {
  my ($self, $pid) = @_;
  
  unless ($pid) {
    $self->set_error("please provide pid (Product ID)");
    return undef;
  }

  my $query = { pid => $pid, process => 'getproduct', tk => $self->token };
  
  my $res = $self->get($self->service_path . complex_to_query($query));
  
  return undef if $self->error_str;

  my $decoded = decode_json $res->content;

  Data::OpenStruct::Deep->new($decoded->{responsebody}{product});
}

=head2 getproductavailability

Just like the name, it will check for product's availability and you need to pass
product ID to this method.

Will return array reference of L<< Data::OpenStruct::Deep >>'s object

  my $availability = $poolcorp->getproductavailability($pid);
  for my $avail (@$availability) {
    say $avail->number;
    say $avail->name;
    say $avail->available;
  }

=cut

sub getproductavailability{
  my ($self, $pid) = @_;
  
  unless ($pid) {
    $self->set_error("please provide pid (Product ID)");
    return undef;
  }

  my $query = { pid => $pid, process => 'getproductavailability', tk => $self->token };
  my $res   = $self->get($self->service_path . complex_to_query($query));

  return undef if $self->error_str;

  my $decoded = decode_json $res->content;

  [map { Data::OpenStruct::Deep->new($_) } @{$decoded->{responsebody}{avail}}];
}

=head2 doesproducthaverelationships

Will check if product has a relationships, you need to pass product's ID to the
method. 

Will return L<< Data::OpenStruct::Deep >>'s object

  my $relationship = $poolcorp->doesproducthaverelationships($product_id);
  say $relationship->product_id;
  say $relationship->hassub;
  say $relationship->hasinfo;
  say $relationship->hasparts;
  say $relationship->hasother;
  say $relationship->hasacces;
=cut

sub doesproducthaverelationships {
  my ($self, $pid) = @_;
  
  unless ($pid) {
    $self->set_error("please provide pid (Product ID)");
    return undef;
  }

  my $query = { 
    pid     => $pid, 
    process => 'doesproducthaverelationships', 
    tk      => $self->token 
  };

  my $res = $self->get($self->service_path . complex_to_query($query));

  return undef if $self->error_str;

  my $decoded = decode_json $res->content;

  Data::OpenStruct::Deep->new($decoded->{responsebody});
}

=head2 getmcdepartments

It's like a way to go when you need to get all main categories (of the product).

Will return array reference of L<< Data::OpenStruct::Deep >>'s object otherwise undef
and C<< error_str >> will be set.

  my $departments = $poolcorp->getmcdepartments or die $poolcorp->error_str;

  for my $d (@$departments) {
    say join "\t", ($d->name, $d->id, $d->total, $d->r);
  }
=cut

sub getmcdepartments {
  my $self = shift;

  my $query = { process => 'getmcdepartments', tk => $self->token };
  my $res   = $self->get($self->service_path . complex_to_query($query));

  return undef if $self->error_str;

  my $decoded = decode_json $res->content;
  
  [map {Data::OpenStruct::Deep->new($_)} @{$decoded->{responsebody}{department}}];
}

=head2 getmcproductlines

When C<< getmcdepartments >> is for main categories then getmcproductlines is a way
to get sub categories. You should pass main categories ID to this method.

Will return array reference of L<< Data::OpenStruct::Deep >>'s object >> otherwise
undef and C<< error_str >> will be set

  my $sub_departments = $poolcorp->getmcproductlines($main_cat_id);
  for my $sub_dep (@$sub_departments) {
    say join "\t", ($sub_dep->name, $sub_dep->r, $sub_dep->total);
  }

=cut

sub getmcproductlines {
  my ($self, $did) = @_;

  unless ($did) {
    $self->set_error("please provide did (Department ID)");
    return undef;
  }

  my $query = {did => $did, process => 'getmcproductlines', tk => $self->token};
  my $res   = $self->get($self->service_path . complex_to_query($query));
  
  return undef if $self->error_str;

  my $decoded = decode_json $res->content;

  [map {Data::OpenStruct::Deep->new($_)} @{$decoded->{responsebody}{productline}}];
}

=head2 search

Originally i designed this method to be an interface for searching all products 
based on sub categories name, for example you can pass 
C<< %2bTop%2fmcdepartmentname_en-us%2fbilliard+-+all >> as keyword to this method, 
so its like

  while (my $row = $poolcorp->search('%2bTop%2fmcdepartmentname_en-us%2fbilliard+-+all')){
    for my $product(@$row) {
      say $product->sku;
      say $product->name;
      say $product->mfg;
      say $product->listprice;
      say $product->img;
      say $product->description;
      say $product->pid;
      say $product->mannum;
    }
  }

But actually you can pass any string to this method and the method will search 
for the keyword

=cut

sub search {
  my ($self, $keyword) = @_;

  if ($self->end_of_page) {
    $self->set_end_of_page(1);
    return undef;
  }

  unless ($keyword) {
    $self->set_error("please provide a keyword");
    return undef;
  }

  $self->set_search_page(0) unless $self->search_page;

  my $query = {
    process => 'search',
    # r => $keyword,#'%2bTop%2fmcdepartmentname_en-us%2fbilliard+-+all',
    b       => $self->search_page,
    tk      => $self->token,
    q       => '#all',    
  };

  my $query_string = complex_to_query($query) . "&r=$keyword"; 
  my $res = $self->get($self->service_path . $query_string);

  return undef if $self->error_str;

  my $decoded = decode_json $res->content;

  $self->set_end_of_page(1) if $decoded->{responsebody}{next} == -1;
  $self->set_search_page($self->search_page + 10);

  [map {Data::OpenStruct::Deep->new($_)} @{$decoded->{responsebody}{items}}];
}

=head1 AUTHOR

Zakarias Santanu, C<< <zaksantanu at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-poolcorp-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-PoolCorp-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::PoolCorp::API


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-PoolCorp-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-PoolCorp-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-PoolCorp-API>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-PoolCorp-API/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Zakarias Santanu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WebService::PoolCorp::API
