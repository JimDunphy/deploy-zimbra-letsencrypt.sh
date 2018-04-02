# deploy-zimbra-letsencrypt.sh

# Purpose
Simple method to install letsencrypt certificates with Zimbra 8.7+ without installing excessive external packages and software. Keep it simple, flexible, and allow to choose best method for certs.  Note: Running zmcertmgr as the zimbra user makes this method 8.7+ specific. This is an automated script that is run from cron. If the CERT hasn't met some minimum threshold (min), it will exit and is safe to call daily from cron.

# Operation
Letsencrypt uses an automated and real-time methods to create Certificate BUT it does require a challenge/verification to establish who you say you are. There are various methods to accomplish this which generally require that you have a program to listen at port 80/443 on the machine you want the cert for. This isn't appropriate sometimes especially when first using/testing, etc. We document the DNS method and a standalone method below. See: https://github.com/Neilpang/acme.sh for a full list of supported modes. Choose the method that works best for you. Any of the methods will work with this script.

# Set up acme.sh 
This project is a self contained bash script to create letsencrypt certificates and can be intalled without root.  Do the following from your home directory.
Note: see project for more examples.
```bash
git clone https://github.com/Neilpang/acme.sh
cd acme.sh
./acme.sh --install --nocron  # creates .acme.sh directory in home directory
```
Note: make the first -d entry your zmhostname
```bash
chmod 755 .acme.sh   #to help zimbra user pull certs
acme.sh --issue --dns -d mail.example.com mail.example.net -d tmail.example.com
```
Add DNS txt records to zones from output of command above
```bash
acme.sh --renew -d mail.example.com -d mail.example.net -d tmail.example.com
or (just the first entry)
acme.sh --renew -d mail.example.com 
```
You now have certificates that can be used by zimbra. Certificates are installed in .acme.sh using the first -d entry as the directory name ie. mail.example.com in this example.

Note: if you don't mind taking an outage witih zimbra. The following method might be simpler. It assumes that you have a single host architecture.
```bash
acme.sh --issue --standalone -d mail.example.com -d mail.example.net -d tmail.example.com
```
Note: this will operate at port 80 which is why zimbra needs to be shutdown and will handle the challenge/Response automatically without any extra steps.

# Set up  deploy-zimbra-letsencrypt.sh
As zimbra user:
```bash
su - zimbra
git clone https://github.com/JimDunphy/deploy-zimbra-letsencrypt.sh.git /tmp/letsencrypt
```
As root:
```bash
su - 
mv /tmp/letsencrypt /opt/
chown zimbra /opt/letsencrypt
exit
```
modify the following variables in deploy-zimbra-letsencrypt.sh
```bash
min=60	#days for CERT expire before will load new certificate. Make large for testing (ie. 10000)
domain="mail.example.com"
user="/home/YourName" # ~user/.acme.sh --- owner that runs acme.sh
# verbose output
d=1  # change to 0 if run from cron
exit # comment this out after adjusting the top two values
```
# General Overview
- issue a letsencrypt certificate via any method from acme.sh
- run deploy-zimbra-letsencrypt.sh 

Deploy-zimbra-letsencrypt.sh understands the directory format used by acme.sh and will include the intermediate certificate so that zimbra can verify and install letsencrypt certificates.

# Install Certificates
Script will stop at each step waiting for a CR when d=1
Run as zimbra user:
```bash
su - zimbra
./deploy-zimbra-letsencrypt.sh
```
# Renewal 
Note: needs to be done 30 days or less or you will have to repeat challenge/Response for the manual DNS method. See recipies for more detail.
```bash
acme.sh --force --renew -d mail.example.com -d mail.example.net -d tmail.example.com
```

# Unattended Operation 
run from cron
- Run acme renewal every 90 days or less depending on method used
- Run deploy-zimbra-letscencrypt.sh at an interval to reflect the renewals
- Bonus: add checks to alert of any failures of acme.sh/CERTs
Example Cron Entry:
- 5 1 * * * su - zimbra /opt/letsencrypt/deploy-zimbra-letsencrypt.sh

# Other uses or multi-host
- use different server to create letsencrypt certs
- copy to remote location on each server (ssh/puppet/etc)
- have each server call deploy-zimbra-letscencrypt.sh

# Tricks
Can verify a new server install with users when using the zimbra proxy by appending this to the end of your normal list when creating certificates. That allows you to verify the actual CERT you will be using in production without having to install it first during testing on your production server[s].
```bash
-d tmail.example.com
```

- use --issue --renew-hook when renewing with acme.sh to call deploy-zimbra-letsencrypt.sh to install. Note: modify min variable with deploy-zimbra-letsencrypt.sh and install acme.sh as zimbra. (NOT TESTED)
```Bash
acme.sh --issue --renew-hook /opt/letsencrypt/deploy-zimbra-letsencrypt.sh
```
Another option if acme.sh runs as a different user.
```Bash
echo 'acme.sh-user ALL = (zimbra) NOPASSWD: /opt/letsencrypt/deploy-zimbra-letsencrypt.sh' >> /etc/sudoers
acme.sh --issue --renew-hook "sudo -u zimbra /opt/letsencrypt/deploy-zimbra-letsencrypt.sh"
```
- use --dns and a provider for automatic insertion/removal. Modify 
account.conf in .acme.sh ... More information at: https://github.com/Neilpang/acme.sh/tree/master/dnsapi
- Can practice creating certificates without forcing zimbra to be involved
- Can practice loading certificates without forcing letsencrypt to be involved
- letsencrypt has some limits: 100 domains per certificate, 500 certificates per ip address and 20 different certs per week. see: https://letsencrypt.org/docs/rate-limits/
- deploy-zimbra-letsencrypt.sh cam be run every at any interval but will only load a new certificate and restart zimbra when the min value has been reached. 

# Bugs
Can call deploy-zimbra-letscencrypt.sh as often as you want with valid CERTs but if the cert is expired, zimbra will not come up. Solution: create valid CERTs and run again.

# Lessons Learned
Goals from 6 months of deployement with zimbra and letsencrypt and a topic at:
http://forums.zimbra.org/viewtopic.php?f=15&t=60781&sid=2a91c5a8f518e7b9d8147b8f26495023
- Stay out of /opt/zimbra 
- run as zimbra to reduce complexity
- run as normal user for letsencrypt stuff
- minimize hooks for zimbra as single cron entry
- do not run as root
- minimize downtime due to zimbra restart
- decouple letsencrypt with automated zimbra script
- support multi-domain, multi-architecture zimbra installs
- support various methods of challege/response method for letsencrypt certs
- automate creating IdentTrust chain to reduce zimbra verification errors
- workaround zmcertmgr chdir bug by copying certs first
- Keep it simple

