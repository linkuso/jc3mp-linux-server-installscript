#!/bin/bash
# init

apt-get update && apt-get upgrade -y
apt-get install lib32gcc1 git screen monit -y

echo "### Specify username to install under - can be a new or existing user - DO NOT use root ###"
read username
echo "### Specify password if new user ###"
read password
echo "### Specify server description ###"
read svdesc
echo "### Specify server ip ###"
read ip
echo "### Specify base port number. Each server needs 4 unique ports. ###"
echo "### additional ports will be incremented from the base port, e.g. 4201, 4202, 4203 ###"
read -i "4200" -e baseport
echo "### Specify server name ###"
read svname
echo "### Specify admin steam id (get your steam id from http://steamidfinder.com/) ###"
read adminsteamid
echo "### Specify server alias - a name to refer to this server by - use different names for multiple servers ###"
read svalias
echo "### Specify server password - leave blank for public ###"
read svpwd
echo "### Advertise server? (true/false) ###"
read svadvertise
while [[ ! $svadvertise == true ]] && [[ ! $svadvertise == false ]]; do
    echo "### Advertise server? ###"
    echo "### Please enter true or false. ###"
    read svadvertise
done

if id "$username" >/dev/null 2>&1; then
        echo "### User already exists ###"
else
        echo "### Creating user $username ###"
        useradd -m -g users -d /home/"$username" -s /bin/bash -p $(echo "$password" | openssl passwd -1 -stdin) "$username"
fi

if [ -d /home/'$username'/jc3mp/'$svalias' ]; then
  echo "### You already have a server with that alias ###"
  exit 0
fi



su "$username" -c "mkdir -p /home/'$username'/jc3mp/'$svalias'"

if [ ! -d /home/'$username'/jc3mp/'$svalias' ]; then
  su "$username" -c "mkdir -p /home/'$username'/steamcmd"
  su "$username" -c "curl -sqL 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' | tar -xzv -C /home/$username/steamcmd"
    #su deleteme -c "curl -sqL 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' | tar -xzv -C /home/deleteme/steamcmd"
fi
chmod 754 /home/"$username"/steamcmd/steamcmd.sh 

su "$username" -c "/home/'$username'/steamcmd/steamcmd.sh +login anonymous +exit"
su "$username" -c "/home/'$username'/steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/'$username'/jc3mp/"$svalias" +app_update 619960 validate +exit"
 
mkdir /home/"$username"/jc3mp/"$svalias"/packages
cd /home/"$username"/jc3mp/"$svalias"/packages
git clone https://gitlab.nanos.io/jc3mp-packages/spawn-menu
git clone https://gitlab.nanos.io/jc3mp-packages/freeroam
git clone https://gitlab.nanos.io/jc3mp-packages/command-hints
git clone https://gitlab.nanos.io/jc3mp-packages/command-manager
git clone https://gitlab.nanos.io/jc3mp-packages/chat
 
mkdir /home/"$username"/jc3mp/"$svalias"/monit
git clone https://github.com/TarryPaloma/jc3mp-linux-server-monit /home/"$username"/jc3mp/"$svalias"/monit
sed -i "s/NAME='replaceme'/NAME='$svalias'/" /home/"$username"/jc3mp/"$svalias"/monit/alias.sh
sed -i "s/DIR=\/home\/'replaceme'\/jc3mp\/'replaceme'/DIR=\/home\/$username\/jc3mp\/$svalias/" /home/"$username"/jc3mp/"$svalias"/monit/alias.sh
mv /home/"$username"/jc3mp/"$svalias"/monit/alias.sh /home/"$username"/jc3mp/"$svalias"/monit/"$svalias".sh
chmod 754 /home/"$username"/jc3mp/"$svalias"/monit/"$svalias".sh
touch /home/"$username"/jc3mp/"$svalias"/monit/"$svalias".pid /home/"$username"/jc3mp/"$svalias"/monit/"$svalias".log

cat > /home/"$username"/jc3mp/"$svalias"/config.json <<EOF
{
    "announce": $svadvertise,
    "description": "$svdesc",
    "host": "$ip",
    "httpPort": $((baseport + 3)),
    "logLevel": 7,
    "logo": "",
    "maxPlayers": 32,
    "maxTickRate": 60,
    "name": "$svname",
    "password": "$svpwd",
    "port": $baseport,
    "queryPort": $((baseport + 1)),
    "requiredDLC": [],
    "steamPort": $((baseport + 2))
}
EOF

sed -i "/admins: \[/a \\\t'$adminsteamid'," /home/"$username"/jc3mp/"$svalias"/packages/freeroam/gm/config.js
sed -i "/death_reasons: \[/a \\\t'tickled the belly of',\n \\t'popped a cherry in',\n \\t'fragged',\n \\t'mutilated',\n \\t'720 noscoped',\n \\t'gatted',\n \\t'bamboozled',\n \\t'mullered',\n \\t'inflicted mortal damage upon',\n \\t'erased',\n \\t'julienned',\n \\t'killded',\n \\t'punctured',\n \\t'perforated',\n \\t'deaded'," /home/"$username"/jc3mp/"$svalias"/packages/freeroam/gm/config.js

cat >> /etc/monit/monitrc <<EOF

check process jc3mpServer_$svalias with pidfile /home/$username/jc3mp/$svalias/monit/$svalias.pid
start program = "/bin/su $username -c '/home/$username/jc3mp/$svalias/monit/$svalias.sh start'"
stop program = "/bin/su $username -c '/home/$username/jc3mp/$svalias/monit/$svalias.sh stop'"
EOF

service monit stop
service monit start

chown -R "$username":users /home/"$username"/jc3mp
su "$username"
