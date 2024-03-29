#!/bin/bash

mkdir -p /root/.ssh
ssh-keyscan -H "$2" >> /root/.ssh/known_hosts

if [ -z "$DEPLOY_KEY" ];
then
	echo $'\n' "------ DEPLOY KEY NOT SET YET! ----------------" $'\n'
	exit 1
else
	printf '%b\n' "$DEPLOY_KEY" > /root/.ssh/id_rsa
	chmod 400 /root/.ssh/id_rsa

	echo $'\n' "------ CONFIG SUCCESSFUL! ---------------------" $'\n'
fi

rsync --progress -avzhI \
	--exclude='.git/' \
	--exclude='.git*' \
	--exclude='.editorconfig' \
	--exclude='Dockerfile' \
	--exclude='readme.md' \
	--exclude='README.md' \
	--exclude='node_modules' \
	-e "ssh -i /root/.ssh/id_rsa" \
	--rsync-path="sudo rsync" ./dist/ $1@$2:$3

if [ $? -eq 0 ]
then
	echo $'\n' "------ SYNC SUCCESSFUL! -----------------------" $'\n'
	echo $'\n' "------ RELOADING PERMISSION -------------------" $'\n'

	ssh -i /root/.ssh/id_rsa -t $1@$2 "sudo chown -R $4:$5 $3"
	ssh -i /root/.ssh/id_rsa -t $1@$2 "sudo chmod 775 -R $3"
	
	if [ $6 ]
	then
	echo $'\n' "------ RELOAD LIGHTSPEED -------------------" $'\n'
	
	ssh -i /root/.ssh/id_rsa -t $1@$2 "/root/.brighthub/brighthub.sh web-restart"
	
	fi

	echo $'\n' "------ CONGRATS! DEPLOY SUCCESSFUL!!! ---------" $'\n'
	exit 0
else
	echo $'\n' "------ DEPLOY FAILED! -------------------------" $'\n'
	exit 1
fi
