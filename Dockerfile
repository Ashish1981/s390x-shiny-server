FROM ashish1981/s390x-rbase-rjava-rplumber
#
ENV DEBIAN_FRONTEND noninteractive
# Install build prerequisites

RUN apt-get install -y make gcc g++ git python libssl-dev 

# Install R repo

RUN echo 'deb http://cran.rstudio.com/bin/linux/ubuntu trusty/' >> /etc/apt/sources.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0x51716619e084dab9

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

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - \
    && apt-get install -y nodejs \
    && apt-get install -y npm \
    && npm config set python /usr/bin/python2.7 \
    && apt-get install -y node-gyp \
    && curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.30.1/install.sh | bash 

RUN mkdir ~/.npm-global \
    && npm config set prefix '~/.npm-global' \
    && echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.profile \
    && . ~/.profile \
    && npm completion >> ~/.bashrc \
    && npm install -g npm 

RUN cd ~/ \
    && wget https://github.com/rstudio/shiny-server/archive/v1.5.12.933.tar.gz \
    && tar xzf v1.5.12.933.tar.gz \
    && mv shiny-server-1.5.12.933 shiny-server \
    && cd shiny-server \
    && mkdir -p tmp 

COPY install-node.sh /home/root/shiny-server/external/node/

RUN cd ~/shiny-server/tmp   \
    && ../external/node/install-node.sh \
    && export DIR=`pwd` && export PATH=$DIR/../bin:$PATH \
    && cmake -DCMAKE_INSTALL_PREFIX=/usr/local ../ \
    && make \
    && mkdir ../build 

RUN cd ~/shiny-server/tmp \    
    && (cd .. && npm install) 

RUN cd ~/shiny-server/tmp   \    
    && (cd .. && node ./ext/node/lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js rebuild) \
    && make install  \
    && ln -s /usr/local/shiny-server/bin/shiny-server /usr/bin/shiny-server \
    && useradd -r -m shiny \
    && mkdir -p /var/log/shiny-server \
    && mkdir -p /srv/shiny-server \
    && mkdir -p /var/lib/shiny-server \
    && chown shiny /var/log/shiny-server \
    && mkdir -p /etc/shiny-server \
    && cp ../config/default.config /etc/shiny-server/shiny-server.conf \
    && rm -rf /tmp/*