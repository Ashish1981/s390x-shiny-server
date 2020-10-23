FROM ashish1981/s390x-shiny-server:master-20201023-171826-46
#
ENV DEBIAN_FRONTEND noninteractive

################################################
#################  Shiny Server   ##############
################################################

RUN cd /home/shiny \
    # && git clone https://github.com/rstudio/shiny-server.git 
    && git clone https://github.com/Ashish1981/shiny-server.git 

COPY install-node.sh /home/shiny/shiny-server/external/node/

RUN cd /home/shiny/shiny-server && mkdir tmp && cd tmp \
    && chmod +x ../external/node/install-node.sh \
    && ../external/node/install-node.sh