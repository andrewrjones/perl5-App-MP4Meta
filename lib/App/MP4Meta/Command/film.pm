use strict;
use warnings;

package App::MP4Meta::Command::film;
use App::MP4Meta -command;

sub usage_desc { "film %o [file ...]" }

sub opt_spec {
  return (
    [ "blortex|X",  "use the blortex algorithm" ],
    [ "recheck|r",  "recheck all results"       ],
  );
}

sub validate_args {
  my ($self, $opt, $args) = @_;

 
  # we need at least one file to work with
  $self->usage_error("too few arguments") unless @$args;
  
  # check each file
  for my $f (@$args){
      unless( -e $f ){
          $self->usage_error("$f does not exist");
      }
      unless( -r $f ){
          $self->usage_error("can not read $f");
      }
      
      # TODO: is $f an mp4?
  }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    # load another package to do work?
    # require App::MP4Meta::Film;
    
    # for each file, parse?
    print "Foo";
}

1;
