package FIDO::Raw;

use strict;
use warnings;

require XSLoader;
XSLoader::load('FIDO::Raw', $FIDO::Raw::VERSION);

1;

__END__

=for HTML
<a href="https://dev.azure.com/jacquesgermishuys/p5-FIDO-Raw/_build">
	<img src="https://dev.azure.com/jacquesgermishuys/p5-FIDO-Raw/_apis/build/status/jacquesg.p5-FIDO-Raw?branchName=master" alt="Build Status: Azure Pipeline" align="right" />
</a>
<a href="https://ci.appveyor.com/project/jacquesg/p5-fido-raw">
	<img src="https://ci.appveyor.com/api/projects/status/il9rm9fsf9dj1dcu/branch/master?svg=true" alt="Build Status: AppVeyor" align="right" />
</a>
<a href="https://coveralls.io/r/jacquesg/p5-FIDO-Raw">
	<img src="https://coveralls.io/repos/jacquesg/p5-FIDO-Raw/badge.png?branch=master" alt="coveralls" align="right" />
</a>
=cut

=head1 NAME

Git::Raw - Perl bindings to the libfido2 library

=head1 DESCRIPTION

=head1 METHODS

=head1 DOCUMENTATION

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
