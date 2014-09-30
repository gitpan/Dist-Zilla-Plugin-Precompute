package Dist::Zilla::Plugin::Precompute;

our $DATE = '2014-09-30'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010;
use strict;
use warnings;

use Data::Dump::OneLine qw(dump1);
use Moose;
with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [ ':InstallModules' ],
    },
);

use namespace::autoclean;

sub mvp_multivalue_args { qw(code) }
has code => (is => 'rw');

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
    return;
}

sub munge_file {
    my ($self, $file) = @_;

    my $content = $file->content;
    my $code = $self->code;
    my $var = $self->plugin_name;

    state %mem;
    unless ($code) {
        $self->log(["Skipping precomputing '\$var' because code is not defined"])
            unless $mem{$var};
        return;
    }
    if (ref($code) eq 'ARRAY') { $code = join '', @$code }

    my $munged_date = 0;
    my $modified =
        $content =~ s{^
                      (\s*(?:(?:my|our|local)\s+))? #1 optional prefix
                      \$(\w+(?:::\w+)*) #2 variable name
                      (?:\s*=s\s*.+?)? #3 optional current value
                      (;\s*\#\s*PRECOMPUTE) #4 marker
                      $
                 }
                     {
                         $self->log_debug(['precomputing $%s in %s ...',
                                           $2, $file->name]);
                         my $res = eval $code;
                         die if $@;
                         $1. '$'.$2 . ' = '. dump1($res) . $3
                     }egmx;
    $file->content($content) if $modified;
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Precompute variable values during building

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Precompute - Precompute variable values during building

=head1 VERSION

This document describes version 0.01 of Dist::Zilla::Plugin::Precompute (from Perl distribution Dist-Zilla-Plugin-Precompute), released on 2014-09-30.

=head1 SYNOPSIS

In C<dist.ini>:

 [Precompute/foo]
 code=Some::Module->_init_value;

in your module C<lib/Some/Module.pm>:

 our $foo; # PRECOMPUTE

The generated module file:

 our $foo = ["some", "value", "..."]; # PRECOMPUTE

=head1 DESCRIPTION

This plugin can be used to precompute (or initialize) a variable's value during
build time and put the resulting computed value into the built source code. This
is useful in some cases to reduce module startup time, especially if it takes
some time to compute the value.

=for Pod::Coverage .+

=head1 SEE ALSO

L<Dist::Zilla>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Precompute>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-Precompute>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Precompute>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
