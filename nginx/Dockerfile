# Multi-stage build: First the full builder image:

# First: global build arguments:

# set the name of the server which will be tested by the curl container.
ARG SERVER_COMMON_NAME=testserver
# liboqs build type variant; build non-optimized by default (maximum portability of image):
ARG LIBOQS_BUILD_DEFINES="-DOQS_USE_CPU_EXTENSIONS=OFF"

# installation paths
ARG OPENSSL_PATH=/opt/openssl
ARG NGINX_PATH=/opt/nginx
ARG CA_PATH=/opt/internet-exp-ca

# defines the QSC signature algorithm used for the certificates:
#ARG SIG_ALG="dilithium2"

# define the nginx version to include
ARG NGINX_VERSION=1.16.1

# Define the degree of parallelism when building the image; leave the number away only if you know what you are doing
ARG MAKE_DEFINES="-j 2"


FROM alpine as intermediate
# Take in global args
ARG LIBOQS_BUILD_DEFINES
ARG OPENSSL_PATH
ARG NGINX_PATH
#ARG SIG_ALG
ARG NGINX_VERSION
ARG MAKE_DEFINES
ARG SERVER_COMMON_NAME


# Get all software packages required for builing all components:
RUN apk add build-base linux-headers \
            libtool automake autoconf cmake ninja \
            make \
            openssl openssl-dev \
            git wget pcre-dev

# get OQS sources
WORKDIR /opt
RUN git clone --depth 1 --branch main https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch OQS-OpenSSL_1_1_1-stable https://github.com/open-quantum-safe/openssl && \
    git clone --depth 1 https://github.com/frankimhof/internet-exp-ca.git && \
    wget nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && tar -zxvf nginx-${NGINX_VERSION}.tar.gz;

# build liboqs (static only)
WORKDIR /opt/liboqs
RUN mkdir build-static && cd build-static && cmake -G"Ninja" ${LIBOQS_BUILD_DEFINES} -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=${OPENSSL_PATH}/oqs .. && ninja && ninja install

# build nginx (which builds OQS-OpenSSL)
WORKDIR /opt/nginx-${NGINX_VERSION}
RUN ./configure --prefix=${NGINX_PATH} \
                --with-debug \
                --with-http_ssl_module --with-openssl=${OPENSSL_PATH} \
                --without-http_gzip_module \
                --with-cc-opt=-I${OPENSSL_PATH}/oqs/include \
                --with-ld-opt="-L${OPENSSL_PATH}/oqs/lib" && \
    sed -i 's/libcrypto.a/libcrypto.a -loqs/g' objs/Makefile && \
    make ${MAKE_DEFINES} && make install;
#maybe add --with-http_v2_module later

FROM alpine 
# Take in global args
ARG LIBOQS_BUILD_DEFINES
ARG OPENSSL_PATH
ARG NGINX_PATH
ARG CA_PATH
ARG SERVER_COMMON_NAME

## second stage: Only create minimal image without build tooling and intermediate build results generated above:

RUN apk add pcre-dev python3 bash

# Only retain the ${*_PATH} contents in the final image
COPY --from=intermediate ${NGINX_PATH} ${NGINX_PATH}
COPY --from=intermediate ${OPENSSL_PATH}/apps/openssl ${OPENSSL_PATH}/apps/openssl
COPY --from=intermediate ${OPENSSL_PATH}/apps/openssl.cnf ${OPENSSL_PATH}/apps/openssl.cnf
COPY --from=intermediate ${CA_PATH} ${CA_PATH}
COPY nginx-conf/ ${NGINX_PATH}/nginx-conf
COPY html/ ${NGINX_PATH}/html

# create Server Certificates and Keys
WORKDIR ${CA_PATH}
RUN /bin/bash ./createAllServerCerts.sh ${OPENSSL_PATH} ${SERVER_COMMON_NAME}
# move server crt and key files into pki folder
WORKDIR ${NGINX_PATH}
RUN mkdir pki && \
    mv ${CA_PATH}/*srv.* ${NGINX_PATH}/pki
# create HTML Files
WORKDIR ${NGINX_PATH}/html
RUN python3 createHTMLFiles.py

WORKDIR ${NGINX_PATH}

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout ${NGINX_PATH}/logs/access.log && \
    ln -sf /dev/stderr ${NGINX_PATH}/logs/error.log;

# This expose command needs to be in line with what's spec'd in nginx.conf:
EXPOSE 4433-4442

# Ensure nginx just runs
ENV PATH ${NGINX_PATH}/sbin:$PATH

STOPSIGNAL SIGTERM

# Enable a normal user to create new server keys off set CA
RUN addgroup -g 1000 -S oqs && adduser --uid 1000 -S oqs -G oqs && chown -R oqs.oqs ${NGINX_PATH}
USER oqs

CMD ["nginx", "-c", "nginx-conf/nginx.conf", "-g", "daemon off;"]

