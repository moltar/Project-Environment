package MooseX::Project::Environment;

# ABSTRACT: Set and detect project environment via .environment file.

use Moose;
with 'MooseX::Project::Environment::Role';
with 'MooseX::Role::Flyweight';

use version; our $VERSION = version->new('v1.0.0');

use overload '""' => sub { shift->project_environment };

=head1 SYNOPSIS

Add a .environment file into the root of your project:

  .
  |-- .environment (<-- add this)
  |-- .git
  |-- lib
      |-- MyApp
      |  |-- Environment.pm
      |-- MyApp.pm

Define a subclass for your application:

 package MyApp::Environment;

 use Moose;
 extends 'MooseX::Project::Environment';

 1;

Now, somewhere inside your application code:

 my $env = MyApp::Environment->instance->project_environment; ## or ->env

=head1 DESCRIPTION

This module provides a way to determine the environment an application is
running in (e.g. development, production, testing, etc.).

Mainly the environment is detected from C<.environment> file in the project
root.

You can also set the environment via C<%ENV>.

Most of the functionality defined and documented in
L<MooseX::Project::Environment::Role>.

This consumer class provides 2 things:

=head2 singularity

This isn't exactly a singleton. And the all of the magic is provided by
L<MooseX::Role::Flyweight>.

In short, all you have to do is call C<instance> constructor instead of C<new>
and you get only one instance of the object and the result of the figuring out
the environment is cached.

=head2 stringification

An instance of L<MooseX::Project::Environment> will stringify into the
environment name properly. This is useful if you were to store the instance
of the L<MooseX::Project::Environment> object in an attribute, rather than
the string name of the environment.

 has environment => (
     is      => 'ro',
     default => sub { MyApp::Environment->instance },
 );

Somewhere else in the application code:

 if ($self->environment eq 'production') {
     ## do not break
 } else {
     ## break everything
 }

=head1 CAVEAT

You B<must extend> this class to use it in your application. You cannot use
this class directly, it will die. This is because it uses C<%INC> to determine
the location of itself, and that will report incorrectly if the class file is
stored in the main Perl lib directory.

=cut

1; ## eof
