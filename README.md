# internet-exp
This repo contains code used to run an experiment similar to the one described in chapter 4.3 of [Benchmarking Post-Quantum Cryptography in TLS](https://s3.amazonaws.com/files.douglas.stebila.ca/files/research/papers/PQCrypto-PaqSteTam20.pdf). The experiment consists of a nginx server (compiled against OQS-OpenSSL 1.1.1) which is configured to listen on multiple ports (each one offering a certificate with one of the signature algorithms under test) and to serve HTML pages of various sizes (1 kB, 10 kB, 100 kB, 1000 kB). For every SIG, KEM and HTML page, the total time to retrieve the complete file is measured. In this experiment, curl is used for measurment instead of apache-benchmark tool.  
Most of the code is taken from [open-quantum-safe/oqs-demos](https://github.com/open-quantum-safe/oqs-demos).
## Perequisites
Be sure to have [docker](https://docs.docker.com/install) installed.  

## nginx (server)
### build nginx docker image
```
cd ..
docker build -t oqs-nginx-img .
```

### run docker container
```
docker run --detach --rm --name oqs-nginx -p 4433-4442:4433-4442 oqs-nginx-img
```
This will expose all ports 4433-4442. See [here](https://github.com/frankimhof/internet-exp/tree/master/nginx) for information about which port offers which SIG.  
<br>
<br>
## curl (client, running on a different computer)
### build curl docker image
```
cd ../curl
docker build -t oqs-curl .
```
### create a local directory for the testresults
```
mkdir <LOCAL_DIRECTORY>/testresults
```
Replace **\<LOCAL_DIRECTORY\>** with a local directory of your choosing. The testresults will be written to the **testresults** folder inside this directory.
### run docker container
The following command will start the container interactively.
```
docker run -u root -it --add-host="<SERVER_COMMON_NAME>:<SERVER_IP>" -v <LOCAL_DIRECTORY>/testresults:/opt/test/testresults oqs-curl
```
Replace **\<SERVER_COMMON_NAME\>** with the server name that has been choosen earlier and replace **\<SERVER_IP\>** with the ip address of the nginx server.  
Replace **\<LOCAL_DIRECTORY\>** with the local directory that has been chosen earlier.

### test connection with server before running experiment
(Inside the container's shell)
```
ping <SERVER_COMMON_NAME>
```

### run experiment
(Inside the container's shell)
```
perl /opt/test/curl_perf_kex.pl <SERVER_COMMON_NAME> <DURATION_IN_SECONDS>
OR
perl /opt/test/curl_perf_sig.pl <SERVER_COMMON_NAME> <DURATION_IN_SECONDS>
```
Replace **\<DURATION_IN_SECONDS\>** with an integer. If set to 180, the experiment will collect data for 3 minutes (180s) **for every KEM|SIG and every HTML file**.

### (alternatively) run specific curl command
Test curl with specific \<KEM\> and \<SIG\>. See [here](https://github.com/frankimhof/internet-exp/tree/master/nginx) for mapping between \<SIG\> and \<PORT\>.
```
curl "https://<SERVER_COMMON_NAME>:<PORT>/<FILE>" --curves <KEM> --cacert certs/<SIG>_CA.crt --verbose --output - -H "Connection: close"
```
Replace **\<PORT\>** and **\<SIG\>** with the desired SIG and the corresponding port.(4433 ecdsap256 for example)  
Replace **\<FILE\>** with one of the following **index1kb.html, index10kb.html, index100kb.html, index1000kb.html**  
Replace **\<KEM\>** with one of the available KEMS. (kyber512, kyber1024, saber, firesaber etc.)
