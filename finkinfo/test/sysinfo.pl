#!/usr/bin/perl -w
# -----------------------------------------------------------------
# Based on:
# kc8apf's sysinfo v0.6 for x-chat
# Avaliable at http://www.kc8apf.net/sysinfo/sysinfo.pl
# Author: <kc8apf@kc8apf.net>
# usage : /sys
# -----------------------------------------------------------------
# YOU MUST ASSIGN THE VARIABLE BELOW TO SET YOUR INTERNET
# CONNECTION DEVICE

my $DEV = "en0";	## EtherNet
my $TYPE = "EtherNet";	## EtherNet
my $DEV2 = "en1";	## AirPort
my $TYPE2 = "AirPort";	## AirPort

# DON'T TOUCH BELLOW THIS POINT
# -----------------------------------------------------------------

my $out;
my $UNAME;
my $ARCH, $TYPE, $MODEL, $NUM, $HEXCPU, $CPU;
my $MEMTOTAL, $MEMUSED, $MEMUSEDGKM, $MEMPERCENT;
my $DEVTYPE, $DEVTYPE2, $PACKIN, $PACKIN2, $PACKOUT, $PACKOUT2;
my $RES;
my $HDD, $HDDFREE;
my $PROCS;
my $UPTIM, $DAYSE;

IRC::register("Darwin SysInfo", "0.2", "", "");
IRC::print "Loading Darwin SysInfo Script";
IRC::add_command_handler("sys", "display_info");
IRC::add_command_handler("up", "display_uptime");

sub get_uname {
  $UNAME = `uname -sr`;
  chop ($UNAME);
}

sub get_cpu {
  $ARCH = `uname -p`;
  chop($ARCH);

  if ($ARCH =~ /^powerpc/i) {
    $ARCH = "PowerPC";
  } elsif ($ARCH =~ /^86/i) {
    $ARCH = "x86";
  } else {
    $ARCH = "Unknown";
  }

  $TYPE = `ioreg | grep $ARCH | cut -d"," -f2 | cut -d"@" -f1 | head -1`;
  chop($TYPE);

  $MODEL = "$ARCH"."/"."$TYPE";
  $MODEL =~ s/^ +//;

  $NUM=`sysctl hw.ncpu | cut -d" " -f3`;
  chop($NUM);
  $NUM =~ s/^ +//;

  unless($NUM eq 1 ) { $MODEL="Dual $MODEL"; }
  chop ($MODEL);

  $HEXCPU = `ioreg -n $ARCH,$TYPE | grep clock-frequency | cut -d"<" -f2 | cut -d">" -f1`;
  chop($HEXCPU);
  $HEXCPU = hex($HEXCPU) / 1000000;
  $CPU = sprintf("%.0f"."MHz", $HEXCPU);
}

sub get_mem {
  $MEMTOTAL = `sysctl hw.physmem | cut -d" " -f3`;
  chop($MEMTOTAL);
  $MEMTOTAL = sprintf("%d",$MEMTOTAL/1024**2);

  $MEMUSED = `top -l1 | grep PhysMem | cut -d":" -f2 | cut -d"," -f4`;
  chop ($MEMUSED);
  $MEMUSED =~ / ([0-9.]+)([GKM]) used$/;
  $MEMUSED = $1;
  $MEMUSEDGKM = $2;      
  if ($MEMUSEDGKM =~ /^K$/) {
    $MEMUSED = $MEMUSED /  1024;
  } elsif ($MEMUSEDGKM =~ /^G$/) {
    $MEMUSED = $MEMUSED * 1024;
  }

  $MEMUSED = sprintf("%.0f", $MEMUSED);

  $MEMPERCENT = $MEMUSED/$MEMTOTAL*100;
  if (int($MEMPERCENT) == int($MEMPERCENT + .5)) {
    $MEMPERCENT = int($MEMPERCENT);
  } else {
    $MEMPERCENT = int($MEMPERCENT + .5);
  }

  if ($MEMUSEDGKM =~ /^K$/) {
    $MEMUSED .= "Kb";
    $MEMTOTAL .= "Kb";
  } elsif ($MEMUSEDGKM =~ /^G$/) {
    $MEMUSED .= "Gb";
    $MEMTOTAL .= "Gb";
  } else {
    $MEMUSED .= "Mb";
    $MEMTOTAL .= "Mb";
  }
}

sub get_net {
  $DEVTYPE=`dmesg | grep $DEV: | head -n1 | cut -d"<" -f2 | cut -d">" -f1`;
  chop($DEVTYPE);

  if ($DEVTYPE =~ /^$/) {
      $DEVTYPE=$TYPE;
  }

  if ($DEV2) {
    $DEVTYPE2=`dmesg | grep $DEV2: | head -n1 | cut -d"<" -f2 | cut -d">" -f1`;
    chop($DEVTYPE2);

    if ($DEVTYPE2 =~ /^$/) {
        $DEVTYPE2=$TYPE2;
    }
  }

  $PACKIN = `netstat -i -n -b | grep $DEV | head -n1 | awk '{print \$7}'`;
  if ($PACKIN < 1024**3) {
    $PACKIN = sprintf("%.02f",$PACKIN / 1024**2)."Mb";
  } else {
    $PACKIN = sprintf("%.02f", $PACKIN / 1024**3)."Gb";
  }

  if ($DEV2) {
    $PACKIN2 = `netstat -i -n -b | grep $DEV2 | head -n1 | awk '{print \$7}'`; 
    if ($PACKIN2 < 1024**3) {
      $PACKIN2 = sprintf("%.02f",$PACKIN / 1024**2)."Mb";
    } else {
      $PACKIN2 = sprintf("%.02f", $PACKIN / 1024**3)."Gb";
    }
  }

  $PACKOUT = `netstat -i -n -b | grep $DEV | head -n1 | awk '{print \$10}'`;
  if ($PACKOUT < 1024**3) {
    $PACKOUT = sprintf("%.02f",$PACKOUT / 1024**2)."Mb";
  } else {
    $PACKOUT = sprintf("%.02f", $PACKOUT / 1024**3)."Gb";
  }

  if ($DEV2) {
    $PACKOUT2 = `netstat -i -n -b | grep $DEV2 | head -n1 | awk '{print \$10}'`;
    if ($PACKOUT2 < 1024**3) {
      $PACKOUT2 = sprintf("%.02f",$PACKOUT / 1024**2)."Mb";
    } else {
      $PACKOUT2 = sprintf("%.02f", $PACKOUT / 1024**3)."Gb";
    }
  }
}

sub get_rez {
  $RES = `xdpyinfo | grep dimensions | cut -d\" \" -f7`;
  chop ($RES);
}

sub get_hdd {
  $HDD = `df -l -x tmpfs -x shm | awk '{ sum+=\$2/1024^2 }; END { printf (\"%dGb\\n\", sum )}'`;
  chop ($HDD);
   
  $HDDFREE = `df -l -x tmpfs -x shm | awk '{ sum+=\$4/1024^2 }; END { printf (\"%dGb\\n\", sum )}'`;
  chop ($HDDFREE);
}

sub get_procs {
  $PROCS = `ps ax | wc -l`;
  $PROCS =~ s/^\s+//;
  chop ($PROCS);
}

sub get_uptime {
  $UPTIME = `uptime`;
  chop ($UPTIME);
  $UPTIME =~ /.*up (.+),.+[0-9]+ user/;
  $DAYS = $1;
  if ($DAYS =~ /.?(.+).?days, (.+):(.+)/) {
    $UPTIME = sprintf("%sd, %dh, %dm", $1, $2, $3);
  } elsif ($DAYS =~ /.?.?(.+):(.+)/) {
    $UPTIME = sprintf("%dh, %dm", $1, $2);
  } else {
    $UPTIME = "Not Currently Available ($DAYS)";
  }
}

sub build_output {
  $out = "%BSysInfo%O";
  $out .= " %B|%O System: %B$UNAME%O";
  $out .= " %B|%O CPU: %B$MODEL%O @ %B$CPU%O";
  $out .= " %B|%O RAM: %B$MEMUSED%O of %B$MEMTOTAL%O (%B$MEMPERCENT% %Oused)";
  $out .= " %B|%O Free Disk: %B$HDDFREE%O of %B$HDD%O";
  $out .= " %B|%O Screen Res: %B$RES%O";
  $out .= " %B|%O Procs: %B$PROCS%O";
  $out .= " %B|%O Uptime: %B$UPTIME%O";
  $out .= " %B|%O $TYPE: In: %B$PACKIN%O Out: %B$PACKOUT%O";
  if ($DEV2) {
    $out .= " %B|%O $TYPE2: In: %B$PACKIN2%O Out: %B$PACKOUT2%O";
  }
}

sub display_uptime {
  get_uname();    

  if ($UNAME =~ /^darwin/i) {
    get_uptime();

    $out = "My current uptime is %B$UPTIME%O".".";

    IRC::command($out);
    return 0;
  } else {
    $out = "System Unsupported, install Darwin and try again...\n";
    IRC::command($out);
    return 1;
  }
}

sub display_info {
  get_uname();

  if ($UNAME =~ /^darwin/i) {
    get_cpu();
    get_mem();
    get_net();
    get_rez();
    get_hdd();
    get_procs();
    get_uptime();

    build_output();

    IRC::command($out);
    return 0;
  } else {
    $out = "System Unsupported, install Darwin and try again...\n";
    IRC::command($out);
    return 1;
  }
}
