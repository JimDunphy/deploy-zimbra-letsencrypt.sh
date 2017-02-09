# Single Server Zimbra - fully automated

# Initial Setup
Install acme.sh as different user than zimbra.
ie) /home/XXX is the home of user XXX

```bash
su - XXX   
git clone https://github.com/Neilpang/acme.sh
cd acme.sh
./acme.sh --install
chmod 755 .acme.sh   # the install created this directory
```
At this point we have acme.sh checking every day via cron to see if the certificates should be renewed. Normally it will only be renewed if the ceritifcate is past 60 days as currently set by the code.

Next we create our first Letsencrypt certificates. 

# Method 1 (STANDALONE port 80)
We will use the stand-alone method. Login as the user that acme.sh was installed as. Standalone listens on port 80 and is used by letsencrypt to verify you are who you say you are. To facilitate this, we stop the proxy that is listening at this port. 

```bash
su - zimbra
zmproxyctl stop
exit
cd
acme.sh --issue --standalone -d mail.example.com -d mail.example.net
su - zimbra
zmproxyctl start
exit
```
At this point we have a directory /home/XXX/.acme.sh/mail.example.com that contains the certificate.

# Method 2 (DNS)
We will use the DNS method.  Does not require initial outage of zimbra.

```bash
acme.sh --issue --dns -d mail.example.com mail.example.net
```
add the DNS text records from the output above
```bash
acme.sh --renew --dns -d mail.example.com mail.example.net
```

At this point we have a directory /home/XXX/.acme.sh/mail.example.com that contains the certificate. You can remove the TXT records from the zone. They are not needed anymore.

# Last Step for acme.sh
Modify the crontab entry that was created and add --force. Change it to say 59 days.  
```bash
crontab -e
```
Example: 
 0 0 */59 * * acme.sh --force --cron --home /home/XXX/.acme.sh

You can test it works from the command line by running it like this.

```bash
cd /home/XXX
acme.sh --force --cron --home /home/XXX/.acme.sh
```

At this point you have a renewed certificate.  

# Zimbra Script setup
As zimbra user
```bash
su - zimbra
git clone https://github.com/JimDunphy/deploy-zimbra-letsencrypt.sh.git /tmp/letsencrypt
```

The deploy-zimbra-letsencrypt.sh uses 3-4 configuration variables to take the certificates in /home/XXX/.acme.sh and install them.  It doesn't care which method you used to create those certificates. It has logic to check the certificates and update them when it is time. First run it by hand to verify your setup. It will stop before each step to allow you to see if there are any errors.

# Modify deploy-zimbra-letsencrypt.sh 
There are 4 variables that define its function.

- min=60  
Normally, It will not update the certificate if its not older than 60 days leftbefore it will expire. If you want to force it to work, change this to something large ...say 1000

- domain=mail.example.com
This is the first -d entry you used when you created your domain with acme.sh. It should be the zmhostname. Change this entry to match this directory:
/home/XXX.acme.sh/mail.example.com

- user="/home/XXX'
This is the user home directory and is used to copy that directory from /home/XXX/.acme.sh/$domain to /opt/letsencrypt. If you have a permision error, it will alert you. This is a common problem during initial setup.

- d=1
This will provide output of what is happening and will stop after each step. You can stop it at anytime. Set this to d=0 when you add this to cron

# Updating zimbra and its certificates
You run it without any arguments
```bash
/opt/letsencrypt/deploy-zimbra-letsencrypt.sh
```

If will stop and restart zimbra at the end. You can repeat this as many times as it takes. To automate this, change the min=60 and d=0 in the script and run this from cron as the zimbra user. It will only install the certificate when the min time is 60 days so it can run every day if you like.

This method gives you 1 day to verify your certificates are being created as expected but in reality you have already tested this and know it works.  

This is a work in progress... Will show other methods including a central server where you do not have to install .acme.sh on any zimbra server and just the deploy-zimbra-letsencrypt.sh script.


