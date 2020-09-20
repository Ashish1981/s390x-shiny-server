FROM ashish1981/s390x-rbase-rjava-rplumber
#
ENV DEBIAN_FRONTEND noninteractive
# Install build prerequisites

################################################################################################
# ensure local python is preferred over distribution python

ARG DISTRO=linux-s390x
ARG VERSION=v14.11.0
ARG HOME=/home/shiny

ENV DISTRO ${DISTRO}
ENV VERSION ${VERSION}
ENV HOME ${HOME}
ENV PATH /usr/local/bin:/opt/nodejs/node-$VERSION-$DISTRO/bin:/home/shiny/.npm-global:$PATH
ENV GPG_KEY E3FF2839C048B25C084DEBE9B26995E310250568
ENV PYTHON_VERSION 3.8.5

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

# extra dependencies (over what buildpack-deps already includes)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libbluetooth-dev \
    tk-dev \
    uuid-dev \
    && rm -rf /var/lib/apt/lists/*

RUN curl -OL https://nodejs.org/dist/latest-v14.x/node-$VERSION-$DISTRO.tar.xz \
    && mkdir -p /opt/nodejs \
    && tar -xJvf node-$VERSION-$DISTRO.tar.xz -C /opt/nodejs \
    # && export PATH=/opt/nodejs/node-$VERSION-$DISTRO/bin:$PATH \
    # && echo 'export DISTRO=linux-s390x' >> /home/shiny/.profile \
    # && echo 'export VERSION=v14.11.0' >> /home/shiny/.profile \
    # && echo 'export PATH=/opt/nodejs/node-$VERSION-$DISTRO/bin:$PATH'   >> /home/shiny/.profile \
    # && . /home/shiny/.profile \
    # && apt-get install -y npm \
    # && apt-get install -y node-gyp \
    && curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.30.1/install.sh | bash 
#### made changes as .~/ to /home/shiny/
RUN mkdir /home/shiny/.npm-global \
    && npm config set prefix '/home/shiny/.npm-global' \
    && echo 'export PATH=/home/shiny/.npm-global:$PATH' >> /home/shiny/.profile \
    # && . /home/shiny/.profile \
    && npm completion >> /home/shiny/.bashrc \
    && npm install -g npm     

################################################
#################### PYTHON ####################
################################################

RUN set -ex \
    \
    && wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" \
    && wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
    && gpg --batch --verify python.tar.xz.asc python.tar.xz \
    && { command -v gpgconf > /dev/null && gpgconf --kill all || :; } \
    && rm -rf "$GNUPGHOME" python.tar.xz.asc \
    && mkdir -p /usr/src/python \
    && tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
    && rm python.tar.xz \
    \
    && cd /usr/src/python \
    && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
    && ./configure \
    --build="$gnuArch" \
    --enable-loadable-sqlite-extensions \
    --enable-optimizations \
    --enable-option-checking=fatal \
    --enable-shared \
    --with-system-expat \
    --with-system-ffi \
    --without-ensurepip \
    && make -j "$(nproc)" \
    && make install \
    && rm -rf /usr/src/python \
    \
    && find /usr/local -depth \
    \( \
    \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
    -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name '*.a' \) \) \
    -o \( -type f -a -name 'wininst-*.exe' \) \
    \) -exec rm -rf '{}' + \
    \
    && ldconfig \
    \
    && python3 --version

# make some useful symlinks that are expected to exist
RUN cd /usr/local/bin \
    && ln -s idle3 idle \
    && ln -s pydoc3 pydoc \
    && ln -s python3 python \
    && ln -s python3-config python-config

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 20.2.3
# https://github.com/pypa/get-pip
ENV PYTHON_GET_PIP_URL https://github.com/pypa/get-pip/raw/fa7dc83944936bf09a0e4cb5d5ec852c0d256599/get-pip.py
ENV PYTHON_GET_PIP_SHA256 6e0bb0a2c2533361d7f297ed547237caf1b7507f197835974c0dd7eba998c53c

RUN set -ex; \
    \
    wget -O get-pip.py "$PYTHON_GET_PIP_URL"; \
    echo "$PYTHON_GET_PIP_SHA256 *get-pip.py" | sha256sum --check --strict -; \
    \
    python get-pip.py \
    --disable-pip-version-check \
    --no-cache-dir \
    "pip==$PYTHON_PIP_VERSION" \
    ; \
    pip --version; \
    \
    find /usr/local -depth \
    \( \
    \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
    -o \
    \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
    \) -exec rm -rf '{}' +; \
    rm -f get-pip.py

################################################
#################### PYTHON END ################
################################################


# RUN apt-get install -y make gcc g++ git python libssl-dev 

RUN apt-get install -y make gcc g++ git libssl-dev 

# # Install R repo

# RUN echo 'deb http://cran.rstudio.com/bin/linux/ubuntu trusty/' >> /etc/apt/sources.list \
#     && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0x51716619e084dab9

# Download, build, and install CMake (must be 2.8.10 or later).
RUN rm -rf /tmp/* \
    && cd /tmp    \
    && wget http://www.cmake.org/files/v2.8/cmake-2.8.11.2.tar.gz \
    && tar xzf cmake-2.8.11.2.tar.gz \
    && cd cmake-2.8.11.2 \
    && ./configure  \
    && make \
    && make install  \
    && rm -rf /tmp/*
###Nodejs
# RUN curl -OL https://nodejs.org/dist/latest-v14.x/node-v14.11.0-linux-s390x.tar.xz \
#     && export VERSION=v14.11.0 \
#     && export DISTRO=linux-s390x \
#     && export HOME=/home/shiny \
#     && mkdir -p /opt/nodejs \
#     && tar -xJvf node-$VERSION-$DISTRO.tar.xz -C /opt/nodejs \
#     && apt-get install -y npm \
#     && apt-get install -y node-gyp \
#     && curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.30.1/install.sh | bash \
#     && echo 'export DISTRO=linux-s390x' >> /home/shiny/.profile \
#     && echo 'export VERSION=v14.11.0' >> /home/shiny/.profile \
#     && echo 'export PATH=/opt/nodejs/node-$VERSION-$DISTRO/bin:$PATH'   >> /home/shiny/.profile \
#     && . /home/shiny/.profile
###Nodejs
# RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - \
#     && apt-get install -y nodejs \
#     && apt-get install -y npm \
#     && npm config set python /usr/bin/python2.7 \
#     && apt-get install -y node-gyp \
#     && curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.30.1/install.sh | bash 
####


# RUN cd ~/ \
#     && wget https://github.com/rstudio/shiny-server/archive/v1.5.12.933.tar.gz \
#     && tar xzf v1.5.12.933.tar.gz \
#     && mv shiny-server-1.5.12.933 shiny-server \
#     && cd shiny-server \
#     && mkdir -p tmp 
# RUN cd ~/ \
#     && wget https://github.com/rstudio/shiny-server/archive/v1.5.9.923.tar.gz \
#     && tar xzf v1.5.9.923.tar.gz \
#     && mv shiny-server-1.5.9.923 shiny-server \
#     && cd shiny-server \
#     && mkdir -p tmp 

# COPY install-node.sh /home/shiny/shiny-server/external/node/

RUN cd /home/shiny \
    && git clone https://github.com/rstudio/shiny-server.git 
    

# RUN cd ~/shiny-server/tmp   \
#     && ../external/node/install-node.sh \
#     && export DIR=`pwd` && export PATH=$DIR/../bin:$PATH \
#     && cmake -DCMAKE_INSTALL_PREFIX=/usr/local ../ \
#     && make \
#     && mkdir ../build 
COPY install-node.sh /home/shiny/shiny-server/external/node/

RUN cd /home/shiny/shiny-server && mkdir tmp && cd tmp \
    && ../external/node/install-node.sh \
    && export DIR=`pwd` && export PATH=$DIR/../bin:$PATH \
    && cmake -DCMAKE_INSTALL_PREFIX=/usr/local ../ \
    && make \
    && mkdir ../build \
    && cd /home/shiny/shiny-server/tmp \
    && (cd .. && npm install)

RUN cd /home/shiny/shiny-server/tmp   \
    && (cd .. && node ./ext/node/lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js rebuild) \
    && make install  \
    && ln -s /usr/local/shiny-server/bin/shiny-server /usr/bin/shiny-server \
    # && useradd -r -m shiny \
    && mkdir -p /var/log/shiny-server \
    && mkdir -p /var/log/supervisord \
    && mkdir -p /srv/shiny-server \
    && mkdir -p /var/lib/shiny-server \
    # && chown shiny /var/log/shiny-server \
    && mkdir -p /etc/shiny-server \
    && cp ../config/default.config /etc/shiny-server/shiny-server.conf \
    && rm -rf /tmp/*