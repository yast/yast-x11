FROM yastdevel/cpp:sle12-sp3
RUN zypper --gpg-auto-import-keys --non-interactive in --no-recommends \
  xorg-x11-libX11-devel \
  xorg-x11-libXmu-devel

COPY . /usr/src/app

