package MooseX::Project::Environment::Role;

# ABSTRACT: Moose role for MooseX::Project::Environment

use Moose::Role;
use MooseX::Types::Path::Class;

use Carp qw();
use File::Spec qw();
use Path::Class qw();
use Class::Inspector qw();

=head1 DESCRIPTION

This role defines most of the logic for L<MooseX::Project::Environment>.

=cut

=head1 ATTRIBUTES

=head2 project_root_files

A list of files that usually reside in the root of a project. A presence of
this file indicates the root of the project. The following files are currently
defined:

 cpanfile
 .git
 .gitmodules
 Makefile.PL
 Build.PL

=head3 build_project_root_files

A builder method to get the list of files. You can overload this builder to
define your own list.

=head3 all_project_root_files

Returns an array of filenames.

=head3 add_project_root_file($filename)

Prepend a filename to the list. Can be used to quickly add a custom filename:

 package MyApp::Environment;
 use Moose;
 extends 'MooseX::Project::Environment';

 sub BUILD {
     my $self = shift;

     $self->add_project_root_file('dist.ini');
 }

=cut

has project_root_files => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    traits  => ['Array'],
    lazy    => 1,
    builder => 'build_project_root_files',
    handles => {
        all_project_root_files => 'elements',
        add_project_root_file  => 'unshift',
    },
);

sub build_project_root_files {
    return [qw(
            cpanfile
            .git
            .gitmodules
            Makefile.PL
            Build.PL
            )];
}

=head2 project_home

An instance of L<Path::Class::Dir>, which defines the root path of the project
as detected by one of the L</project_root_files> filenames.

Current location is determined by looking at C<%INC>, and then traversing
upwards and checking for presence of one of the L</project_root_files> filenames.

Will croak if it cannot successfully build project_home.

=cut

has project_home => (
    is      => 'ro',
    isa     => 'Path::Class::Dir',
    coerce  => 1,
    lazy    => 1,
    builder => '_build_project_home',
);

sub _build_project_home {
    my $self = shift;

    my $class = ref $self || $self;

    if ($class eq 'MooseX::Project::Environment') {
        Carp::croak('You must inherit from MooseX::Project::Environment.');
    }

    my $dir
        = Path::Class::Dir->new($INC{ Class::Inspector->filename($class) });

    ## inline package declarations will not have a path
    unless ($dir) {
        Carp::croak("Cannot find path for $class via %INC");
    }

    my $_parent = sub {
        my $dir    = shift;
        my $parent = $dir->parent;
        return if $parent eq File::Spec->rootdir;
        return $parent;
    };

    while (my $parent = $_parent->($dir)) {
        foreach my $project_root_file ($self->all_project_root_files) {
            if (-e $dir->file($project_root_file)) {
                return $dir;
            }
        }
        $dir = $parent;
    }

    Carp::croak(
              q{}
            . 'Cannot build project_home. '
            . 'Please set project_home attribute by hand or create one of '
            . 'the project_root_files in the root of the project.',
    );
}

=head2 environment_filename

A name of the file to look for in the L</project_home> directory to read the
environment string from.

File must contain a single line with the environment name. It will attempt to
chomp the line. So, this will work:

 echo "develop" > .environment

Default: C<.environment>

=cut

has environment_filename => (
    is      => 'ro',
    isa     => 'Str',
    default => '.environment',
);

=head2 environment_path

Full path to the L</environment_filename>. Basically just concatenation of
C<project_home> and C<environment_filename>.

=cut

has environment_path => (
    is      => 'ro',
    isa     => 'Path::Class::File',
    coerce  => 1,
    lazy    => 1,
    builder => '_build_environment_path',
);

sub _build_environment_path {
    my $self = shift;

    return $self->project_home->file($self->environment_filename);
}

=head2 default_environment

You can set a default environment in your subclass for when no environment
could be detected.

 package MyApp::Environment;
 use Moose;
 extends 'MooseX::Project::Environment';

 has '+default_environment' => (default => 'development');

=head3 has_default_environment

A predicate method to test if a default environment is set or not.

=cut

has default_environment => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_default_environment',
);

=head2 environment_variable

An environment variable name to look for the value. This will always take
precedence over anything.

 PROJECT_ENVIRONMENT=test prove t/app.t

Default: C<PROJECT_ENVIRONMENT>

=cut

has environment_variable => (
    is      => 'ro',
    isa     => 'Str',
    default => 'PROJECT_ENVIRONMENT',
);

=head2 project_environment

Finally the star of the show. This attribute stores the actual value of the
environment as it was established. The value is determined in the following
order:

=over 4

=item C<environment_variable>

First, we check the value of the environment variable. If the value is set,
then we use that as C<project_environment>.

=item C<.environment>

Second, we check the C<.environment> file in the C<project_home>.

=item C<default_environment>

Lastly, we check the C<default_environment> attribute for a default value

=back

If the value cannot be established, the builder will croak with an explanation.

=cut

has project_environment => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_project_environment',
);

sub _build_project_environment {
    my $self = shift;

    ## see if %ENV is set
    my $ev = $self->environment_variable;
    if (exists $ENV{$ev} && defined $ENV{$ev} && $ENV{$ev}) {
        return $ENV{$ev};
    }

    ## now check .environment file
    if (-e $self->environment_path) {
        return scalar $self->environment_path->slurp(chomp => 1);
    }

    ## finally, try default
    if ($self->has_default_environment) {
        return $self->default_environment;
    }

    Carp::croak(
              q{}
            . 'Cannot find environment file at '
            . $self->environment_path
            . ' and no default_environment set.',
    );
}

=head1 METHODS

=head2 environment

Shortcut for L</project_environment>.

=cut

sub environment {
    return shift->project_environment;
}

=head2 env

Shortcut for L</project_environment>.

=cut

sub env {
    return shift->project_environment;
}

1;    ## eof
