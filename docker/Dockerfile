FROM pandoc/latex:latest-ubuntu
LABEL maintainer="Philipp Kohn <wider.fissile_0i@icloud.com>"

#ENV DEBIAN_FRONTEND noninteractive
#ENV DEBCONF_NONINTERACTIVE_SEEN true
#ENV HOME /

# get pip
RUN apt-get update && apt-get install python3 python3-pip git-all -y && ln -s /usr/bin/python3 /usr/bin/python

# get xnos
RUN python -m pip install --force-reinstall --root-user-action=ignore --break-system-packages git+https://github.com/tomduck/pandoc-xnos@284474574f51888be75603e7d1df667a0890504d#egg=pandoc-xnos 

# install missing TexLive packages
RUN tlmgr install textpos subfigure fncylab doublestroke siunitx threeparttable charter

COPY docker/build.sh /build.sh
RUN chmod +x build.sh

ENTRYPOINT [ "/build.sh" ]

WORKDIR /github/workspace

VOLUME ["/github/workspace"]
