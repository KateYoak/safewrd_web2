package Kliq::Worker::Role::WithTemplate;

use namespace::autoclean;
use Moose::Role;
use Template;
use File::Spec::Functions qw(catdir tmpdir);
use Template::Constants qw( :all );
use Data::Section::Simple qw(get_data_section);
use JSON;

sub template {
    my ($self, $template_string, $vars) = @_;
    unless($template_string =~ /\s/) {
        $template_string = $self->_template($template_string);
        }
    $vars ||= {};
    my $output;

    my $tt = Template->new;
    if ($tt->process(\$template_string, $vars, \$output )) {
        return $output;
        }
    else {
        die $tt->error();
        }

    return;
    }

sub _template {
    my ($self, $template) = @_;
    my $package = ref($self) || $self;
    my $reader = Data::Section::Simple->new($package);
    return $reader->get_data_section($template);
}

no Moose::Role;

1;
__END__
