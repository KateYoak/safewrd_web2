package Kliq::Model::Base;

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
use String::CamelCase qw/camelize/;
use Data::Dumper;
use Try::Tiny;

#my $REDIS = Kliq::Redis->new(connection => Redis->new());
#sub redis { $REDIS }

has 'user_id' => (
    is => 'ro',
    isa => 'Str',
    required => 0
    );

has 'schema' => (
    is => 'ro',
    #isa => 'Int'
    required => 1
    );

has 'user' => (
    is => 'rw',
    #isa => 'Str',
    required => 0,
    #lazy_build => 1,
    predicate => 'has_user',
    );

sub _build_user {
    my $self = shift;
    die("Invocation without user or user_id") unless $self->user_id;
    return $self->schema->resultset('User')->find($self->user_id);
    }

has 'session' => (
    is => 'ro',
    #isa => 'Int'
    required => 1
    );

has 'redis' => (
    is => 'ro',
    #isa => 'Int'
    required => 1
    );

has 'api_base' => (
    is => 'rw',
    default => 'http://api.kliqmobile.com/v1'
    );

sub method {} #die("Abstract method"); 

sub search {
    my ($self, $params, $filters, $expand) = @_;

    $params ||= {};

    $filters ||= {};
    $filters->{rows} ||= 30;
    $filters->{page} ||= 1;

    my $method = $self->method;
    my $result = $method ? 
        $self->user->$method($params, $filters) :
        $self->schema->resultset($self->table)->search_rs($params, $filters);
    
    #my $result = $total->search_rs($params, $filters);
    return $result->TO_JSON_PAGED();
    }

sub get {
    my ($self, $id) = @_;
    my $row = $self->get_row($id) or return; # die("Couldn not find $id");
    return $row->TO_JSON(1);
}

sub get_row {
    my ($self, $id) = @_;
    return $self->schema->resultset($self->table)->find({ id => $id });
}

sub create {
    my ($self, $params) = @_;

    my ($res, $error);
    my $method = $self->method;    
    try {    
        $method = 'add_to_' . $method if $method;
        $res = $method ?
            $self->user->$method($params) :
            $self->schema->resultset($self->table)->create($params);
    } catch {
        $error = $self->error($_, $method);
    };
    
    return $error || ($res ? $self->get($res->id) : $self->error(undef, $method));
}

sub update {
    my ($self, $id, $params) = @_;
    my $row = $self->get_row($id) or return;
    my ($res, $error);
    try {
        $res = $row->update($params);
    } catch {
        $error = $self->error($_);
    };
    return $error || ($res ? $self->get($res->id) : $self->error());    
    #return $error || $res || catch_error();
}

sub delete {
    my ($self, $id) = @_;
    my $row = $self->get_row($id) or return;
    return $row->delete();
}

sub error {
    my ($self, $exception, $method) = @_;
    my $error;
    if(!$exception) {
        $error = { code => "missing" };
    }
    elsif(!ref($exception)) {
        $error = { code => $exception };
    }
    elsif($exception->{msg} =~ /No such column (\w+)/) {
        $error = { field => lcfirst(camelize($1)), code => "invalid_field" };
    }
    elsif($exception->{msg} =~ /Field '(\w+)' doesn't have a default value/) {
        $error = { field => lcfirst(camelize($1)), code => 'missing_field' };
    }
    elsif($exception->{msg} =~ /Duplicate entry (.*) for key \'(\w+)\'/) {
        my $key = $2;
        $key = 'id' if($key eq 'PRIMARY');
        $error = { field => lcfirst(camelize($key)), code => "already_exists" };
    }
    elsif($exception->{msg} =~ /Recursive update is not supported over relationships of type 'multi' \((.*)\)/) {
        $error = { field => lcfirst(camelize($1)), code => "invalid_field" };
    }

    else {
        $error = { code => 'Object not created: ' . $exception };
    }
    
    ( my $entity = $method || ref($self) ) =~ s{.*::}{};
    $entity =~ s/add_to_(\w+)s?/$1/g;
    $entity =~ s/s$//g;
    $error->{resource} = ucfirst($entity);
    
    return { error => $error };
}

__PACKAGE__->meta->make_immutable;

1;
__END__