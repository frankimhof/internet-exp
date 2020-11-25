## Purpose 
This directory contains a Dockerfile that builds nginx with the [OQS OpenSSL 1.1.1 fork](https://github.com/open-quantum-safe/openssl), which allows nginx to negotiate quantum-safe keys and use quantum-safe authentication in TLS 1.3.

### SIG to PORT Mapping
The server listen on multiple ports (each one offering a certificate with one of the signature algorithms under test).  


| Port          | SIG           |
| ------------- | ------------- |
| 4433          | ecdsap256     |
| 4434          | dilithium2 |
| 4435          | dilithium3 |
| 4436          | dilithium4 |
| 4437          | p256_dilithium2 |
| 4438          | p256_dilithium3 |
| 4439          | falcon512 |
| 4440          | falcon1024 |
| 4441          | rainbowIaclassic|
| 4442          | rainbowVcclassic |