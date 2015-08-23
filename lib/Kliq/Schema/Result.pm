package Kliq::Schema::Result;

use strict;
use String::CamelCase qw/camelize/;
use JSON ();
use Scalar::Util qw/blessed/;
use parent qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/
    InflateColumn::Serializer InflateColumn::DateTime TimeStamp 
    PassphraseColumn UUIDColumns
    /);

__PACKAGE__->mk_group_accessors(inherited => '_serializable_columns');

my $dont_serialize = {
   text  => 0,
   ntext => 1,
   blob  => 1,
};

sub _is_column_serializable {
   my ( $self, $column ) = @_;

   my $info = $self->column_info($column);
   if (!defined $info->{is_serializable}) {
      if (defined $info->{data_type} &&
          $dont_serialize->{lc $info->{data_type}}
      ) {
         $info->{is_serializable} = 0;
      } else {
         $info->{is_serializable} = 1;
      }
   }

   return $info->{is_serializable};
}

sub serializable_columns {
    my $self = shift;

    if (!$self->_serializable_columns) {
        my @cols = grep $self->_is_column_serializable($_),
           $self->result_source->columns;

        $self->_serializable_columns(\@cols);
    }
    
    return $self->_serializable_columns;
}

sub _is_bool {
    my ($self, $col) = @_;
    my $info = $self->column_info($col);
    return 1 if ($info->{data_type} =~ /tinyint/i && $info->{size} && $info->{size} == 1);
    return 0;
}

sub _bool {
    my ($self, $col) = @_;
    return $self->$col ? JSON::true : JSON::false;
}

## no critic (ProhibitUnusedPrivateSubroutines)
# override call from within DBIx::Class::InflateColumn::DateTime
sub _inflate_to_datetime {
    my ($self, @args) = @_;

    my $val = $self->next::method(@args);
    
    return unless $val && ref($val);
    return bless $val, 'Kliq::Schema::DateTime';
    }

sub TO_JSON {
    my ($self, $recursive) = @_;  #recursive follow level inline

    my $map = {};
    
    foreach my $col(@{$self->serializable_columns}) {
        $map->{lcfirst(camelize($col))} = blessed $self->$col ?
            $self->$col->TO_JSON() : (
                $self->_is_bool($col) ? $self->_bool($col) : $self->$col
            );
    }

    if ($self->can("_serializable_rels")) {
        my @cols = $self->_serializable_rels;
        foreach my $rel(@cols) {
            next unless($rel =~ /^\+/ || $recursive);
            $rel =~ s/^\+//;
            my $rela = $self->$rel or next;
            $map->{lcfirst(camelize($rel))} = $rela->TO_JSON(0);
        }
    }
    
    return $map;
}


## no critic (ProhibitMultiplePackages)
{
package Kliq::Schema::DateTime;

use strict;
use warnings;
use parent 'DateTime';

sub TO_JSON {
    my $dt = shift;
    #return $dt->datetime;
    return "$dt";
    }
}

1;
__END__

