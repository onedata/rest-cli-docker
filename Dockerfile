FROM ubuntu:16.10
MAINTAINER Bartek Kryza <bkryza@gmail.com>

RUN apt-get update -y && apt-get full-upgrade -y
RUN apt-get install -y bsdmainutils autoconf2.13 make gcc g++ figlet wget \
                       python python-dev python-pip \
    && pip install virtualenv \
    && mkdir -p /tmp/spidermonkey \
	  && cd /tmp/spidermonkey \
	  && wget -O/tmp/spidermonkey/mozjs-24.2.0.tar.bz2 https://ftp.mozilla.org/pub/mozilla.org/js/mozjs-24.2.0.tar.bz2 \
    && export SHELL=/bin/bash \
    && cd /tmp/spidermonkey \
	  && tar xjf mozjs-24.2.0.tar.bz2 \
	  && cd /tmp/spidermonkey/mozjs-24.2.0/js/src \
	  && autoconf2.13 \
	  && mkdir build-release \
	  && cd build-release \
	  && ../configure \
    && make \
    && make install \
    && make clean \
    && cd /tmp \
    && rm -rf spidermonkey \
    && rm -f /usr/local/lib/libmoz* \
    && apt-get remove --purge -y $python python-dev python-pip make gcc g++ \
                                  autoconf2.13 git $AUTO_ADDED_PACKAGES \
                                  `apt-mark showauto` \
    && apt-get autoremove --purge -y libx11-6 libx11-data

RUN apt-get install -y zsh libxml2-utils openssh-client zsh zsh-common wget curl \
                       cowsay figlet git vim-tiny libjson-perl \
    && apt-get clean

#
# Install oh-my-zsh
#
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" || true

#
# Install jsawk, resty and pp
#
RUN    wget -O/usr/local/bin/jsawk http://github.com/micha/jsawk/raw/master/jsawk \
    && wget -O/usr/local/bin/resty http://github.com/micha/resty/raw/master/resty \
    && wget -O/usr/local/bin/pp http://github.com/micha/resty/raw/master/pp \
    && chmod a+x /usr/local/bin/jsawk \
    && chmod a+x /usr/local/bin/resty \
    && chmod a+x /usr/local/bin/pp

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
RUN    mkdir -p /var/opt/onedata/onepanel \
    && mkdir -p /var/opt/onedata/oneprovider \
    && mkdir -p /var/opt/onedata/onezone \
    && tar -zxf /tmp/onepanel-rest-clients.tar.gz -C /var/opt/onedata/onepanel/ \
    && tar -zxf /tmp/oneprovider-rest-clients.tar.gz -C /var/opt/onedata/oneprovider/ \
    && tar -zxf /tmp/onezone-rest-clients.tar.gz -C /var/opt/onedata/onezone/ \
    && chmod 755 -R /var/opt/onedata \
    && chmod 755 /usr/local/share/zsh/site-functions/_onedata-select-version \
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
RUN    echo -n 3.0.0-rc12 > /etc/onedata.release \
    && echo 'export ZSH_THEME="onedata"' >> ~/.zshrc \
    && echo 'export ZSH_PLUGINS=(onedata)' >> ~/.zshrc \
    && echo 'export PS1="[Onedata REST CLI] \$ "' >> ~/.bashrc \
    && echo "compdef _onedata-select-version onedata-select-version" | tee -a ~/.zshrc \
    && /usr/local/bin/onedata-select-version 3.0.0-rc12 \
    && echo "figlet \"O n e d a t a\"" | tee -a ~/.bashrc ~/.zshrc

#
# Setup welcome message
#
RUN echo 'cat << EOF\n\
This Docker provides preconfigured environment for accessing $(tput setaf 6)Onedata$(tput sgr0) REST services\n\
using command line interface. For convenience, export the following\n\
environment variables, depending on which service you will access:\n\
\n\
$(tput setaf 3)ONEZONE_HOST$(tput sgr0) - Onezone server URL, e.g. https://zone.example.com:8443\n\
$(tput setaf 4)ONEPROVIDER_HOST$(tput sgr0) - Oneprovider server URL, e.g. https://provider.example.com:8443\n\
$(tput setaf 5)ONEPANEL_HOST$(tput sgr0) - Onepanel server URL, e.g. https://zone.example.com:9443\n\
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
$(tput setaf 7)Basic usage:$(tput sgr0)\n\
\n\
$(tput setaf 3)Onezone REST client:$(tput sgr0)\n\
$ onezone-rest-cli -h\n\
$(tput setaf 3)Oneprovider REST client:$(tput sgr0)\n\
$ oneprovider-rest-cli -h\n\
$(tput setaf 3)Onepanel REST client$(tput sgr0)\n\
$ onepanel-rest-cli -h\n\
$(tput setaf 3)Get information about specific operation, e.g.:$(tput sgr0)\n\
$ onezone-rest-cli getUserSpaces -h\n\
$(tput setaf 3)To switch to another Onedata version, please use the following command, e.g.:$(tput sgr0)\n\
$ onedata-select-version 3.0.0-rc11\n\
\n\
Online Onedata API documentation: https://onedata.org/#/home/api\n\
\n\
EOF\n\
' | tee -a ~/.bashrc ~/.zshrc

ENTRYPOINT ["zsh"]
