# must be run by an explicit perl interp (with /usr/bin/arch as usual)

use Config;
use File::Temp qw(tempfile);

if(!@ARGV) {
    die "Usage: $0 [list of perlmodule .bundle files]\n";
}

my $libperl="$Config{archlibexp}/CORE/$Config{libperl}";
if($libperl =~ /\.a$/) {
    print "building shared libperl...\n";
    my( $dylibFH, $dylib ) = tempfile( 'libperl_XXXXXX', SUFFIX=>'.dylib' ) or die "unstable to get temporary file: $!\n";
    my @cmd = ( 'gcc', '-dynamiclib', $libperl, '-all_load', '-o', $dylib );
    print "@cmd\n";
    system @cmd;
    $? >>= 8 if defined $? and $? >= 256;
    if ($?) {
	die "failed: $!\n";
    }
    $libperl = $dylib;
}

print "testing loadability of perl-dependent binaries...\n";
foreach my $bundle (@ARGV) {
    my @cmd;
    if ($Config{"byteorder"} =~ /^1/) {
        # little-endian means intel (not powerpc), so need to force
	# the correct arch
        push @cmd, '/usr/bin/arch';
        if ( $Config{"longsize"} == 4 ) {
            push @cmd, '-i386';   # 32-bit
        } else {
            push @cmd, '-x86_64'; # 64-bit
        }
    }
    push @cmd, ( './loadability', $libperl, $bundle );
    print "@cmd\n";
    system @cmd;
    $? >>= 8 if defined $? and $? >= 256;
    if ($?) {
	print "failed: $!\n";
	exit 1;
    }
}

exit 0;
