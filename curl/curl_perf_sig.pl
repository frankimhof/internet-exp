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
system("echo =================================================================");
system("echo Testing connection with server: $server");
system("echo -----------------------------------------------------------------");
system("printf RTT_ > out.txt");
system("ping '$server' -c 1 | tail -1 | awk '{print \$4}' | cut -d '/' -f 2 >> out.txt");
system("printf PKTLOSS_ >> out.txt");
system("ping '$server' -c 1 | tail -2 | head -n1 | awk '{print \$7}' >> out.txt");

my $rtt=`cat out.txt | head -n1 | tr -d '\n'`;
my $packet_loss=`cat out.txt | tail -1 | tr -d '\n'`;
system("echo RTT '\(average\)'     = $rtt ms");
system("echo Packet Loss           = '$packet_loss'");
system("echo ");
sleep 3;
system("echo =================================================================");
system("echo Running test curl_perf_sig");
system("echo -----------------------------------------------------------------");
sleep 2;

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
        #Checking HTTP Status code for connection under test. If not 200, throw error
        my $http_status_code=`curl -s -o /dev/null -w "%{http_code}" 'https://$server:$port/$file' --curves $kex_alg --cacert /certs/$sig_alg$appendix -H 'Connection: close'`;
        if($http_status_code!=200){
            system("echo =================================================================");
            system("echo =================================================================");
            printf("ERROR: curl returned HTTP Status Code: %d \n", $http_status_code);
            last;
        }
        #Passed test, now executing test
        system("echo 'running curl for $timelimit second(s) on $server:$port/$file using sig $sig_alg'");
        my $endtime = Time::HiRes::time()+$timelimit;
        while(Time::HiRes::time()<$endtime){
            #Write curl results to .csv file
            system("curl -s -o /dev/null 'https://$server:$port/$file' --curves $kex_alg --cacert /certs/$sig_alg$appendix -H 'Connection: close' -w '\,%{time_total}' >> $output.csv");
        }
        system("printf '\n' >> $output.csv");                                                                                                                                                                                          
    }
    $counter++;
    system("echo -----------------------------------------------------------------");
}
system("echo ");
system("echo =================================================================");
system("echo =================================================================");
system("echo DONE. Testresults have been written to /opt/test/testresults");
