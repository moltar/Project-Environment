package ProjectX::Direct;

use Moose;
use MooseX::Project::Environment;

=head2 env



=cut

has env => (
    is      => 'ro',
    isa     => 'MooseX::Project::Environment',
    lazy    => 1,
    builder => '_build_env',
);

sub _build_env {
    my $self = shift;

    return MooseX::Project::Environment->new(environment_filename => 'environment');
}

1;
