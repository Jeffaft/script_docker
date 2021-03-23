#!/bin/bash

#contrôle des paramètres

if [ $1 = help ]
then
	echo "$(tput setaf 6)
Le but de ce programme est d'automatiser la composition de service.
Il s'utilise en tapant ./docker_create image_source nom_destination path_app [path_dest]
		- l'image sera crée 
		- un conteneur Docker sera lancé sur le port 80 de la machine.$(tput sgr 0)"
	exit 2
fi

if [ $# -lt 3 ]
then
	echo "erreur: Syntaxe commande: image_source nom_destination path_app [path_dest]"
	exit 2
fi

if [ $# = 4 ]
then
	path_dest=$4
else
	path_dest="/var/www/html/"
fi

image_source=$1
nom_dest=$2
path_app=$3

#demande de confirmation
echo "$(tput setaf 6)Résumé de la demande :
- à partir de l'image : $image_source
- faire l'image : $nom_dest
- qui installe l'appli : $path_app
- dans : $path_dest$(tput sgr 0)"
read -p "confirmez vous cette exécution ? [y/n]" confirm

if [ $confirm = n ]
then
	echo 'Annulation volontaire'
	exit 2
elif [ $confirm != y ]
then
	exit 2
fi

#création Dockerfile
echo "FROM $image_source
MAINTAINER Julien Reynaud <reynaud_julien@yahoo.com>
ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get -y install apache2
RUN apt-get -y install git
RUN git clone $path_app $path_dest
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
EXPOSE 80
CMD /usr/sbin/apache2ctl -D FOREGROUND" > Dockerfile

echo "Création de l'image ... Cette opération peut prendre quelques instants."

#création et lancement conteneur
docker build -t $nom_dest .
docker run -d -p 8080:80 $nom_dest

#suppresion Dockerfile
rm Dockerfile