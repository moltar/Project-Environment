package ProjectX::Env;

use Moose;
extends 'MooseX::Project::Environment';

has '+environment_filename' => (default => 'environment');

1;
