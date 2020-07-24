FROM ashish1981/s390x-rbase-rjava-rplumber
#
# Install build prerequisites
RUN apt-get install -y make gcc g++ git python libssl-dev

RUN apt-get update && apt-get install -y \
    python-software-properties \
    software-properties-common

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

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get install -y nodejs

RUN cd /tmp \
    && wget https://github.com/rstudio/shiny-server/archive/v1.5.14.948.tar.gz \
    && tar xzf v1.5.14.948.tar.gz \
    && cd v1.5.14.948 \
    && cd shiny-server \
    && mkdir -p tmp \
    && cd tmp \
    && export DIR=`pwd` && export PATH=$DIR/../bin:$PATH \
    && cmake -DCMAKE_INSTALL_PREFIX=/usr/local ../ \
    && make \
    && mkdir ../build \
    && npm install \
    && make install  \
    && ln -s /usr/local/shiny-server/bin/shiny-server /usr/bin/shiny-server \
    && useradd -r -m shiny \
    && mkdir -p /var/log/shiny-server \
    && mkdir -p /srv/shiny-server \
    && mkdir -p /var/lib/shiny-server \
    && chown shiny /var/log/shiny-server \
    && mkdir -p /etc/shiny-server \
    && cp ../config/default.config /etc/shiny-server/shiny-server.conf 