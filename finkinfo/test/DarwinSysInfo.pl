#!/usr/bin/perl -w
# -----------------------------------------------------------------
# Darwin SysInfo for X-Chat
# Available at http://www.southofheaven.net/DarwinSysInfo/
# Author: <thesin@users.sourceforge.net>
# usage : /sys, /up, /fink, /playing
#         /infosave, /infoshow, /infoload, /infohelp
#         /enable <option>, /disable <option, /conf <option> <value>
# -----------------------------------------------------------------

my $out;
my ($ENABLEDEV1, $ENABLEDEV2, $ENABLEPPP, $ENABLEFINK, $ENABLERES, $ENABLEXMMS);
my ($DEV1, $DEV1NAME, $DEV2, $DEV2NAME, $PPP, $PPPNAME, $DISPLAYLEVEL);
my $BASEPATH;
my $UNAME;
my ($ARCH, $TYPE, $MODEL, $NUM, $CPU);
my ($MEMTOTAL, $MEMUSED, $MEMGKM, $MEMPERCENT);
my ($DEV1TYPE, $PACKIN1, $PACKOUT1);
my ($DEV2TYPE, $PACKIN2, $PACKOUT2);
my $RES;
my ($HDDTOTAL, $HDDUSED, $HDDCOUNT);
my $PROCS;
my $UPTIME;
my ($OSX, $OSXVERS, $OSXBUILD);
my ($FINKVERS, $DISTVERS, $FINKPKGS, $FINKTREE);
my ($DEVTOOLS, $TOOLVERS, $TOOLBUILD, $GCCVERS);

my $configfile = "$ENV{HOME}/.xchat/darwininfo.conf";
my $version = "0.4.0";
my $scriptname = "Darwin SysInfo";

IRC::print "\n\0034Loading\003\002 $scriptname $version Script\002\n";

# Try to load the config
LoadConfig();

IRC::register("$scriptname", "$version", "", "");

IRC::add_command_handler("infoload", "LoadConfig");
IRC::add_command_handler("infosave", "SaveConfig");
IRC::add_command_handler("infoshow", "ShowConfig");
IRC::add_command_handler("infohelp", "info_help");
IRC::add_command_handler("sys", "display_info");
IRC::add_command_handler("up", "display_uptime");
IRC::add_command_handler("fink", "display_fink");
IRC::add_command_handler("playing", "display_song");

IRC::add_command_handler("enable", "enable_option");
IRC::add_command_handler("disable", "disable_option");
IRC::add_command_handler("conf", "conf_options");

sub info_help {
  IRC::print "\n";                           
  IRC::print "\002$scriptname $version\002 \0034HELP!\0034\n";
  IRC::print "\n";
  IRC::print "   \002System Functions\002\n";
  IRC::print "      \002/sys\002 - display system stats and information\n";
  IRC::print "      \002/up\002  - display current system uptime\n";
  IRC::print "\n";                           
  IRC::print "   \002Fink Functions\002 \0034NOTE: Requires and valid install of Fink http://fink.sf.net/\0034\n";
  IRC::print "      \002/fink\002 - display fink stats and information\n";
  IRC::print "\n";                           
  IRC::print "   \002XMMS Functions\002 \0034NOTE: Requires xmms and mp3-info perl modules\0034\n";
  IRC::print "      \002/playing\002 - display song currently playing in XMMS\n";
  IRC::print "         \002\00315* XMMS extra display levels:\003\002\n";
  IRC::print "           0 = No extra info";
  IRC::print "           1 = Display song parameters (freq, kbps, st/mon)";
  IRC::print "           2 = Display album and genre (if available)";
  IRC::print "           3 = 1 and 2";
  IRC::print "\n";                           
  IRC::print "   \002Script Functions\002\n";
  IRC::print "      \002/infoload\002 - Reload configuration from $configfile\n";
  IRC::print "      \002/infosave\002 - Saves configuration to $configfile\n";
  IRC::print "      \002/infohelp\002 - Display this help information\n";
  IRC::print "      \002/enable\002   - Enables an option\n";
  IRC::print "           \002Usage:\002 /enable <option>\n";
  IRC::print "      \002/disable\002  - Disables an option\n";
  IRC::print "           \002Usage:\002 /disable <option>\n";
  IRC::print "      \002/conf\002     - Change configurations values\n";
  IRC::print "           \002Usage:\002 /conf <variable> <value>\n";

  return 1;
}

sub conf_options {
  my ($tmp) = @_;
  my @args = split(/ /, $tmp); 
  my $option = $args[0];
  my $value = $args[1];

  if ($option =~ m/basepath/i) {
    IRC::print "Base Path: $value\n";
    $BASEPATH = $value;
  } elsif ($option =~ m/dev1name/i) {
    IRC::print "Device 1 Name: $value\n";
    $DEV1NAME = $value;
  } elsif ($option =~ m/dev1/i) {
    IRC::print "Device 1 Device: $value\n";
    $DEV1 = $value;
  } elsif ($option =~ m/dev2name/i) {
    IRC::print "Device 2 Name: $value\n";
    $DEV2NAME = $value;
  } elsif ($option =~ m/dev2/i) {
    IRC::print "Device 2 Device: $value\n";
    $DEV2 = $value;       
  } elsif ($option =~ m/pppname/i) {
    IRC::print "PPP Name: $value\n";
    $PPPNAME = $value;
  } elsif ($option =~ m/ppp/i) {
    IRC::print "PPP Device: $value\n";
    $PPP = $value;        
  } elsif ($option =~ m/displaylevel/i) {
    IRC::print "XMMS Display Level: $value\n";
    $DISPLAYLEVEL = $value;
  } else {
    IRC::print "\0034$option Not a valid option\0034\n";
    IRC::print "\002Valid options are:\002 basepath, dev1, dev1name, dev2, dev2name, ppp, pppname, displaylevel\n";
  }
  SaveConfig();
  return 1;
}

sub enable_option {
  my ($option) = @_;
  my $func = "enable";
  set_option($option, $func);
  return 1;
}

sub disable_option {
  my ($option) = @_;
  my $func = "disable";
  set_option($option, $func);
  return 1;
}

sub set_option {
  my $option = shift;
  my $func = shift;

  if ($option =~ m/fink/i) {
    if ($func =~ m/enable/i) {
      $ENABLEFINK = "true";
    } else {
      $ENABLEFINK = "false";
    }
  } elsif ($option =~ m/dev1/i) {
    if ($func =~ m/enable/i) {
      $ENABLEDEV1 = "true";
    } else {
      $ENABLEDEV1 = "false";
    }
  } elsif ($option =~ m/dev2/i) { 
    if ($func =~ m/enable/i) {
      $ENABLEDEV2 = "true";
    } else {
      $ENABLEDEV2 = "false";
    }
  } elsif ($option =~ m/ppp/i) { 
    if ($func =~ m/enable/i) {
      $ENABLEPPP = "true";
    } else {
      $ENABLEPPP = "false";
    }
  } elsif ($option =~ m/xmms/i) { 
    if ($func =~ m/enable/i) {
      $ENABLEXMMS = "true";
    } else {
      $ENABLEXMMS = "false";
    }
  } elsif ($option =~ m/res/i) {
    if ($func =~ m/enable/i) {
      $ENABLERES = "true";
    } else {
      $ENABLERES = "false";
    }
  } else {
    IRC::print "\0034$option Not Valid\0034\n";
    IRC::print "\002Valid options are:\002 fink, dev1, dev2, ppp, xmms, res\n";
  }
  SaveConfig();
  return 1;
}

sub LoadDefaults {
  IRC::print "\0034$configfile not found or not complete.\0034\n";
  IRC::print "\002Loading defaults for missing values and saving the file.\002\n";
  IRC::print "\002Please edit and modify it for your system.\002\n";

  unless ($ENABLERES) {
    $ENABLERES = "false";
  }

  unless ($ENABLEDEV1) {
    $ENABLEDEV1 = "true";
  }
  unless ($DEV1) {
    $DEV1 = "en0";
  }
  unless ($DEV1NAME) {
    $DEV1NAME = "EtherNet";
  }

  unless ($ENABLEDEV2) {
    $ENABLEDEV2 = "false";
  }
  unless ($DEV2) {
    $DEV2 = "en1";
  }
  unless ($DEV2NAME) {
    $DEV2NAME = "AirPort";
  }

  unless ($ENABLEPPP) {
    $ENABLEPPP = "false";
  }
  unless ($PPP) {
    $PPP = "ppp0";
  }
  unless ($PPPNAME) {
    $PPPNAME = "Internal Modem";
  }

  unless ($ENABLEXMMS) {
    $ENABLEXMMS = "false";
  }
  unless ($DISPLAYLEVEL) {
    $DISPLAYLEVEL = "3";
  }

  unless ($ENABLEFINK) {
    $ENABLEFINK = "false";
  }
  unless ($BASEPATH) {
    $BASEPATH = "/sw";
  }

  ShowConfig();
  SaveConfig();
  return 1;
}

sub LoadConfig {
  my @values;
  unless (-e "$configfile") {
    LoadDefaults();
    return 1;
  }

  open (FD,"<$configfile");
  foreach(<FD>) {
    @values = split(/=/, $_);
    if ($values[1]) {
      chomp($values[1]);
    }
    if ($values[0] eq "enabledev1") {
      $ENABLEDEV1 = $values[1];
    } elsif ($values[0] eq "dev1") {
      $DEV1 = $values[1];
    } elsif ($values[0] eq "dev1name") {
      $DEV1NAME = $values[1];
    } elsif ($values[0] eq "enabledev2") {
      $ENABLEDEV2 = $values[1];
    } elsif ($values[0] eq "dev2") {
      $DEV2 = $values[1];
    } elsif ($values[0] eq "dev2name") {
      $DEV2NAME = $values[1];
    } elsif ($values[0] eq "enableppp") {
      $ENABLEPPP = $values[1];
    } elsif ($values[0] eq "ppp") {
      $PPP = $values[1];
    } elsif ($values[0] eq "pppname") {
      $PPPNAME = $values[1];
    } elsif ($values[0] eq "enablefink") {
      $ENABLEFINK = $values[1];
    } elsif ($values[0] eq "basepath") {
      $BASEPATH = $values[1];
    } elsif ($values[0] eq "displaylevel") {
      $DISPLAYLEVEL = $values[1];
    } elsif ($values[0] eq "enableres") {
      $ENABLERES = $values[1];
    }
  }
  close(FD);
  unless ($ENABLEDEV1 & $DEV1 & $DEV1NAME & $ENABLEDEV2 & $DEV2 &
          $DEV2NAME & $ENABLEPPP & $PPP & $PPPNAME & $ENABLEFINK &
          $BASEPATH & $DISPLAYLEVEL & $ENABLERES) {
    IRC::print "\0034Config file missing entries, self repair.\002";
    LoadDefaults();
  } else {
    IRC::print "\002Configuration loaded\002\n";
    return 1;
  }
}

sub SaveConfig {
  open (FD, ">$configfile");
    print(FD "enabledev1=$ENABLEDEV1\n");
    print(FD "dev1=$DEV1\n");
    print(FD "dev1name=$DEV1NAME\n\n");
    print(FD "enabledev2=$ENABLEDEV2\n");
    print(FD "dev2=$DEV2\n");
    print(FD "dev2name=$DEV2NAME\n\n");      
    print(FD "enableppp=$ENABLEPPP\n");
    print(FD "ppp=$PPP\n");
    print(FD "pppname=$PPPNAME\n\n");
    print(FD "enablexmms=$ENABLEXMMS\n");
    print(FD "displaylevel=$DISPLAYLEVEL\n\n");
    print(FD "enablefink=$ENABLEFINK\n");
    print(FD "basepath=$BASEPATH\n\n");
    print(FD "enableres=$ENABLERES\n\n");
  close(FD);
  IRC::print "\002Configuration saved\002\n";
  return 1;
}

sub ShowConfig {
  IRC::print "\n\002\0034$scriptname $version\0034\002\n";
  IRC::print "   \0034SysInfo\0034\n";   
  IRC::print "      \002Res:\002 $ENABLERES\n";
  IRC::print "   \0034Device 1\0034\n";
  IRC::print "      \002Enabled:\002 $ENABLEDEV1\n";
  if ($ENABLEDEV1 =~ m/true/i) {
    IRC::print "      \002Device:\002 $DEV1\n";
    IRC::print "      \002Name:\002 $DEV1NAME\n";
  }
  IRC::print "   \0034Device 2\0034\n";
  IRC::print "      \002Enabled:\002 $ENABLEDEV2\n";
  if ($ENABLEDEV2 =~ m/true/i) {
    IRC::print "      \002Device:\002 $DEV2\n";
    IRC::print "      \002Name:\002 $DEV2NAME\n";
  }
  IRC::print "   \0034PPP\0034\n";      
  IRC::print "      \002Enabled:\002 $ENABLEPPP\n";
  if ($ENABLEPPP =~ m/true/i) {
    IRC::print "      \002Device:\002 $PPP\n";
    IRC::print "      \002Name:\002 $PPPNAME\n";
  }
  IRC::print "   \0034XMMS\0034\n";
  IRC::print "      \002Enabled:\002 $ENABLEXMMS\n";
  if ($ENABLEXMMS =~ m/true/i) {
    IRC::print "      \002Display Level:\002 $DISPLAYLEVEL\n";
  }
  IRC::print "   \0034Fink\0034\n";
  IRC::print "      \002Enabled:\002 $ENABLEFINK\n";
  if ($ENABLEFINK =~ m/true/i) {
    IRC::print "      \002Base Path:\002 $BASEPATH\n";
  }

  return 1;
}

sub get_uname {
  chomp($UNAME = `/usr/bin/uname -sr`);
}

sub get_cpu {
  chomp($ARCH = `uname -p`);
  if ($ARCH =~ /^powerpc/i) {
    $ARCH = "PowerPC";
  } elsif ($ARCH =~ /^86/i) {
    $ARCH = "x86";
  } else {
    $ARCH = "Unknown";
  }

  chomp($TYPE = `ioreg | grep $ARCH`);
  if ($TYPE =~ /.+$ARCH,(.+)@.+/) {
    $TYPE = $1;
  } else {
    $TYPE = "Unknown";
  }

  my $truetype;
  if ($TYPE eq "750") {
    $truetype = "G3";
  } else {
    $truetype = $TYPE;
  }

  chomp($NUM=`sysctl hw.ncpu`);
  $NUM =~ s/hw.ncpu = //;
  if ($NUM eq 1 ) {
    $MODEL = "$ARCH/$truetype";
  } elsif ($NUM eq 2) {
    $MODEL="Dual $ARCH/$truetype";
  } elsif ($NUM gt 2) {
    $MODEL="Multi $ARCH/$truetype";
  } else {
    $MODEL = "#? $ARCH/$truetype";
  }

  chomp($CPU = `ioreg -n $ARCH,$TYPE | grep '"clock-frequency" ='`);
  if ($CPU =~ /.*[<](.+)[>].*/) {
    $CPU = hex($1)/1000000;
    if ($CPU gt 999) {
      $CPU = sprintf("%.0fGHz", $CPU/1000);
    } else {
      $CPU = sprintf("%.0fMHz", $CPU);
    }
  } else {
    $CPU = "Unknown ($CPU)";
  }
}

sub get_mem {
  chomp($MEMTOTAL = `sysctl hw.physmem`);
  $MEMTOTAL =~ s/hw.physmem = //;

  chomp($MEMUSED = `top -l1 | grep PhysMem`);
  $MEMUSED =~ /.*[,](.+)([GKM]) used.*/;
  $MEMUSED = $1;
  $MEMGKM = $2;
  $MEMUSED =~ s/ //g;
  if ($MEMGKM =~ /^K$/) {
    $MEMTOTAL = sprintf("%.0f", $MEMTOTAL/1024);  
  } elsif ($MEMGKM =~ /^M$/) {
    $MEMTOTAL = sprintf("%.0f", $MEMTOTAL/1024**2);
  } elsif ($MEMGKM =~ /^G$/) {
    $MEMTOTAL = sprintf("%.2f", $MEMTOTAL/1024**3);  
  }

  $MEMPERCENT = $MEMUSED/$MEMTOTAL*100;
  if (int($MEMPERCENT) == int($MEMPERCENT + .5)) {
    $MEMPERCENT = int($MEMPERCENT);
  } else {
    $MEMPERCENT = int($MEMPERCENT + .5);
  }

  if ($MEMGKM =~ /^K$/) {
    $MEMUSED .= "KB";
    $MEMTOTAL .= "KB";
  } elsif ($MEMGKM =~ /^G$/) {
    $MEMUSED .= "GB";
    $MEMTOTAL .= "GB";
  } else {
    $MEMUSED .= "MB";
    $MEMTOTAL .= "MB";
  }
}

sub get_ppp {
}

sub get_net {
  $DEV1TYPE=`dmesg | grep $DEV1: | head -n1 | cut -d"<" -f2 | cut -d">" -f1`;
  chop($DEV1TYPE);

  if ($DEV1TYPE =~ /^$/) {
      $DEV1TYPE=$DEV1NAME;
  }

  if ($DEV2) {
    $DEV2TYPE=`dmesg | grep $DEV2: | head -n1 | cut -d"<" -f2 | cut -d">" -f1`;
    chop($DEV2TYPE);

    if ($DEV2TYPE =~ /^$/) {
        $DEV2TYPE=$DEV2NAME;
    }
  }

  $PACKIN1 = `netstat -i -n -b | grep $DEV1 | head -n1 | awk '{print \$7}'`;
  if ($PACKIN1 < 1024**3) {
    $PACKIN1 = sprintf("%.02f",$PACKIN1 / 1024**2)."MB";
  } else {
    $PACKIN1 = sprintf("%.02f", $PACKIN1 / 1024**3)."GB";
  }

  if ($DEV2) {
    $PACKIN2 = `netstat -i -n -b | grep $DEV2 | head -n1 | awk '{print \$7}'`; 
    if ($PACKIN2 < 1024**3) {
      $PACKIN2 = sprintf("%.02f",$PACKIN2 / 1024**2)."MB";
    } else {
      $PACKIN2 = sprintf("%.02f", $PACKIN2 / 1024**3)."GB";
    }
  }

  $PACKOUT1 = `netstat -i -n -b | grep $DEV1 | head -n1 | awk '{print \$10}'`;
  if ($PACKOUT1 < 1024**3) {
    $PACKOUT1 = sprintf("%.02f",$PACKOUT1 / 1024**2)."MB";
  } else {
    $PACKOUT1 = sprintf("%.02f", $PACKOUT1 / 1024**3)."GB";
  }

  if ($DEV2) {
    $PACKOUT2 = `netstat -i -n -b | grep $DEV2 | head -n1 | awk '{print \$10}'`;
    if ($PACKOUT2 < 1024**3) {
      $PACKOUT2 = sprintf("%.02f",$PACKOUT2 / 1024**2)."MB";
    } else {
      $PACKOUT2 = sprintf("%.02f", $PACKOUT2 / 1024**3)."GB";
    }
  }
}

sub get_rez {
  chomp($RES = `xdpyinfo | grep dimensions`);   
  $RES =~ /dimensions: (.+) pixels.*/;         
  $RES = $1;  
  $RES =~ s/ //g;     
  unless ($RES) {
    $RES = "X11 not running";
  }
}

sub get_hdd {
  my @hddlist = `/bin/df -l`;
  my $hddline;
  my ($hddtotal, $hddused, $hddcount) = (0, 0, 0);

  foreach $hddline (@hddlist) {
    chomp($hddline);
    if ($hddline =~ /^\/dev\S+\ +([0-9.]+)\ +([0-9.]+)\ +([0-9.]+)\ .+[\%].*$/) {
      if ($3 != 0) {
        $hddcount++;
        $hddtotal += sprintf("%.2f", $1/2);
        $hddused += sprintf("%.2f", $2/2);
      }
    }
  }

  if ($hddtotal >= 1024**3) {
    $hddtotal = sprintf("%.2fTB", $hddtotal/1024**3);
    $hddused = sprintf("%.2fTB", $hddused/1024**3);
  } elsif ($hddtotal >= 1024**2) {
    $hddtotal = sprintf("%.2fGB", $hddtotal/1024**2);
    $hddused = sprintf("%.2fGB", $hddused/1024**2);
  } elsif ($hddtotal >= 1024*1024) {
    $hddtotal = sprintf("%.2fMB", $hddtotal/1024**1);
    $hddused = sprintf("%.2fMB", $hddused/1024**1);
  } elsif ($hddtotal >= 1024) {
    $hddtotal = sprintf("%.2fKB", $hddtotal/1024);
    $hddused = sprintf("%.2fKB", $hddused/1024);
  } else {
    $hddtotal = sprintf("%.2fB", $hddtotal);
    $hddused = sprintf("%.2fB", $hddused);
  }
  $HDDTOTAL = $hddtotal;
  $HDDUSED = $hddused;
  $HDDCOUNT = $hddcount;
}

sub get_procs {
  chomp($PROCS = `top -l1 | grep Processes`);
  $PROCS =~ /Processes: (.+) total.*/;
  $PROCS = $1;
  $PROCS =~ s/ //g;
}

sub get_uptime {
  my $days;

  chomp($UPTIME = `uptime`);
  $UPTIME =~ /.*up (.+),.+[0-9]+ user/;
  $days = $1;
  if ($days =~ /\s{0,1}([0-9.]+)\s{0,1}days{0,1}, (.+):(.+)/) {
    $UPTIME = sprintf("%dd, %dh, %dm", $1, $2, $3);
  } elsif ($days =~ /\s{0,1}([0-9.]+)\s{0,1}days{0,1}, (.+)\s{0,1}hrs{0,1}/) {
    $UPTIME = sprintf("%dd, %dh", $1, $2);
  } elsif ($days =~ /\s{0,1}([0-9.]+)\s{0,1}days{0,1}, (.+)\s{0,1}mins{0,1}/) {
    $UPTIME = sprintf("%dd, %dm", $1, $2); 
  } elsif ($days =~ /\s{0,2}(.+):(.+)/) {
    $UPTIME = sprintf("%dh, %dm", $1, $2);
  } elsif ($days =~ /\s{0,1}(.+) mins{0,1}/) {
    $UPTIME = sprintf("%dm", $1);
  } else {
    $UPTIME = "Not Currently Available ($days)";
  }
}

sub build_output {
  $out = "\002SysInfo\002";
  $out .= " \002|\002 System: \002$UNAME\002";
  $out .= " \002|\002 CPU: \002$MODEL\002 @ \002$CPU\002";
  $out .= " \002|\002 RAM: \002$MEMUSED\002 of \002$MEMTOTAL\002 (\002$MEMPERCENT% \002used)";
  $out .= " \002|\002 Disk(s)/Partion(s): \002$HDDCOUNT\002";
  $out .= " \002|\002 Space: \002$HDDUSED\002 of \002$HDDTOTAL\002 used";
  if ($ENABLERES =~ m/true/i) {
    $out .= " \002|\002 Screen Res: \002$RES\002";
  }
  $out .= " \002|\002 Procs: \002$PROCS\002";
  $out .= " \002|\002 Uptime: \002$UPTIME\002";
  if ($ENABLEDEV1 =~ m/true/i) {
    $out .= " \002|\002 $DEV1TYPE: In: \002$PACKIN1\002 Out: \002$PACKOUT1\002";
  }
  if ($ENABLEDEV2 =~ m/true/i) {
    $out .= " \002|\002 $DEV2TYPE: In: \002$PACKIN2\002 Out: \002$PACKOUT2\002";
  }
}

sub get_osxinfo {
  my @sw_vers = `sw_vers`;
  my ($infoline, $value);
  my $counter = 0;

  foreach $infoline (@sw_vers) {
    chomp($infoline);
    if ($infoline =~ /.+:\s?\s?\s?(.+)/) {
      $value = $1;
      $counter++;
      if ($counter eq 1) {
        $OSX = $value;
      } elsif ($counter eq 2) {
        $OSXVERS = $value;
      } elsif ($counter eq 3) {
        $OSXBUILD = $value;
      }
    }
  }
}

sub get_darwininfo {
}

sub get_finkinfo {
  my @fink_vers = `$BASEPATH/bin/fink --version`;
  my @fink_pkgs = `$BASEPATH/bin/fink list -i`;
  my @fink_config = `cat $BASEPATH/etc/fink.conf`;
  my ($infoline, $value);

  $FINKPKGS = 0;
  foreach $infoline (@fink_pkgs) {
    chomp($infoline);
    if ($infoline =~ /^[\(|\s]i.*$/) {
      $FINKPKGS++;
    }
  }

  foreach $infoline (@fink_config) {
    chomp($infoline);
    if ($infoline =~ /^Trees: (.*)$/) {
      $FINKTREE = $1;
    }
  }

  foreach $infoline (@fink_vers) {
    chomp($infoline);
    if ($infoline =~ /^(.+): (.+)/) {
      $value = $2;
      if ($1 =~ /^Package/i) {
        $FINKVERS = $value;
      } elsif ($1 =~ /^Distribution/i) {
        $DISTVERS = $value;
      }
    }
    $FINKVERS =~ s/ //g;
    $DISTVERS =~ s/ //g; 
  }
}

sub get_devinfo {
  $TOOLVERS = "Unknown";
  $TOOLBUILD = "Unknown";
  $GCCVERS = "Unknown";

  my @gcc_vers = `cc --version`;
  my @dev_vers = `cat \"/Developer/Applications/Project\ Builder.app/Contents/Resources/English.lproj/DevCDVersion.plist\"`;

  my ($infoline, $value);

  if (-e "/Developer") {
    $DEVTOOLS = "Installed";
  } else {
    $DEVTOOLS = "N/A";
  }

  foreach $infoline (@dev_vers) {
    chomp($infoline);
    if ($infoline =~ /^.* = "(.*)";/) {
      $TOOLVERS = "$1";
    }
  }

  foreach $infoline (@gcc_vers) {
    chomp($infoline);
    if ($infoline =~ /^cc \(GCC\) ([0-9.]+.*)/) {
      $GCCVERS = $1;
    } elsif ($infoline =~ /^([0-9.]+)/) {
      $GCCVERS = $1;
    }
  }
}

sub build_finkout {
  $out = "\002FinkInfo\002";
  $out .= " \002|\002 System: \002$OSX\002";
  $out .= " \002|\002 Version: \002$OSXVERS\002";
  $out .= " \002|\002 Build: \002$OSXBUILD\002";
  $out .= " \002|\002 Basepath: \002$BASEPATH\002";
  $out .= " \002|\002 Package Manager: \002$FINKVERS\002";
  $out .= " \002|\002 Distribution: \002$DISTVERS\002";
  $out .= " \002|\002 Packages Installed: \002$FINKPKGS\002";                      
  $out .= " \002|\002 Trees: \002$FINKTREE\002";
  $out .= " \002|\002 Dev Tools: \002$DEVTOOLS\002";
  if ($DEVTOOLS =~ m/installed/i) {
    $out .= " \002|\002 Tools Version: \002$TOOLVERS\002";
    $out .= " \002|\002 Tools Build: \002$TOOLBUILD\002";
    $out .= " \002|\002 GCC Version: \002$GCCVERS\002";
  }
}

sub get_song {
  my $remote = Xmms::Remote->new;

  my ($no_tag, $file_ext);

  my $play_pos = $remote->get_playlist_pos;
  my $song_name = $remote->get_playlist_title($play_pos);
  my $song_time = $remote->get_playlist_timestr($play_pos);
  my $song_file = $remote->get_playlist_file($play_pos);
  unless (-e $song_file) {
    return 1;
  }
  my $tag = get_mp3tag($song_file) or $no_tag = 1;
  my $info = get_mp3info($song_file);
  my $inf_freq = $info->{FREQUENCY};
  my $inf_bitrate = $info->{BITRATE};
  my $inf_stereo = $info->{STEREO};
  my $inf_title = $tag->{TITLE};
  my $inf_artist = $tag->{ARTIST};
  my $inf_album = $tag->{ALBUM};
  my $inf_genre = $tag->{GENRE};

  my $play_pos_disp = $play_pos+1;

  $out = "\002$inf_artist\002 - \002$inf_title\002";

  if (($inf_artist ne "") || ($inf_title ne "")) {
    $no_tag = 0;
  }
  if (($inf_artist eq "") || ($inf_title eq "")) {
    $no_tag = 2;
    my $pos_s = rindex ($song_file, "/");
    $pos_s++;
    my $pos_e = rindex ($song_file, ".");
    my $len_e = length ($song_file) - $pos_e + 1;
    my $len_s = length ($song_file) - $pos_s - $len_e + 1;
    my $leng = length ($song_file);
    $file_ext = substr ($song_file, $pos_e + 1);
    $file_ext =~ tr/a-z/A-Z/;
    $song_file = substr ($song_file, $pos_s, $len_s);
  }
  if ($no_tag == 1) {
    $out = "\002$song_name\002";
  }
  if ($no_tag == 2) {
    $out = "\002$song_file\002";
    if (($song_file eq "") && ($song_name ne "")) {
      $out = "\002$song_name\002";
    }
    if (($file_ext ne "MP3") && ($file_ext ne "MP2") &&
        ($file_ext ne "MPG") && ($song_name ne "")) {
      $out = "\002$song_name\002 (\002$file_ext\002)";
    }
  }

  if ($song_time ne "0:00") {
    $out .= " (\002$song_time\002)";
  }
  if (($DISPLAYLEVEL == 1) || ($DISPLAYLEVEL == 3)) {
    if ($inf_freq ne "") {
      if ($inf_stereo == 1) {
        $out .= " (\002$inf_freq\\KHz\002/\002$inf_bitrate\\Kbs\002/\002ST\002)";
      } else {
        $out .= " (\002$inf_freq\\KHz\002/\002$inf_bitrate\\Kbs\002/\002Mon\002)";
      }
    }
  }
  if (($DISPLAYLEVEL == 2) || ($DISPLAYLEVEL == 3)) {
    if ($inf_album ne "") {
      $out .= " (Album: \002$inf_album\002)";
    }
    if (($inf_genre ne "") && ($inf_genre ne "Other") &&
        ($inf_genre ne "genre")) {
      $out .= " (Genre: \002$inf_genre\002)";
    }
  }
}

sub display_uptime {
  get_uname();    

  unless ($UNAME =~ m/darwin/i) {
    IRC::print "\0034System Unsupported, install Darwin and try again...\0034\n";
    return 1;
  }

  get_uptime();

  $out = "My current uptime is \002$UPTIME\002".".";

  IRC::command("/say $out");
  return 1;
}

sub display_fink {
  get_uname();

  unless ($ENABLEFINK =~ m/true/i) {
    IRC::print "\0034Fink reporting is currently disabled, /enable fink to enable it.\0034\n";
    return 1;
  }

  unless ($UNAME =~ m/darwin/i) {
    IRC::print "\0034System Unsupported, install Darwin and try again...\0034";
    return 1;
  }

  unless (-f $BASEPATH."/bin/fink") {
    IRC::print "\0034Fink Not Installed, you can get Fink at http://fink.sf.net/\0034\n";
    IRC::print "\0034Or your base path is incorrectly set, /conf basepath <location>\0034\n";
    return 1;
  }

  if (-f "/usr/bin/sw_vers") {
    get_osxinfo();
  } else {
    get_darwininfo();
  }

  get_finkinfo();
  get_devinfo();

  build_finkout();

  IRC::command("/say $out");
  return 1;
}

sub display_info {
  get_uname();

  unless ($ENABLEXMMS =~ m/true/i) {
    IRC::print "\0034XMMS reporting is currently disabled, /enable xmms to enable it.\0034\n";
    return 1;
  }

  unless ($UNAME =~ m/darwin/i) {
    IRC::print "\0034System Unsupported, install Darwin and try again...\0034";
    return 1;
  }

  get_cpu();
  get_mem();
  get_net();
  if ($ENABLEPPP =~ m/true/i) {
    get_ppp();
  }
  get_rez();
  get_hdd();
  get_procs();
  get_uptime();

  build_output();

  IRC::command("/say $out");
  return 1;
}

sub display_song {
  get_uname();

  unless ($UNAME =~ m/darwin/i) {

    IRC::print "\0034System Unsupported, install Darwin and try again...\0034";
    return 1;
  }

  eval { require Xmms; require Xmms::Remote;};
  if ($@) {
    IRC::print "\0034Install Xmms:: from CPAN then try again!\n\0034";
    return 1;
  }

  eval { require MP3::Info; };
  if ($@) {
    IRC::print "\0034Install MP3::Info from CPAN then try again!\n\0034";
    return 1;
  } else {
    import MP3::Info qw(:genres);
    import MP3::Info qw(:DEFAULT :genres);
    import MP3::Info qw(:all);
  }

  get_song();

  if (length($out) < 5) {
    IRC::print "\0034Must have XMMS running at least!\n";
    return 1;
  }
  IRC::command("/me plays $out in xmms.");
  return 1;
}
