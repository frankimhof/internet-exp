#!/usr/bin/perl

use strict;
use warnings;
use Time::HiRes;

if ($#ARGV + 1 != 2) {
    print "\nUsage: experiment.pl server_common_name time_limit_in_seconds\n";
    exit;
}

my $server = $ARGV[0];
my $timelimit = $ARGV[1];

#my @kex_algs = ('prime256v1', 'kyber512', 'kyber1024', 'p256_kyber512', 'p256_kyber1024', 'kyber512_90s', 'ntru_hps2048509', 'lightsaber', 'p256_kyber512_90s', 'p256_lightsaber');
my @kex_algs = ('prime256v1');

my @files = ('index1kb.html', 'index10kb.html', 'index100kb.html', 'index1000kb.html');

foreach my $kex_alg (@kex_algs) {
    my $sig_alg = 'ecdsap256';
    my $output = 'curl-kex-' . $kex_alg . '-' . $sig_alg;
    foreach my $file (@files) {
        my $port = '4433';
        system("printf '$file' >> $output.txt");
        my $check_curl_command = "curl -s 'https://$server:4433/$file' --curves $kex_alg --cacert certs/ecdsap256_CA.crt -H 'Connection: close'";
        system($check_curl_command . "2> /dev/null");
        if($? != 0){
                printf("Curl exited with code: %d", $?>>8);
                last;
        }
        my $cmd = "curl -s 'https://$server:4433/$file' --curves $kex_alg --cacert certs/ecdsap256_CA.crt -H 'Connection: close' -w '\,%{time_total}' 2> /dev/null | tail -n1";
        system("echo $cmd");
        my $endtime = Time::HiRes::time()+$timelimit;
        while(Time::HiRes::time()<$endtime){
            system($cmd . ">> $output.txt");
        }
        system("printf '\n' >> $output.txt");
    }
}

