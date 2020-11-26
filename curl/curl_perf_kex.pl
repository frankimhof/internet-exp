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

my @kex_algs = ('prime256v1', 'kyber512', 'kyber1024', 'p256_kyber512', 'saber', 'lightsaber', 'firesaber', 'ntru_hps2048509', 'ntru_hps2048677', 'ntru_hps4096821');
#my @kex_algs = ('prime256v1', 'p256_kyber90s512', 'p256_sikep434', 'p256_frodo640aes');
my @files = ('index1kb.html', 'index10kb.html', 'index100kb.html', 'index1000kb.html');

foreach my $kex_alg (@kex_algs) {
    my $sig_alg = 'ecdsap256';
    my $output = $testresult_path . 'curl-kex-' . $kex_alg . '-' . $sig_alg;
    foreach my $file (@files) {
        my $port = '4433';
        system("printf '$file' >> $output.csv");
        my $check_curl_command = "curl -s 'https://$server:4433/$file' --curves $kex_alg --cacert /certs/ecdsap256_CA.crt -H 'Connection: close'";
        system($check_curl_command . "2> /dev/null");
        if($? != 0){
                printf("Curl exited with code: %d", $?>>8);
                last;
        }
        my $cmd = "curl -s 'https://$server:4433/$file' --curves $kex_alg --cacert /certs/ecdsap256_CA.crt -H 'Connection: close' -w '\,%{time_total}' 2> /dev/null | tail -n1";
        system("echo $cmd");
        my $endtime = Time::HiRes::time()+$timelimit;
        while(Time::HiRes::time()<$endtime){
            system($cmd . ">> $output.csv");
        }
        system("printf '\n' >> $output.csv");
    }
}

