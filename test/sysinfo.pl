#$Id: sysinfo.pl,v 1.5 2002/08/22 16:01:15 thesin Exp $

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

$DEV = "en0";   ## <-------------------------------CHANGE THAT
$DEV2 = "en1";

IRC::register("TheSin's sysinfo", "0.1", "", "");
IRC::print "Loading TheSin's sysinfo script";
IRC::add_command_handler("sys", "display_info");


sub display_info
{  
    
    #--UNAME--#
    $UNAME = `uname -sr`;
    chop ($UNAME);

  #--GET INFO ON FREEBSD--#
  if ($UNAME =~ /^freebsd/i) {
    #--MODEL--#
    $MODEL = `sysctl hw.model | cut -d":" -f2`;
    chop($MODEL);
    $MODEL =~ s/^ +//;

    #--HOW MANY CPUS--#
    $NUM=`sysctl hw.ncpu | cut -d":" -f2`;
    chop($NUM);
    $NUM =~ s/^ +//;

    #--PROCESSOR SPEED--#
    $CPU = `dmesg | grep CPU: | cut -d"(" -f2 | cut -d"-" -f1`;
    chop($CPU);

    #--TOTAL MEMORY--#
    $MEMTOTAL = `sysctl hw.physmem | cut -d":" -f2`;
    chop($MEMTOTAL);
    $MEMTOTAL = sprintf("%d",$MEMTOTAL/1024**2);

    #--MEMORY USED--#
    $MEMUSED = `top -b | grep Mem | cut -d":" -f2`;
    chop ($MEMUSED);
    $MEMUSED =~ /.+, ([0-9]+)([KM]) Cache, ([0-9]+)([KM]) Buf, ([0-9]+)([KM]) Free$/;
    $MEMCACHE = $1;
    $MEMCACHEKM = $2;
    $MEMBUF = $3;
    $MEMBUFKM = $4;
    $MEMUSED = $5;
    $MEMUSEDKM = $6;
    if ($MEMCACHEKM =~ /^K$/) {
       $MEMCACHE = $MEMCACHE / 1024;
    };
    if ($MEMBUFKM =~ /^K$/) {
       $MEMBUF = $MEMBUF / 1024;
    };
    if ($MEMUSEDKM =~ /^K$/) {
       $MEMUSED = $MEMUSED / 1024;
    };
    $MEMUSED = int($MEMUSED + $MEMBUF + $MEMCACHE);
    $MEMUSED = int($MEMTOTAL - $MEMUSED);

    #--LM_SENSORS #1--#
    $SENSOR1 = `/usr/local/bin/lmmon -i -p -s | head -n2 | tail -n1 | cut -d"/" -f2`;
    chop ($SENSOR1);
    $SENSOR1 =~ s/ +//;
    
    #--LM_SENSORS #2--#
    $SENSOR2 = `/usr/local/bin/lmmon -i -p -s | grep -A1 Fans: | tail -n1 | cut -d":" -f2`;
    chop ($SENSOR2);
    $SENSOR2 =~ s/ +//;

    #--CONNECTION DEVICE--# 
    $DEVTYPE=`dmesg | grep $DEV: | head -n1 | cut -d"<" -f2 | cut -d">" -f1`;
    chop($DEVTYPE);
    if ($DEVTYPE =~ /^$/) {
        $DEVTYPE="Unknown";
    };

    #--PACKETS IN--# 
    $PACKIN = `netstat -i -n -b | grep $DEV | head -n1 | awk '{print \$7}'`;
    if($PACKIN < 1024**3) { $PACKIN = sprintf("%.02f",$PACKIN / 1024**2)."M"; } else { $PACKIN = sprintf("%.02f", $PACKIN / 1024**3)."G"; }

    #--PACKETS OUT--# 
    $PACKOUT = `netstat -i -n -b | grep sis0 | head -n1 | awk '{print \$10}'`; 
    if($PACKOUT < 1024**3) { $PACKOUT = sprintf("%.02f",$PACKOUT / 1024**2)."M"; } else { $PACKOUT = sprintf("%.02f", $PACKOUT / 1024**3)."G"; }

  } elsif ($UNAME =~ /^darwin/i) {
  #--GET INFO ON DARWIN--#
    #--MODEL--#
    $ARCH = `uname -p`;
    chop($ARCH);
    if ($ARCH = "powerpc") {
      $ARCH = "PowerPC";
    } elsif ($ARCH = "i386") {
      $ARCH = "i386";
    } else {
      $ARCH = "Unknown";
    }
    $TYPE = `ioreg | grep $ARCH | cut -d"," -f2 | cut -d"@" -f1 | head -1`;
    chop($TYPE);
    $MODEL = "$ARCH"."/"."$TYPE @ ";
    $MODEL =~ s/^ +//;

    #--HOW MANY CPUS--#
    $NUM=`sysctl hw.ncpu | cut -d" " -f3`;
    chop($NUM);
    $NUM =~ s/^ +//;

    #--PROCESSOR SPEED--#
    $HEXCPU = `ioreg -n $ARCH,$TYPE | grep clock-frequency | cut -d"<" -f2 | cut -d">" -f1`;
    chop($HEXCPU);
    $HEXCPU = hex($HEXCPU) / 1000000;
    $CPU = sprintf("%.0f", $HEXCPU);

    #--TOTAL MEMORY--#
    $MEMTOTAL = `sysctl hw.physmem | cut -d" " -f3`;
    chop($MEMTOTAL);
    $MEMTOTAL = sprintf("%d",$MEMTOTAL/1024**2);

    #--MEMORY USED--#
    $MEMUSED = `top -l1 | grep PhysMem | cut -d":" -f2 | cut -d"," -f4`;
    chop ($MEMUSED);
    $MEMUSED =~ / ([0-9.]+)([GKM]) used$/;
    $MEMUSED = $1;
    $MEMUSEDGKM = $2;      
    if ($MEMUSEDGKM =~ /^K$/) {
       $MEMUSED = $MEMUSED /  1024;
    };
    if ($MEMUSEDGKM =~ /^G$/) {
       $MEMUSED = $MEMUSED * 1024;
    };
    $MEMUSED = sprintf("%.0f", $MEMUSED);

    #--CONNECTION DEVICE--#
    $DEVTYPE=`dmesg | grep $DEV: | head -n1 | cut -d"<" -f2 | cut -d">" -f1`;
    chop($DEVTYPE);
    if ($DEVTYPE =~ /^$/) {
        $DEVTYPE="EtherNet";
    };
    if ($DEV2) {
      $DEVTYPE2=`dmesg | grep $DEV2: | head -n1 | cut -d"<" -f2 | cut -d">" -f1`;
      chop($DEVTYPE2);
      if ($DEVTYPE2 =~ /^$/) {
          $DEVTYPE2="AirPort";
      };
    };

    #--PACKETS IN--#
    $PACKIN = `netstat -i -n -b | grep $DEV | head -n1 | awk '{print \$7}'`;
    if($PACKIN < 1024**3) { $PACKIN = sprintf("%.02f",$PACKIN / 1024**2)."M"; } else { $PACKIN = sprintf("%.02f", $PACKIN / 1024**3)."G"; }
    if ($DEV2) {
      $PACKIN2 = `netstat -i -n -b | grep $DEV2 | head -n1 | awk '{print \$7}'`; 
      if($PACKIN2 < 1024**3) { $PACKIN2 = sprintf("%.02f",$PACKIN / 1024**2)."M"; } else { $PACKIN2 = sprintf("%.02f", $PACKIN / 1024**3)."G"; }
    };

    #--PACKETS OUT--#
    $PACKOUT = `netstat -i -n -b | grep $DEV | head -n1 | awk '{print \$10}'`;
    if($PACKOUT < 1024**3) { $PACKOUT = sprintf("%.02f",$PACKOUT / 1024**2)."M"; } else { $PACKOUT = sprintf("%.02f", $PACKOUT / 1024**3)."G"; }
    if ($DEV2) {
      $PACKOUT2 = `netstat -i -n -b | grep $DEV2 | head -n1 | awk '{print \$10}'`;
      if($PACKOUT2 < 1024**3) { $PACKOUT2 = sprintf("%.02f",$PACKOUT / 1024**2)."M"; } else { $PACKOUT2 = sprintf("%.02f", $PACKOUT / 1024**3)."G"; }
    };

  } else {
  #--GET INFO ON LINUX--#

    #--MODEL--#
    $MODEL = `cat /proc/cpuinfo | grep '^model name' | head -1 | cut -d":" -f2`;
    $MODEL =~ s/^ +//;
    
    #--HOW MANY CPUS--#
    $NUM=`cat /proc/cpuinfo | grep 'model name' | wc -l | cut -d" " -f7`;
    chop ($NUM);
    
    #--PROCESSOR SPEED--#
    $CPU = `cat /proc/cpuinfo | grep 'cpu MHz' | cut -d":" -f2`;
    chop ($CPU);
    $CPU =~ s/^ +//;

    #--TOTAL MEMORY--#
    $MEMTOTAL = `free | grep Mem | awk '{printf (\"%d\", \$2/1000 )}'`;
    
    #--MEMORY USED--#
    $MEMUSED = `free | grep Mem | awk '{printf (\"%.0fg\", ( \$3 -(\$6 + \$7) )/1000)}'`;
    chop ($MEMUSED);

    #--BOGOMIPS--#
    $MIPS = `cat /proc/cpuinfo | grep '^bogomips' | cut -d":" -f2`;
    chop ($MIPS);
    $MIPS =~ s/ +//;
    
    #--LM_SENSORS #1--#
    $SENSOR1 = `sensors -f | grep 'temp:'`;
    chop ($SENSOR1);
    $SENSOR1 =~ /[\w\:]+[\s]+([^\s]+)/;
    $SENSOR1 = $1;
    
    #--LM_SENSORS #2--#
    $SENSOR2 = `sensors -f | grep 'fan1:'`;
    chop ($SENSOR2);
    $SENSOR2 =~ /[\w\:]+[\s]+([^\s]+)/;
    $SENSOR2 = $1;

    #--CONNECTION DEVICE--#
    if($DEV =~ /^ppp/i) {
       $DEVTYPE=`cat /proc/pci | grep 'Communication controller:' | cut -d" " -f7-`;
    } else {	    
       $DEVTYPE=`cat /proc/pci | grep "IRQ \`/sbin/ifconfig $DEV | grep Interrupt | cut -d":" -f2 | cut -d" " -f1\`" -B1 | grep Ethernet | cut -d":" -f2- | cut -d" " -f2-`;
    };
    chop($DEVTYPE);
    if ($DEVTYPE =~ /^$/) {
        $DEVTYPE="Unknown";
    };

    #--PACKETS IN--# 
    $PACKIN = `cat /proc/net/dev | grep $DEV | awk -F: '/:/ {print \$2}' | awk '{printf \$1}'`;
    if($PACKIN < 1024**3) { $PACKIN = sprintf("%.02f",$PACKIN / 1024**2)."M"; } else { $PACKIN = sprintf("%.02f", $PACKIN / 1024**3)."G"; }
 
   #--PACKETS OUT--# 
    $PACKOUT = `cat /proc/net/dev | grep $DEV | awk -F: '/:/ {print \$2}' | awk '{print \$9}'`; 
    if($PACKOUT < 1024**3) { $PACKOUT = sprintf("%.02f",$PACKOUT / 1024**2)."M"; } else { $PACKOUT = sprintf("%.02f", $PACKOUT / 1024**3)."G"; }

  };

  #--GET COMMON INFO--#

    #--PROCS RUNNING--#
    $PROCS = `ps ax | wc -l`;
    $PROCS =~ s/^\s+//;
    chop ($PROCS);

    #--PERCENTAGE OF MEMORY USED--#
    $MEMPERCENT = $MEMUSED/$MEMTOTAL*100;
    if (int($MEMPERCENT) == int($MEMPERCENT + .5)) {
	    $MEMPERCENT = int($MEMPERCENT);
    } else {
	    $MEMPERCENT = int($MEMPERCENT + .5);
    };
    
    #--SCREEN RESOLUTION--#
    if ($UNAME =~ /^darwin/i) {
      #$RES = `dmesg | grep video | cut -d"(" -f2 | cut -d")" -f1`;
      $RES = `xdpyinfo | grep dimensions | cut -d" " -f7`;
      chop ($RES);
    } else {
      $RES = `xdpyinfo | grep dimensions | cut -d" " -f7`;
      chop ($RES);
    };

    #--DISKSPACE--#
    $HDD = `df -l -x tmpfs -x shm | awk '{ sum+=\$2/1024^2 }; END { printf (\"%dGb\", sum )}'`;
    chop ($HDD);
    
    #--DISKSPACE FREE--#
    if ($UNAME =~ /^darwin/i) {
      $HDDFREE = `df -l -x tmpfs -x shm | awk '{ sum+=\$4/1024^2 }; END { printf (\"%dGb\", sum )}'`;
      chop ($HDDFREE);
    } else {
      $HDDFREE = `df -l -x tmpfs -x shm | awk '{ sum+=\$3/1024^2 }; END { printf (\"%dGb\", sum )}'`;
      chop ($HDDFREE);
    }
    
    #--SUPPORT FOR DUAL PROCS--#
    unless($NUM eq 1 ) { $MODEL="Dual $MODEL"; }
    chop ($MODEL);

    #--UPTIME--#
    $UPTIME = `uptime`;
    chop ($UPTIME);
    $UPTIME =~ /.+ up (.+),.+[0-9]+ user/;
    $UPTIME = $1;

    #--BUILD OUTPUT--#
    $out = "%BSysInfo%O";
    if ($UNAME !~ /^$/) {
	$out = $out . " | System: $UNAME";
    };
    if ($MODEL !~ /^$/) {
        $out = $out . " | CPU: $MODEL $CPU" . "MHz";
    };
    if ($MEMUSED !~ /^$/ && $MEMTOTAL !~ /^$/) {
        $out = $out . " | Mem: $MEMUSED/" . $MEMTOTAL . "Mb ($MEMPERCENT%)";
    };
    if ($HDD !~ /^$/ && $HDDFREE !~ /^$/) {
        $out = $out . " | Diskspace: " . $HDD . "b Free: " . $HDDFREE . "b";
    };
    if ($MIPS !~ /^$/) {
        $out = $out . " | Bogomips: $MIPS";
    };
    if ($RES !~ /^$/) {
        $out = $out . " | Screen Res: $RES";
    };
    if ($PROCS !~ /^$/) {
        $out = $out . " | Procs: $PROCS";
    };
    if ($SENSOR1 !~ /^$/ && $SENSOR2 !~ /^$/) {
	$out = $out . " | CPU: $SENSOR1 Fan 1: $SENSOR2";
    }
    if ($UPTIME !~ /^$/) {
	$out = $out . " | Uptime: $UPTIME";
    };
    if ($DEVTYPE !~ /^$/ && $PACKIN !~ /^$/ && $PACKOUT !~ /^$/) {
      if ($PACKIN >  0 || $PACKOUT > 0) {
        $out = $out . " | Connection Device: $DEVTYPE In: " . $PACKIN . "b Out: " . $PACKOUT . "b";
      };
    };
    if ($DEVTYPE2 !~ /^$/ && $PACKIN2 !~ /^$/ && $PACKOUT2 !~ /^$/) {
      if ($PACKIN2 > 0 || $PACKOUT2 > 0) {
        $out = $out . " | Connection Device: $DEVTYPE2 In: " . $PACKIN2 . "b Out: " . $PACKOUT2 . "b";
      };
    };

    #--SPEW IT INTO THE CHANNEL SHALL WE--#
    IRC::command($out);
    return 1;
}
