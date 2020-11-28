#!/usr/bin/perl

use strict;
use warnings;
use Time::HiRes;

if ($#ARGV + 1 != 2) {
    print "\nUsage: curl_perf_kex.pl <SERVER_COMMON_NAME> <TIME_LIMIT_IN_SECONDS>\n";
    exit;
}

my $server = $ARGV[0];
my $timelimit = $ARGV[1];
my $testresult_path = '/opt/test/testresults/';

# Get RTT and Packet-Loss information via Ping and store it for naming files later
system("echo =================================================================");
system("echo Testing connection with server: $server");
system("echo -----------------------------------------------------------------");
system("printf RTT_ > out.txt");
system("ping '$server' -c 10 | tail -1 | awk '{print \$4}' | cut -d '/' -f 2 >> out.txt");
system("printf PKTLOSS_ >> out.txt");
system("ping '$server' -c 10 | tail -2 | head -n1 | awk '{print \$7}' >> out.txt");

my $rtt=`cat out.txt | head -n1 | tr -d '\n'`;
my $packet_loss=`cat out.txt | tail -1 | tr -d '\n'`;
system("echo RTT '\(average\)'     = $rtt ms");
system("echo Packet Loss           = '$packet_loss'");
system("echo ");
sleep 3;
system("echo =================================================================");
system("echo Running test curl_perf_kex");
system("echo -----------------------------------------------------------------");
sleep 2;
my @kex_algs = ('prime256v1', 'kyber512', 'kyber1024', 'p256_kyber512', 'saber', 'lightsaber', 'firesaber', 'ntru_hps2048509', 'ntru_hps2048677', 'ntru_hps4096821');
#my @kex_algs = ('prime256v1', 'p256_kyber90s512', 'p256_sikep434', 'p256_frodo640aes');
my @files = ('index1kb.html', 'index10kb.html', 'index100kb.html', 'index1000kb.html');

foreach my $kex_alg (@kex_algs) {
    my $sig_alg = 'ecdsap256';
    my $port = '4433';
    # Name the files starting with RTT and Packet Loss info
    my $output = $testresult_path . $rtt . 'ms__' . $packet_loss . '__KEX_' . $kex_alg . '__SIG_' . $sig_alg;
    foreach my $file (@files) {
        system("printf '$file' >> $output.csv");
        my $check_curl_command = "curl -s 'https://$server:4433/$file' --curves $kex_alg --cacert /certs/ecdsap256_CA.crt -H 'Connection: close'";
        system($check_curl_command . "2> /dev/null");
        if($? != 0){
                system("echo =================================================================");
                system("echo =================================================================");
                printf("ERROR: Curl exited with code: %d", $?>>8);
                last;
        }
        my $cmd = "curl -s 'https://$server:4433/$file' --curves $kex_alg --cacert /certs/ecdsap256_CA.crt -H 'Connection: close' -w '\,%{time_total}' 2> /dev/null | tail -n1";
        system("echo 'running curl for $timelimit second(s) on $server:$port/$file using kex $kex_alg'");
        my $endtime = Time::HiRes::time()+$timelimit;
        while(Time::HiRes::time()<$endtime){
            system($cmd . ">> $output.csv");
        }
        system("printf '\n' >> $output.csv");
    }
    system("echo -----------------------------------------------------------------");
}

system("echo ");
system("echo =================================================================");
system("echo =================================================================");
system("echo DONE. Testresults have been written to /opt/test/testresults");
