#!/usr/bin/perl
# -----------------------------------------------------------------
# Based on:
# kc8apf's sysinfo v0.6 for x-chat
# Avaliable at http://www.kc8apf.net/sysinfo/sysinfo.pl
# Author: <kc8apf@kc8apf.net>
# usage : /sys, /up, /fink, /playing, /saveinfo, /showinfo, /loadinfo
#         /enable <option>, /conf <option> <value>
# -----------------------------------------------------------------

my $out;
my ($ENABLEDEV1, $ENABLEDEV2, $ENABLEPPP, $ENABLEFINK);
my ($DEV1, $DEV1NAME, $DEV2, $DEV2NAME, $PPP, $PPPNAME);
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

IRC::print "Loading Darwin SysInfo Script\n";

# Try to load the config
LoadConfig();

IRC::register("Darwin SysInfo", "0.2", "", "");

IRC::add_command_handler("loadinfo", LoadConfig);
IRC::add_command_handler("saveinfo", SaveConfig);
IRC::add_command_handler("showinfo", ShowConfig);
IRC::add_command_handler("sys", display_info);
IRC::add_command_handler("up", display_uptime);
IRC::add_command_handler("fink", display_fink);

sub LoadConfig {
  open (FD,"<$ENV{HOME}/.xchat/sysinfo.conf");
  foreach(<FD>) {
    @values = split(/=/, $_);
    chomp($values[1]);
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
    }
  }
  close(FD);
  IRC::print "Configuration loaded\n";
}

sub SaveConfig {
  open (FD, ">$ENV{HOME}/.xchat/sysinfo.conf");
    print(FD "enabledev1=\"$ENABLEDEV1\"\n");
    print(FD "dev1=\"$DEV1\"\n");
    print(FD "dev1name=\"$DEV1NAME\"\n\n");
    print(FD "enabledev2=\"$ENABLEDEV2\"\n");
    print(FD "dev2=\"$DEV2\"\n");
    print(FD "dev2name=\"$DEV2NAME\"\n\n");      
    print(FD "enableppp=\"$ENABLEPPP\"\n");
    print(FD "ppp=\"$PPP\"\n");
    print(FD "pppname=\"$PPPNAME\"\n\n");
    print(FD "enablefink=\"$ENABLEFINK\"\n");
    print(FD "basepath=\"$BASEPATH\"\n");
  close(FD);
  IRC::print "Configuration saved\n";
}

sub ShowConfig {
  IRC::print "\nDarwin SysInfo\n";
  IRC::print "   Device 1\n";
  IRC::print "      Enabled: $ENABLEDEV1\n";
  if ($ENABLEDEV1 =~ m/true/i) {
    IRC::print "      Device: $DEV1\n";
    IRC::print "      Name: $DEV1NAME\n";
  }
  IRC::print "   Device 2\n";
  IRC::print "      Enabled: $ENABLEDEV2\n";
  if ($ENABLEDEV2 =~ m/true/i) {
    IRC::print "      Device: $DEV2\n";
    IRC::print "      Name: $DEV2NAME\n";
  }
  IRC::print "   PPP\n";      
  IRC::print "      Enabled: $ENABLEPPP\n";
  if ($ENABLEPPP =~ m/true/i) {
    IRC::print "      Device: $PPP\n";
    IRC::print "      Name: $PPPNAME\n";
  }
  IRC::print "   Fink\n";
  IRC::print "      Enabled: $ENABLEFINK\n";
  if ($ENABLEFINK =~ m/true/i) {
    IRC::print "      Base Path: $BASEPATH\n";
  }

  return 1;
}

sub get_uname {
  chomp($UNAME = `uname -sr`);
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
    $MEMUSED .= "Kb";
    $MEMTOTAL .= "Kb";
  } elsif ($MEMGKM =~ /^G$/) {
    $MEMUSED .= "Gb";
    $MEMTOTAL .= "Gb";
  } else {
    $MEMUSED .= "Mb";
    $MEMTOTAL .= "Mb";
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
    $PACKIN1 = sprintf("%.02f",$PACKIN1 / 1024**2)."Mb";
  } else {
    $PACKIN1 = sprintf("%.02f", $PACKIN1 / 1024**3)."Gb";
  }

  if ($DEV2) {
    $PACKIN2 = `netstat -i -n -b | grep $DEV2 | head -n1 | awk '{print \$7}'`; 
    if ($PACKIN2 < 1024**3) {
      $PACKIN2 = sprintf("%.02f",$PACKIN2 / 1024**2)."Mb";
    } else {
      $PACKIN2 = sprintf("%.02f", $PACKIN2 / 1024**3)."Gb";
    }
  }

  $PACKOUT1 = `netstat -i -n -b | grep $DEV1 | head -n1 | awk '{print \$10}'`;
  if ($PACKOUT1 < 1024**3) {
    $PACKOUT1 = sprintf("%.02f",$PACKOUT1 / 1024**2)."Mb";
  } else {
    $PACKOUT1 = sprintf("%.02f", $PACKOUT1 / 1024**3)."Gb";
  }

  if ($DEV2) {
    $PACKOUT2 = `netstat -i -n -b | grep $DEV2 | head -n1 | awk '{print \$10}'`;
    if ($PACKOUT2 < 1024**3) {
      $PACKOUT2 = sprintf("%.02f",$PACKOUT2 / 1024**2)."Mb";
    } else {
      $PACKOUT2 = sprintf("%.02f", $PACKOUT2 / 1024**3)."Gb";
    }
  }
}

sub get_rez {
  chomp($RES = `xdpyinfo | grep dimensions`);   
  $RES =~ /dimensions: (.+) pixels.*/;         
  $RES = $1;  
  $RES =~ s/ //g;     
  if (!$RES) {
    $RES = "X11 not running";
  }
}

sub get_hdd {
  my @hddlist = `df -l -x volfs -x fdesc -x devfs -x hsfs -x cdfs`;
  my $hddline;
  my ($hddtotal, $hddused, $hddcount) = (0, 0, 0);

  foreach $hddline (@hddlist) {
    chomp($hddline);
    if ($hddline =~ /^\/dev\S+\ +([0-9.]+)\ +([0-9.]+)\ +([0-9.]+)\ .+[\%].*$/) {
      if ($3 != 0) {
        $hddcount++;
        $hddtotal += $1;
        $hddused += $2;
      }
    }
  }

  if ($hddtotal >= 1024**3) {
    $hddtotal = sprintf("%.2fTb", $hddtotal/1024**3);
    $hddused = sprintf("%.2fTb", $hddused/1024**3);
  } elsif ($hddtotal >= 1024**2) {
    $hddtotal = sprintf("%.2fGb", $hddtotal/1024**2);
    $hddused = sprintf("%.2fGb", $hddused/1024**2);
  } elsif ($hddtotal >= 1024*1024) {
    $hddtotal = sprintf("%.2fMb", $hddtotal/1024**1);
    $hddused = sprintf("%.2fMb", $hddused/1024**1);
  } elsif ($hddtotal >= 1024) {
    $hddtotal = sprintf("%.2fKb", $hddtotal/1024);
    $hddused = sprintf("%.2fKb", $hddused/1024);
  } else {
    $hddtotal = sprintf("%.2fb", $hddtotal);
    $hddused = sprintf("%.2fb", $hddused);
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
  $out = "%BSysInfo%O";
  $out .= " %B|%O System: %B$UNAME%O";
  $out .= " %B|%O CPU: %B$MODEL%O @ %B$CPU%O";
  $out .= " %B|%O RAM: %B$MEMUSED%O of %B$MEMTOTAL%O (%B$MEMPERCENT% %Oused)";
  $out .= " %B|%O Disk(s)/Partion(s): %B$HDDCOUNT%O";
  $out .= " %B|%O Space: %B$HDDUSED%O of %B$HDDTOTAL%O used";
  $out .= " %B|%O Screen Res: %B$RES%O";
  $out .= " %B|%O Procs: %B$PROCS%O";
  $out .= " %B|%O Uptime: %B$UPTIME%O";
  if ($ENABLEDEV1 =~ m/true/i) {
    $out .= " %B|%O $DEV1TYPE: In: %B$PACKIN1%O Out: %B$PACKOUT1%O";
  }
  if ($ENABLEDEV2 =~ m/true/i) {
    $out .= " %B|%O $DEV2TYPE: In: %B$PACKIN2%O Out: %B$PACKOUT2%O";
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
  my $fink_pkgs = `$BASEPATH/bin/fink list -i | wc -l`;
  my @fink_config = `cat $BASEPATH/etc/fink.conf`;
  my ($infoline, $value);

  $fink_pkgs =~ s/ //g;
  $FINKPKGS = sprintf("%s", $fink_pkgs-2);

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
    $DEVTOOL = "Installed";
  } else {
    $DEVTOOL = "N/A";
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
  $out = "%BFinkInfo%O";
  $out .= " %B|%O System: %B$OSX%O";
  $out .= " %B|%O Version: %B$OSXVERS%O";
  $out .= " %B|%O Build: %B$OSXBUILD%O";
  $out .= " %B|%O Basepath: %B$BASEPATH%O";
  $out .= " %B|%O Package Manager: %B$FINKVERS%O";
  $out .= " %B|%O Distribution: %B$DISTVERS%O";
  $out .= " %B|%O Packages Installed: %B$FINKPKGS%O";                      
  $out .= " %B|%O Trees: %B$FINKTREE%O";
  $out .= " %B|%O Dev Tools: %B$DEVTOOL%O";
  if ($DEVTOOLS = "installed") {
    $out .= " %B|%O Tools Version: %B$TOOLVERS%O";
    $out .= " %B|%O Tools Build: %B$TOOLBUILD%O";
    $out .= " %B|%O GCC Version: %B$GCCVERS%O";
  }
}

sub display_uptime {
  get_uname();    

  unless ($UNAME =~ /^darwin/i) {
    $out = "System Unsupported, install Darwin and try again...";
    IRC::command("/say $out");
    return 1;
  }

  get_uptime();

  $out = "My current uptime is %B$UPTIME%O".".";

  IRC::command("/say $out");
  return 1;
}

sub display_fink {
  get_uname();

  unless ($ENABLEFINK =~ m/true/i) {
    $out = "System Unsupported, install Darwin and try again...";
    IRC::command("/say $out");
    return 1;
  }

  unless ($UNAME =~ /^darwin/i) {
    $out = "System Unsupported, install Darwin and try again...";
    IRC::command("/say $out");
    return 1;
  }

  unless (-f $BASEPATH."/bin/fink") {
    $out = "Fink Not Installed, you can get Fink at http://fink.sf.net/";
    IRC::command("/say $out");
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

  unless ($UNAME =~ /^darwin/i) {
    $out = "System Unsupported, install Darwin and try again...";
    IRC::command("/say $out");
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
