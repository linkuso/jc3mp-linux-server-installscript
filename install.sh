#!/bin/bash
# init

apt-get update && apt-get upgrade -y
apt-get install lib32gcc1 steamcmd git screen monit lib32gcc1 -y

echo "Specify username"
read username
echo "Specify password"
read password
echo "Specify server description"
read svdesc
echo "Specify server ip"
read ip
echo "Specify server name"
read svname
echo "Specify admin steam id (get your steam id from http://steamidfinder.com/)"
read adminsteamid
echo "Specify server alias - use differnet names for multiple servers"
read svalias
 
useradd -m -u 1337 -g users -d /home/"$username" -s /bin/bash -p $(echo "$password" | openssl passwd -1 -stdin) "$username"
adduser "$username" sudo
su "$username" -c "mkdir /home/'$username'/jc3mp/'$svalias'"
su "$username" -c "steamcmd +login anonymous +exit"
su "$username" -c "steamcmd +login anonymous +force_install_dir /home/'$username'/jc3mp/"$svalias" +app_update 619960 validate +exit"
 
mkdir /home/"$username"/jc3mp/"$svalias"/packages
cd /home/"$username"/jc3mp/"$svalias"/packages
git clone https://gitlab.nanos.io/jc3mp-packages/spawn-menu
git clone https://gitlab.nanos.io/jc3mp-packages/freeroam
git clone https://gitlab.nanos.io/jc3mp-packages/command-hints
git clone https://gitlab.nanos.io/jc3mp-packages/command-manager
git clone https://gitlab.nanos.io/jc3mp-packages/chat
 
mkdir /home/"$username"/jc3mp/"$svalias"/monit
git clone https://github.com/TarryPaloma/jc3mp-linux-server-monit /home/"$username"/jc3mp/"$svalias"/monit
mv /home/"$username"/jc3mp/"$svalias"/monit/alias.sh /home/"$username"/jc3mp/"$svalias"/monit/"$svalias".sh
touch /home/"$username"/jc3mp/"$svalias"/monit/"$svalias".pid /home/"$username"/jc3mp/"$svalias"/monit/"$svalias".log

cat > /home/"$username"/jc3mp/"$svalias"/config.json <<EOF
{
    "announce": true,
    "description": "$svdesc",
    "host": "$ip",
    "httpPort": 4203,
    "logLevel": 7,
    "logo": "",
    "maxPlayers": 32,
    "maxTickRate": 60,
    "name": "$svname",
    "password": "",
    "port": 4200,
    "queryPort": 4201,
    "requiredDLC": [],
    "steamPort": 4202
}
EOF

sed -i "/admins: \[/a \\\t'$steamid'," /home/"$username"/jc3mp/packages/freeroam/gm/config.js
sed -i "/death_reasons: \[/a \\\t'tickled the belly of',\n \\t'popped a cherry in',\n \\t'fragged',\n \\t'mutilated',\n \\t'720 noscoped',\n \\t'gatted',\n \\t'bamboozled',\n \\t'mullered',\n \\t'inflicted mortal damage upon',\n \\t'erased',\n \\t'julienned',\n \\t'killded',\n \\t'punctured',\n \\t'perforated',\n \\t'deaded'," /home/"$username"/jc3mp/packages/freeroam/gm/config.js


chown -R "$username":users /home/"$username"/jc3mp
su "$username"
