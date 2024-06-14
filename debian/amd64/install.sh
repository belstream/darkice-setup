#!/bin/bash

echo "deb http://deb.debian.org/debian/ bullseye main contrib non-free" | tee /etc/apt/sources.list.d/debian-non-free.list

# Mise à jour de la liste des paquets
apt-get update

# Installation des paquets nécessaires
apt-get install -y wget supervisor dh-autoreconf libtool libtool-bin libasound2-dev \
libfftw3-dev build-essential devscripts autotools-dev fakeroot dpkg-dev debhelper \
autotools-dev dh-make quilt ccache libsamplerate0-dev libpulse-dev libaudio-dev lame \
libjack-jackd2-dev libasound2-dev libtwolame-dev libfaad-dev libflac-dev libshout3-dev \
libmp3lame-dev libopus-dev libfaac-dev alsa-utils

# Création du répertoire /usr/local/src et déplacement dans ce répertoire
mkdir -p /usr/local/src && cd /usr/local/src

# Téléchargement et extraction de libaacplus
wget https://github.com/belstream/libaacplus/raw/main/libaacplus-2.0.2.tar.gz
tar -xzf libaacplus-2.0.2.tar.gz
cd libaacplus-2.0.2

# Téléchargement et application du patch pour libaacplus
wget https://raw.githubusercontent.com/belstream/libaacplus/main/patch/libaacplus-2.0.2-clang-inline-redefinition.patch
patch -p1 < libaacplus-2.0.2-clang-inline-redefinition.patch

# Compilation et installation de libaacplus
./autogen.sh --enable-static --enable-shared
make
make install
ldconfig
cd ..

# Clonage de darkice et aller au commit du 14/11/2023 (pour figer la version car la release 1.4 ne fonctionne pas en aac)
git clone https://github.com/rafael2k/darkice
git checkout 93b8d97
cd darkice/darkice/trunk

# Configuration, compilation et installation de darkice
./autogen.sh
./configure --with-faac --with-lame --with-alsa --with-aacplus --with-samplerate --with-vorbis
make
make install

# Vérification de l'installation de darkice
/usr/local/bin/darkice -h

# Téléchargement de la configuration de darkice pour supervisor
wget https://raw.githubusercontent.com/belstream/supervisor-darkice/main/conf.d/darkice.conf -O /etc/supervisor/conf.d/darkice.conf

# Ajout des paramètres de l'interface HTTP de Supervisor
bash -c 'cat <<EOF >> /etc/supervisor/supervisord.conf

[inet_http_server]
port = 80
username = admin
password = hackme
EOF'

# redémarrage du service supervisor
systemctl restart supervisor
