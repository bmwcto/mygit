## set frp folder
## v5
## Fri Jul  3 22:33:06 CST 2020


frpcd=$(pwd)
systemctl stop frps
systemctl daemon-reload
rm /usr/bin/frps
rm /etc/frps/frps.ini
rm /usr/lib/systemd/system/frps.service
ln -s $frpcd/frps /usr/bin/frps
mkdir -p /etc/frps/
mkdir -p /var/log/frps/
ln -s $frpcd/frps.ini /etc/frps/frps.ini
cp $frpcd/frps.service /usr/lib/systemd/system/
chmod a+x $frpcd/frps
systemctl daemon-reload
systemctl start frps
systemctl enable frps
systemctl status frps
