# deploy-zimbra-letsencrypt.sh

# Purpose
Simple method to install letsencrypt certificates with Zimbra 8.7+ without installing excessive external packages and software. Keep it simple, flexible, and allow to choose best method for certs.  Note: Running zmcertmgr as zimbra makes this 8.7+ specific. This is an automated method that is run from cron.

# Operation
Letsencrypt is an automated and real-time method to create a Certificate but does require a challenge/verification to establish who you say you are. There are various modes to accomplish which generally require that you have a program listein at port 80/443 on the machine you want the cert for. This isn't appropraite sometimes, and we document the DNS method below. See: https://github.com/Neilpang/acme.sh for a full list of supported modes.

# Set up acme.sh 
Do the following from your home directory.
```bash
git clone https://github.com/Neilpang/acme.sh.git
```
```bash
cd acme.sh
```
```bash
./acme.sh --install   # creates a .acme.sh directory
```
Note: make the first -d entry your zmhostname
```bash
chmod 755 .acme.sh   #to help zimbra user pull certs
```
```bash
acme.sh --issue --dns -d mail.example.com mail.example.net -d tmail.example.com
```
Add txt records to zones from output of commands above
```bash
acme.sh --renew -d mail.example.com -d mail.example.net -d tmail.example.com
```
You now have certificates that can be used by zimbra. Certificates are installed in .acme.sh using the first -d entry... ie. mail.example.com

# Set up  deploy-zimbra-letsencrypt.sh
As root:
```bash
su - 
mkdir /opt/letsencrypt
chown zimbra /opt/letscencrypt
exit
```
As zimbra user:
```bash
su - zimbra
cd /opt/letsencrypt
git clone https://github.com:JimDunphy/deploy-zimbra-letsencrypt.sh.git
```
modify the following variables in deploy-zimbra-letsencrypt.sh
```bash
min=159	#when you want to restart zimbra - make large to force ie. 159 for testing
domain="mail.example.com"
user="/home/YourName" # ~user/.acme.sh --- owner that runs acme.sh
# verbose output
d=1  # change to 0 if run from cron
exit # comment this out after adjusting the top two values
```
Install Certificates. Script will stop at each step waiting for a CR when d=1
Run as zimbra user:
```bash
./deploy-zimbra-letsencrypt.sh
```

# Renewal 
Note: needs to be done 59 days or less or will have to repeat challenge/Response.  As user that installed acme.sh
```bash
acme.sh --force --renew -d mail.example.com -d mail.example.net -d tmail.example.com
```

# Unattended use
- Run renewal every 59 days or less
- Run deploy-zimbra-letscencrypt.sh every 60 days or so
- Bonus: add checks to see that new certs were created

# Other uses or multi-host
- use different server to create letsencrypt certs
- copy to remote location on each server
- have each server call deploy-zimbra-letscencrypt.sh

# Bugs
Can call deploy-zimbra-letscencrypt.sh as often as you want with valid CERTs but if the cert is expired, zimbra will not come up. Solution: create valid CERTsand run again.

# Lessons Learned
Goals from 6 months of deployement with zimbra and letsencrypt and a topic at:
http://forums.zimbra.org/viewtopic.php?f=15&t=60781&sid=2a91c5a8f518e7b9d8147b8f26495023
- Stay out of /opt/zimbra 
- run as zimbra to reduce complexity
- run as normal user for letsencrypt stuff
- minimize my hooks to a single cron entry for zimbra
- do not run as root
- minimize downtime due to zimbra restart
- decouple letsencrypt with automated zimbra script
- support multi-domain, multi-architecture zimbra installs
- support various methods of challege/response method for letsencrypt certs
- Keep it simple

