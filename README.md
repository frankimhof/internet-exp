# internet-exp
This repo contains code used to run an experiment similar to the one described in chapter 4.3 of [Benchmarking Post-Quantum Cryptography in TLS](https://s3.amazonaws.com/files.douglas.stebila.ca/files/research/papers/PQCrypto-PaqSteTam20.pdf). The experiment consists of a nginx server (compiled against OQS-OpenSSL 1.1.1) which is configured to listen on multiple ports (each one offering a certificate with one of the signature algorithms under test) and to serve HTML pages of various sizes (1 kB, 10 kB, 100 kB, 1000 kB). For every SIG, KEM and HTML page, the total time to retrieve the complete file is measured. In this experiment, curl is used for measurment instead of apache-benchmark tool.  
Most of the code is taken from [open-quantum-safe/oqs-demos](https://github.com/open-quantum-safe/oqs-demos).
## Perequisites
Be sure to have [docker](https://docs.docker.com/install) installed.  
Be sure to have python3 installed.

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
This will expose all ports 4433-4442. See [here](https://github.com/frankimhof/internet-exp/blob/main/nginx/certs/README.md) for information about which port offers which SIG.  
<br>
<br>
## curl (client, running on a different computer)
### build curl docker image
```
cd ../curl
docker build -t oqs-curl .
```
### run docker container
```
docker run -it --add-host="<SERVER_COMMON_NAME>:<SERVER_IP>" oqs-curl
```
Replace **\<SERVER_COMMON_NAME\>** with the server name that has been choosen earlier and replace **\<SERVER_IP\>** with the ip address of the nginx server.  
This will add the nginx server to /etc/hosts and help resolve host verification later on when using curl.
### run curl command
```
curl "https://<SERVER_COMMON_NAME>:<PORT>/<FILE>" --curves <KEM> --cacert certs/<SIG>_CA.crt --verbose --output - -H "Connection: close"
```
This runs a simple curl command to test whether the connection works.  
Replace **\<PORT\>** and **\<SIG\>** with the desired SIG and the corresponding port.(4433 ecdsap256 for example)  
Replace **\<FILE\>** with one of the following **index1kb.html, index10kb.html, index100kb.html, index1000kb.html**  
Replace **\<KEM\>** with one of the available KEMS. (kyber512, kyber1024, saber, firesaber etc.)
