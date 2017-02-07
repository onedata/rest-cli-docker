FROM ubuntu:16.10
MAINTAINER Bartek Kryza <bkryza@gmail.com>

RUN apt-get update -y && apt-get full-upgrade -y
RUN apt-get install -y bsdmainutils bash-completion zsh curl cowsay git vim \
                       libxml2 autoconf2.13 make gcc g++ figlet wget python \
                       python-dev python-pip

RUN pip install virtualenv
#
# Install oh-my-zsh
#
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" || true

#
# Download and Configure SpiderMonkey
#
RUN mkdir -p /tmp/spidermonkey \
	  && cd /tmp/spidermonkey \
	  && wget -O/tmp/spidermonkey/mozjs-24.2.0.tar.bz2 https://ftp.mozilla.org/pub/mozilla.org/js/mozjs-24.2.0.tar.bz2

RUN export SHELL=/bin/bash \
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
    && rm -rf spidermonkey

#
# Install jsawk
#
RUN wget -O/usr/local/bin/jsawk http://github.com/micha/jsawk/raw/master/jsawk
RUN chmod a+x /usr/local/bin/jsawk

ADD onedata-select-version.sh /usr/local/bin/onedata-select-version
RUN chmod a+x /usr/local/bin/onedata-select-version

#
# Enable cowsay
#
RUN ln -s /usr/games/cowsay /usr/bin/cowsay

#
# Add Onedata REST clients
#
COPY onepanel-rest-clients.tar.gz /tmp/onepanel-rest-clients.tar.gz
COPY oneprovider-rest-clients.tar.gz /tmp/oneprovider-rest-clients.tar.gz
COPY onezone-rest-clients.tar.gz /tmp/onezone-rest-clients.tar.gz
RUN mkdir -p /var/opt/onedata/onepanel
RUN mkdir -p /var/opt/onedata/oneprovider
RUN mkdir -p /var/opt/onedata/onezone
RUN tar -zxf /tmp/onepanel-rest-clients.tar.gz -C /var/opt/onedata/onepanel/
RUN tar -zxf /tmp/oneprovider-rest-clients.tar.gz -C /var/opt/onedata/oneprovider/
RUN tar -zxf /tmp/onezone-rest-clients.tar.gz -C /var/opt/onedata/onezone/
RUN chmod 755 -R /var/opt/onedata
ADD _onedata-select-version /usr/local/share/zsh/site-functions/_onedata-select-version
RUN chmod 755 /usr/local/share/zsh/site-functions/_onedata-select-version

#
# Setup default Onedata version and prompt
#
ADD zshrc /root/.zshrc
ADD onedata.zsh-theme /root/.oh-my-zsh/themes/onedata.zsh-theme
ADD onedata.plugin.zsh /root/.oh-my-zsh/plugins/onedata/onedata.plugin.zsh
RUN echo -n 3.0.0-rc12 > /etc/onedata.release
RUN echo 'export ZSH_THEME="onedata"' >> ~/.zshrc
RUN echo 'export ZSH_PLUGINS=(onedata)' >> ~/.zshrc
RUN echo 'export PS1="[Onedata REST CLI] \$ "' >> ~/.bashrc

#
# Fake zsh history
#
RUN echo '\n\
: 1486495368:0;onepanel-rest-cli\n\
: 1486495397:0;oneprovider-rest-cli\n\
: 1486495418:0;onezone-rest-cli\n\
: 1486495743:0;onedata-select-version\n\
' | tee -a ~/.zsh_history

RUN /usr/local/bin/onedata-select-version 3.0.0-rc12

RUN echo "compdef _onedata-select-version onedata-select-version" | tee -a ~/.zshrc

#
# Setup a welcome message with basic instruction
#
RUN echo "figlet \"O n e d a t a\"" | tee -a ~/.bashrc ~/.zshrc

RUN echo 'cat << EOF\n\
This Docker provides preconfigured environment for accessing $(tput setaf 6)Onedata$(tput sgr0) REST services\n\
using command line interface. For convenience, export the following\n\
environment variables, depending on which service you will access:\n\
\n\
$(tput setaf 3)ONEZONE_HOST$(tput sgr0) - Onezone server URL, e.g. https://zone.example.com:8443\n\
$(tput setaf 4)ONEPROVIDER_HOST$(tput sgr0) - Oneprovider server URL, e.g. https://provider.example.com:8443\n\
$(tput setaf 5)ONEPANEL_HOST$(tput sgr0) - Onepanel server URL, e.g. https://panel.example.com:8443\n\
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
