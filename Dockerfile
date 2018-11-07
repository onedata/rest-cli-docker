FROM gliderlabs/alpine:3.4
MAINTAINER Bartek Kryza <bkryza@gmail.com>

RUN sed -i -e 's/v3\.4/edge/g' /etc/apk/repositories && \
    apk add --update \
    git \
    curl \
    libxml2-utils \
    bash \
    figlet \
    wget \
    zsh \
    perl \
    ncurses \
    coreutils \
    util-linux \
    jq \
    vim \
    openssh \
  && rm -rf /var/cache/apk/*

#
# Install oh-my-zsh
#
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" || true

#
# Install cowsay
#
RUN cd /tmp && \
    git clone https://github.com/schacon/cowsay.git && \
    cd cowsay && \
    sh install.sh && \
    cd .. && \
    rm -rf cowsay

ADD onedata-select-version.sh /usr/local/bin/onedata-select-version
RUN chmod a+x /usr/local/bin/onedata-select-version

#
# Enable cowsay
#
RUN ln -s /usr/games/cowsay /usr/bin/cowsay

#
# Add Onedata REST clients
#
ADD _onedata-select-version /usr/local/share/zsh/site-functions/_onedata-select-version
COPY onepanel-rest-clients.tar.gz /tmp/onepanel-rest-clients.tar.gz
COPY oneprovider-rest-clients.tar.gz /tmp/oneprovider-rest-clients.tar.gz
COPY onezone-rest-clients.tar.gz /tmp/onezone-rest-clients.tar.gz
COPY luma-rest-clients.tar.gz /tmp/luma-rest-clients.tar.gz
COPY cdmi-rest-client.tar.gz /tmp/cdmi-rest-client.tar.gz
RUN    mkdir -p /var/opt/onedata/onepanel \
    && mkdir -p /var/opt/onedata/oneprovider \
    && mkdir -p /var/opt/onedata/onezone \
    && mkdir -p /var/opt/onedata/luma \
    && mkdir -p /var/opt/onedata/cdmi \
    && tar -zxf /tmp/onepanel-rest-clients.tar.gz -C /var/opt/onedata/onepanel/ \
    && tar -zxf /tmp/oneprovider-rest-clients.tar.gz -C /var/opt/onedata/oneprovider/ \
    && tar -zxf /tmp/onezone-rest-clients.tar.gz -C /var/opt/onedata/onezone/ \
    && tar -zxf /tmp/luma-rest-clients.tar.gz -C /var/opt/onedata/luma/ \
    && tar -zxf /tmp/cdmi-rest-client.tar.gz -C /var/opt/onedata/cdmi/ \
    && chmod 755 -R /var/opt/onedata \
    && chmod 755 /usr/local/share/zsh/site-functions/_onedata-select-version \
    && cp /var/opt/onedata/cdmi/bash/1.1.1/cdmi-cli /usr/local/bin/cdmi-cli \
    && chmod a+x /usr/local/bin/cdmi-cli \
    && cp /var/opt/onedata/cdmi/bash/1.1.1/_cdmi-cli /usr/local/share/zsh/site-functions/_cdmi-cli \
    && chmod 755 /usr/local/share/zsh/site-functions/_cdmi-cli \
    && rm -f /tmp/*.tar.gz

#
# Fake zsh history
#
RUN echo '\n\
: 1486495368:0;onepanel-rest-cli\n\
: 1486495397:0;oneprovider-rest-cli\n\
: 1486495418:0;onezone-rest-cli\n\
: 1486495743:0;onedata-select-version\n\
' | tee -a ~/.zsh_history

#
# Setup default Onedata version and prompt
#
ADD zshrc /root/.zshrc
ADD onedata.zsh-theme /root/.oh-my-zsh/themes/onedata.zsh-theme
ADD onedata.plugin.zsh /root/.oh-my-zsh/plugins/onedata/onedata.plugin.zsh
RUN    echo -n 18.02.0-rc13 > /etc/onedata.release \
    && echo 'export ZSH_THEME="onedata"' >> ~/.zshrc \
    && echo 'export ZSH_PLUGINS=(onedata)' >> ~/.zshrc \
    && echo 'export PS1="[Onedata REST CLI] \$ "' >> ~/.bashrc \
    && echo "compdef _onedata-select-version onedata-select-version" | tee -a ~/.zshrc \
    && /usr/local/bin/onedata-select-version 18.02.0-rc13 \
    && echo "figlet \"O n e d a t a\"" | tee -a ~/.bashrc ~/.zshrc

#
# Setup welcome message
#
RUN printf 'cat << EOF\n\
This Docker provides preconfigured environment for accessing $(tput setaf 6)Onedata$(tput sgr0) REST services\n\
using command line interface. For convenience, export the following\n\
environment variables, depending on which service you will access:\n\
\n\
$(tput setaf 3)ONEZONE_HOST$(tput sgr0) - Onezone server URL, e.g. https://zone.example.com\n\
$(tput setaf 4)ONEPROVIDER_HOST$(tput sgr0) - Oneprovider server URL, e.g. https://provider.example.com\n\
$(tput setaf 5)ONEPANEL_HOST$(tput sgr0) - Onepanel server URL, e.g. https://zone.example.com:9443\n\
$(tput setaf 5)LUMA_HOST$(tput sgr0) - LUMA server URL, e.g. http://luma.example.com:8080\n\
$(tput setaf 5)CDMI_HOST$(tput sgr0) - Oneprovider CDMI endpoint, e.g. https://provider.example.com/cdmi\n\
\n\
as well as:\n\
\n\
$(tput setaf 3)ONEZONE_API_KEY$(tput sgr0) - access token, e.g. "ABCDEFGHIJKLMNOP"\n\
or\n\
$(tput setaf 3)ONEZONE_BASIC_AUTH$(tput sgr0) - basic authentication credentials, e.g.: "username:password"\n\
\n\
$(tput setaf 4)ONEPROVIDER_API_KEY$(tput sgr0) - access token, e.g. "ABCDEFGHIJKLMNOP"\n\
or\n\
$(tput setaf 4)ONEPROVIDER_BASIC_AUTH$(tput sgr0) - basic authentication credentials, e.g.: "username:password"\n\
\n\
$(tput setaf 5)ONEPANEL_BASIC_AUTH$(tput sgr0) - basic authentication credentials, e.g.: "username:password"\n\
\n\
$(tput setaf 5)CDMI_API_KEY$(tput sgr0) - access token, e.g. "ABCDEFGHIJKLMNOP"\n\
or\n\
$(tput setaf 5)CDMI_BASIC_AUTH$(tput sgr0) - basic authentication credentials, e.g.: "username:password"\n\
\n\
$(tput setaf 7)Basic usage:$(tput sgr0)\n\
\n\
$(tput setaf 3)Onezone REST client:$(tput sgr0)\n\
$ onezone-rest-cli -h\n\
$(tput setaf 3)Oneprovider REST client:$(tput sgr0)\n\
$ oneprovider-rest-cli -h\n\
$(tput setaf 3)Onepanel REST client$(tput sgr0)\n\
$ onepanel-rest-cli -h\n\
$(tput setaf 3)LUMA REST client$(tput sgr0)\n\
$ luma-rest-cli -h\n\
$(tput setaf 3)CDMI REST client$(tput sgr0)\n\
$ cdmi-cli -h\n\
$(tput setaf 3)Get information about specific operation, e.g.:$(tput sgr0)\n\
$ onezone-rest-cli getUserSpaces -h\n\
$(tput setaf 3)To switch to another Onedata version, please use the following command, e.g.:$(tput sgr0)\n\
$ onedata-select-version 18.02.0-rc12\n\
\n\
Online Onedata API documentation: https://onedata.org/#/home/api\n\
\n\
EOF\n\
' | tee -a ~/.bashrc ~/.zshrc

ENTRYPOINT ["zsh"]
