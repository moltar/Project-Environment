# NAME

Project::Environment - Set and detect project environment via .environment file.

# VERSION

version v1.2.0

# SYNOPSIS

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
    extends 'Project::Environment';

    1;

Now, somewhere inside your application code:

    my $env = MyApp::Environment->instance->project_environment; ## or ->env

# DESCRIPTION

This module provides a way to determine the environment an application is
running in (e.g. development, production, testing, etc.).

Mainly the environment is detected from `.environment` file in the project
root.

You can also set the environment via `%ENV`.

Most of the functionality defined and documented in
[Project::Environment::Role](http://search.cpan.org/perldoc?Project::Environment::Role).

This consumer class provides 2 things:

## singularity

This isn't exactly a singleton. And all of the magic is provided by
[MooseX::Role::Flyweight](http://search.cpan.org/perldoc?MooseX::Role::Flyweight).

In short, all you have to do is call `instance` constructor instead of `new`
and you get only one instance of the object and the result of the figuring out
the environment is cached.

## stringification

An instance of [Project::Environment](http://search.cpan.org/perldoc?Project::Environment) will stringify into the
environment name properly. This is useful if you were to store the instance
of the [Project::Environment](http://search.cpan.org/perldoc?Project::Environment) object in an attribute, rather than
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

# AUTHOR

Roman F. <romanf@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Roman F..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
