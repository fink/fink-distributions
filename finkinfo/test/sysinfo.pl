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

my $DEV = "en0";		## EtherNet
my $DEVNAME = "EtherNet";	## EtherNet
my $DEV2 = "en1";		## AirPort
my $DEVNAME2 = "AirPort";	## AirPort

# DON'T TOUCH BELLOW THIS POINT
# -----------------------------------------------------------------

my $out;
my $UNAME;
my $ARCH, $TYPE, $MODEL, $NUM, $CPU;
my $MEMTOTAL, $MEMUSED, $MEMGKM, $MEMPERCENT;
my $DEVTYPE, $DEVTYPE2, $PACKIN, $PACKIN2, $PACKOUT, $PACKOUT2;
my $RES;
my $HDDTOTAL, $HDDUSED, $HDDCOUNT;
my $PROCS;
my $UPTIME, $DAYS;

IRC::register("Darwin SysInfo", "0.2", "", "");
IRC::print "Loading Darwin SysInfo Script";
IRC::add_command_handler("sys", "display_info");
IRC::add_command_handler("up", "display_uptime");

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

  chomp($CPU = `ioreg -n $ARCH,$TYPE | grep clock-frequency`);
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
    $MEMTOTAL = sprintf("%.0f", $MEMTOTAL/1024**3);  
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

sub get_net {
  $DEVTYPE=`dmesg | grep $DEV: | head -n1 | cut -d"<" -f2 | cut -d">" -f1`;
  chop($DEVTYPE);

  if ($DEVTYPE =~ /^$/) {
      $DEVTYPE=$DEVNAME;
  }

  if ($DEV2) {
    $DEVTYPE2=`dmesg | grep $DEV2: | head -n1 | cut -d"<" -f2 | cut -d">" -f1`;
    chop($DEVTYPE2);

    if ($DEVTYPE2 =~ /^$/) {
        $DEVTYPE2=$DEVNAME2;
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
  chomp($RES = `xdpyinfo | grep dimensions`);   
  $RES =~ /dimensions: (.+) pixels.*/;         
  $RES = $1;  
  $RES =~ s/ //g;     
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
  chomp($UPTIME = `uptime`);
  $UPTIME =~ /.*up (.+),.+[0-9]+ user/;
  $DAYS = $1;
  if ($DAYS =~ /.?(.+).?days, (.+):(.+)/) {
    $UPTIME = sprintf("%dd, %dh, %dm", $1, $2, $3);
  } elsif ($DAYS =~ /.?(.+).?days, (.+).?hrs/) {
    $UPTIME = sprintf("%dd, %dh", $1, $2);
  } elsif ($DAYS =~ /.?.?(.+):(.+)/) {
    $UPTIME = sprintf("%dh, %dm", $1, $2);
  } elsif ($DAYS =~ /.?(.+) mins/) {
    $UPTIME = sprintf("%dm", $1);
  } else {
    $UPTIME = "Not Currently Available ($DAYS)";
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
  $out .= " %B|%O $DEVTYPE: In: %B$PACKIN%O Out: %B$PACKOUT%O";
  if ($DEV2) {
    $out .= " %B|%O $DEVTYPE2: In: %B$PACKIN2%O Out: %B$PACKOUT2%O";
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
