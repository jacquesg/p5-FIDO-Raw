package inc::MakeMaker;

use Moose;
use Config;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_MakeFile_PL_template => sub {
	my ($self) = @_;

	my $template = <<'TEMPLATE';
use strict;
use warnings;
use Config;
use Getopt::Long;
use File::Basename qw(basename dirname);

use Devel::CheckLib;

# compiler detection
my $is_gcc = length($Config{gccversion});
my $is_msvc = $Config{cc} eq 'cl' ? 1 : 0;
my $is_sunpro = (length($Config{ccversion}) && !$is_msvc) ? 1 : 0;

# os detection
my $is_solaris = ($^O =~ /(sun|solaris)/i) ? 1 : 0;
my $is_windows = ($^O =~ /MSWin32/i) ? 1 : 0;
my $is_linux = ($^O =~ /linux/i) ? 1 : 0;
my $is_osx = ($^O =~ /darwin/i) ? 1 : 0;
my $is_gkfreebsd = ($^O =~ /gnukfreebsd/i) ? 1 : 0;
my $is_netbsd = ($^O =~ /netbsd/i) ? 1 : 0;

# allow the user to override/specify the locations of OpenSSL, libssh2
our $opt = {};

Getopt::Long::GetOptions(
	"help" => \&usage,
	'with-openssl-include=s' => \$opt->{'ssl'}->{'incdir'},
	'with-openssl-libs=s@'   => \$opt->{'ssl'}->{'libs'},
) || die &usage();

my $def = '';
my $lib = '';
my $otherldflags = '';
my $inc = '';
my $ccflags = '';

my %os_specific = (
	'darwin' => {
		'ssl' => {
			'inc' => ['/usr/local/opt/openssl/include'],
			'lib' => ['/usr/local/opt/openssl/lib']
		}
	},
);

my ($ssl_libpath, $ssl_incpath);
if (my $os_params = $os_specific{$^O}) {
	if (my $ssl = $os_params -> {'ssl'}) {
		$ssl_libpath = $ssl -> {'lib'};
		$ssl_incpath = $ssl -> {'inc'};
	}
}


my @library_tests = (
	{
		'lib'     => 'ssl',
		'libpath' => $ssl_libpath,
		'incpath' => $ssl_incpath,
		'header'  => 'openssl/opensslconf.h',
	},
);

my %library_opts = (
	'ssl' => {
		'defines' => '',
		'libs'    => ' -lssl -lcrypto',
	},
);

# check for optional libraries
foreach my $test (@library_tests)
{
	my $library = $test->{lib};
	my $user_library_opt = $opt->{$library};
	my $user_incpath = $user_library_opt->{'incdir'};
	my $user_libs = $user_library_opt->{'libs'};

	if ($user_incpath && $user_libs)
	{
		$inc .= " -I$user_incpath";

		# perform some magic
		foreach my $user_lib (@$user_libs) {
			my ($link_dir, $link_lib) = (dirname($user_lib), basename($user_lib));

			if (!$is_msvc) {
				my @tokens = grep { $_ } split(/(lib|\.)/, $link_lib);
				shift @tokens if ($tokens[0] eq 'lib');
				$link_lib = shift @tokens;
			}
			$lib .= " -L$link_dir -l$link_lib";
		}

		my $opts = $library_opts{$library};
		$opts->{'use'} = 1;

		$def .= $opts->{'defines'};

		print uc($library), " support enabled (user provided)", "\n";
	}
	elsif (check_lib(%$test))
	{
		if (exists($test->{'incpath'})) {
			if (my $incpath = $test->{'incpath'}) {
				$inc .= ' -I'.join (' -I', @$incpath);
			}
		}

		if (exists($test->{'libpath'})) {
			if (my $libpath = $test->{'libpath'}) {
				$lib .= ' -L'.join (' -L', @$libpath);
			}
		}

		my $opts = $library_opts{$library};
		$opts->{'use'} = 1;

		$def .= $opts->{'defines'};
		$lib .= $opts->{'libs'};

		print uc($library), " support enabled", "\n";
	}
	else
	{
		print uc($library), " support disabled", "\n";
	}
}

# universally supported
#$def .= ' -DNO_VIZ -DSTDC -DNO_GZIP -D_FILE_OFFSET_BITS=64 -D_GNU_SOURCE';

# supported on Solaris
if ($is_solaris) {
	$def .= ' -D_POSIX_C_SOURCE=200112L -D__EXTENSIONS__ -D_POSIX_PTHREAD_SEMANTICS';
}

if ($is_netbsd)
{
	# Needed for stat.st_mtim / stat.st_mtimespec
	$def .= ' -D_NETBSD_SOURCE';
}

if ($is_gcc)
{
	# gcc-like compiler
	$ccflags .= ' -Wall -Wno-unused-variable -Wno-pedantic -Wno-deprecated-declarations';

	# clang compiler is pedantic!
	if ($is_osx)
	{
		# clang masquerading as gcc
		if ($Config{gccversion} =~ /LLVM/) {
			$ccflags .= ' -Wno-unused-const-variable -Wno-unused-function';
		}

		# Secure transport (HTTPS)
		$otherldflags .= ' -framework CoreFoundation -framework Security';
	}

	if ($is_solaris) {
		$ccflags .= ' -std=c99';
	}

	# building with a 32-bit perl on a 64-bit OS may require this (supported by cc and gcc-like compilers,
	# excluding some ARM toolchains)
	if ($Config{ptrsize} == 4 && $Config{archname} !~ /arm/) {
		$ccflags .= ' -m32';
	}
} elsif ($is_sunpro) {
	# probably the SunPro compiler, (try to) enable C99 support
	$ccflags .= ' -xc99=all,no_lib';
	$def .= ' -D_STDC_C99';

	$ccflags .= ' -errtags=yes -erroff=E_EMPTY_TRANSLATION_UNIT -erroff=E_ZERO_OR_NEGATIVE_SUBSCRIPT';
	$ccflags .= ' -erroff=E_EMPTY_DECLARATION -erroff=E_STATEMENT_NOT_REACHED';
}

my @deps = glob 'deps/libgit2/deps/{http-parser,zlib,pcre}/*.c';
my @srcs = glob 'deps/libgit2/src/{*.c,transports/*.c,xdiff/*.c,streams/*.c,allocators/*.c,hash/sha1/collision*.c,hash/sha1/sha1dc/*.c}';
$inc .= ' -Ideps/libgit2/deps/pcre';

if ($is_windows) {
	push @srcs, glob 'deps/libgit2/src/{win32,compat}/*.c';

	$def .= ' -DWIN32 -DSTRSAFE_NO_DEPRECATE';
	$lib .= ' -lwinhttp -lrpcrt4 -lcrypt32 -lbcrypt';

	if ($is_msvc)
	{
		# visual studio compiler
		$def .= ' -D_CRT_SECURE_NO_WARNINGS';
	}
	else
	{
		# mingw/cygwin
		$def .= ' -D_WIN32_WINNT=0x0600 -D__USE_MINGW_ANSI_STDIO=1';
	}
}
else
{
	push @srcs, glob 'deps/libgit2/src/unix/*.c'
}

# real-time library is required for Solaris and Linux
#if ($is_linux || $is_solaris || $is_gkfreebsd)
#{
#	$lib .= ' -lrt';
#}

my @objs = map { substr ($_, 0, -1) . 'o' } (@deps, @srcs);

sub MY::c_o {
	my $out_switch = '-o ';

	if ($is_msvc) {
		$out_switch = '/Fo';
	}

	my $line = qq{
.c\$(OBJ_EXT):
	\$(CCCMD) \$(CCCDLFLAGS) "-I\$(PERL_INC)" \$(PASTHRU_DEFINE) \$(DEFINE) \$*.c $out_switch\$@
};

	if ($is_gcc) {
		# disable parallel builds
		$line .= qq{

.NOTPARALLEL:
};
	}
	return $line;
}

# This Makefile.PL for {{ $distname }} was generated by Dist::Zilla.
# Don't edit it but the dist.ini used to construct it.
{{ $perl_prereq ? qq[BEGIN { require $perl_prereq; }] : ''; }}
use strict;
use warnings;
use ExtUtils::MakeMaker {{ $eumm_version }};
use ExtUtils::Constant qw (WriteConstants);

{{ $share_dir_block[0] }}
my {{ $WriteMakefileArgs }}

$WriteMakefileArgs{MIN_PERL_VERSION}  = '5.8.8';
$WriteMakefileArgs{DEFINE}  .= $def;
$WriteMakefileArgs{LIBS}    .= $lib;
$WriteMakefileArgs{INC}     .= $inc;
$WriteMakefileArgs{CCFLAGS} .= $Config{ccflags} . ' '. $ccflags;
$WriteMakefileArgs{OBJECT}  .= ' ' . join ' ', @objs;
$WriteMakefileArgs{dynamic_lib} = {
	OTHERLDFLAGS => $otherldflags
};
$WriteMakefileArgs{clean} = {
	FILES => "*.inc"
};

if (!eval { ExtUtils::MakeMaker->VERSION (6.56) })
{
	my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
	my $pp = $WriteMakefileArgs{PREREQ_PM};

	for my $mod (keys %$br)
	{
		if (exists $pp -> {$mod})
		{
			$pp -> {$mod} = $br -> {$mod}
				if $br -> {$mod} > $pp -> {$mod};
		}
		else
		{
			$pp -> {$mod} = $br -> {$mod};
		}
	}
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
	unless eval { ExtUtils::MakeMaker -> VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
exit(0);

sub usage {
	print STDERR << "USAGE";
Usage: perl $0 [options]

Possible options are:
  --with-openssl-include=<path>    Specify <path> for the root of the OpenSSL installation.
  --with-openssl-libs=<libs>       Specify <libs> for the OpenSSL libraries.
USAGE

	exit(1);
}

{{ $share_dir_block[1] }}
TEMPLATE

	return $template;
};

override _build_WriteMakefile_args => sub {
	return +{
		%{ super() },
		INC	    => '-I. -Ideps/libfido2',
		OBJECT	=> '$(O_FILES)',
	}
};

__PACKAGE__->meta->make_immutable;
