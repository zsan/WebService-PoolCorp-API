package WebService::PoolCorp::API;

use warnings;
use strict;
use Moose;
use LWP::UserAgent;
use JSON::XS;
use Data::OpenStruct::Deep;
use Data::URIEncode qw/complex_to_query/;
=head1 NAME

WebService::PoolCorp::API - Perl !nterface to the poolcorop.com's webservice

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use WebService::PoolCorp::API;

    my $poolcorp = WebService::PoolCorp::API->new(
      username => 'foo',
      password => 'bar',
    );

    $poolcorp->auth or die $poolcorp->error_str;
    ...

=head1 SUBROUTINES/METHODS
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

has ua          => (
  isa => 'Object',
  is => 'rw',
  default => sub { LWP::UserAgent->new },
  handles => { get => 'get' },
);

around 'get' => sub {
  my ($original_method, $self) = @_;

  my $res = $self->$original_method(@_);
  
  unless ($res->is_success) {
    $self->set_error($res->status_line);
    return undef;
  }

  return $res;
};


sub _build_auth {
  my $self = shift;

  my $query = {
    process => 'authenticateuser',
    user    => $self->username,
    pass    => $self->password
  };

  my $res     = $self->get($self->service_path . complex_to_query($query));
  return undef if $self->error_str;

  my $decoded = decode_json $res->content;

  if (defined $decoded->{exmsg} && $decoded->{exmsg} =~ /(Unable.*)/i) {
    $self->set_error($1);
    return undef;
  }
    
  $self->token($decoded->{responsebody}{tk});
}



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


sub doesproducthaverealtionships {
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


sub getmcdepartments {
  my $self = shift;

  my $query = { process => 'getmcdepartments', tk => $self->token };
  my $res   = $self->get($self->service_path . complex_to_query($query));

  return undef if $self->error_str;

  my $decoded = decode_json $res->content;
  
  [map {Data::OpenStruct::Deep->new($_)} @{$decoded->{responsebody}{department}}];
}


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
