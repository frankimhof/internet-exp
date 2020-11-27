#!/usr/bin/perl

use strict;
use warnings;
use Time::HiRes;

if ($#ARGV + 1 != 2) {
    print "\nUsage: curl_perf_sig.pl <SERVER_COMMON_NAME> <TIME_LIMIT_IN_SECONDS>\n";
    exit;
}

my $server = $ARGV[0];
my $timelimit = $ARGV[1];
my $testresult_path = '/opt/test/testresults/';

# Get RTT and Packet-Loss information via Ping and store it for naming files later
system("echo Testing connection for RTT and Packet Loss...");
system("printf RTT_ > out.txt");
system("ping google.com -c 10 | tail -1 | awk '{print \$4}' | cut -d '/' -f 2 >> out.txt");
system("printf PKTLOSS_ >> out.txt");
system("ping google.com -c 10 | tail -2 | head -n1 | awk '{print \$7}' >> out.txt");

my $rtt=`cat out.txt | head -n1 | tr -d '\n'`;
system("echo '$rtt (average)'");
my $packet_loss=`cat out.txt | tail -1 | tr -d '\n'`;
system("echo $packet_loss");

my @sig_algs= ('ecdsap256', 'dilithium2', 'dilithium3', 'dilithium4', 'p256_dilithium2', 'p256_dilithium3', 'falcon512', 'falcon1024', 'rainbowIaclassic', 'rainbowVcclassic');
my @ports =(4433, 4434, 4435, 4436, 4437, 4438, 4439, 4440, 4441, 4442);
my @files = ('index1kb.html', 'index10kb.html', 'index100kb.html', 'index1000kb.html');
my $counter = 0;

my $kex_alg = 'prime256v1'; #in this experiment, always use same KEM: prime256v1
my $appendix= '_CA.crt';

foreach my $sig_alg (@sig_algs) {
    # Name the files starting with RTT and Packet Loss info
    my $output = $testresult_path . $rtt . 'ms__' . $packet_loss . '__KEX_' . $kex_alg . '__SIG_' . $sig_alg;
    my $port = $ports[$counter];

    foreach my $file (@files) {
        system("printf '$file' >> $output.csv");
        my $check_curl_command = "curl -s 'https://$server:$port/$file' --curves $kex_alg --cacert /certs/$sig_alg$appendix -H 'Connection: close'";
        system($check_curl_command . "2> /dev/null");
        if($? != 0){
                printf("Curl exited with code: %d", $?>>8);
                last;
        }
        my $cmd = "curl -s 'https://$server:$port/$file' --curves $kex_alg --cacert /certs/$sig_alg$appendix -H 'Connection: close' -w '\,%{time_total}' 2> /dev/null | tail -n1";
        system("echo 'running curl for $timelimit second(s) on $server:$port/$file using sig $sig_alg'");
        my $endtime = Time::HiRes::time()+$timelimit;
        while(Time::HiRes::time()<$endtime){
            system($cmd . ">> $output.csv");
        }
        system("printf '\n' >> $output.csv");                                                                                                                                                                                             
    }
    $counter++;
} 
