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
We will use the stand-alone method. Login as the user that acme.sh was installed as. Standalone listens on port 80 so it requires that acme.sh be runs as root to bind to port 80 and is used by letsencrypt to verify you are who you say you are. To facilitate this, we stop the proxy that is listening at this port. Note: if you require all zimbra logins via https (port 443), then you do not need to issue the zmproxyctl stop/start cycle.

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

# Method 2a (DNS)
We will use the DNS method.  Does not require initial outage of zimbra.

```bash
acme.sh --issue --dns -d mail.example.com -d mail.example.net
```
add the DNS text records from the output above
```bash
acme.sh --renew --dns -d mail.example.com -d mail.example.net
```
# Method 2B (DNS + API)
We will use the DNS method but have acme.sh insert the TXT records automatically.  Does not require initial outage of zimbra. Check the list of supported DNS providers. In this example, we use cloudflare. Add the following entries to the account.conf file in the .acme.sh directory.  SAVED_CF='......' where this is your API key from Cloudflare and SAVED_CF_Email='user@example.com'  

```bash
acme.sh --issue --dns dns_cf -d mail.example.com -d mail.example.net
```
the DNS text records will be automatically added for the 2 above domains. From here on, the renewal process must be --renew and not --issue. 
```bash
acme.sh --renew --dns -d mail.example.com -d mail.example.net
```
If you want to test this again and the 60 days hasn't expired. Do this:
```bash
acme.sh --force --renew --dns -d mail.example.com -d mail.example.net
```

At this point we have a directory /home/XXX/.acme.sh/mail.example.com that contains the certificate. You can remove the TXT records from the zone if you manually added them. They are not needed anymore.

# Method 3 (Stateless))
Configure webserver to respond statelessly to challenges for a give account key. This requires a one-time nginx configuration change in zimbra.
###1. Get account key thumbprint:
```bash
acme.sh --register-account
[Thu Apr 17 12:23:09 PDT 2017] Registering account
[Thu Apr 17 12:23:09 PDT 2017] Already registered
[Thu Apr 17 12:23:09 PDT 2017] Update success.
[Thu Apr 17 12:23:09 PDT 2017] ACCOUNT_THUMBPRINT='6fXAG9VyG0IahirPEU2ZerUtItW2DHzDzD9wZaEKpqd'
```
###2. Configure nginx server to return account key thumbprint

Locate the correct location at: /opt/zimbra/conf/nginx/includes
https://wiki.zimbra.com/wiki/Zimbra_Proxy_Guide#Config_Files_and_Config_Templates

http {
...
server {
...
  location ~ "^/\.well-known/acme-challenge/([-_a-zA-Z0-9]+)$" {
    default_type text/plain;
    return 200 "6fXAG9VyG0IahirPEU2ZerUtItW2DHzDzD9wZaEKpqd";
  }
...
}
}

Restart nginx
```bash
su - zimbra
zmnginxctl restart
```

###3. Issue Cert
```bash
acme.sh --issue -d mail.example.com -d mail.example.net
```

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
Normally, It will not update the certificate if its not older than 60 days left before it will expire. If you want to force it to work, change this to something large ...say 1000

- domain=mail.example.com
This is the first -d entry you used when you created your domain with acme.sh. It normally should be the zmhostname. Change this entry to match this directory:
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

If will stop and restart zimbra at the end. You can repeat this as many times as it takes. To automate this, change the min time min=60 and d=0 in the script and run this from cron as the zimbra user. So in the default configuration... It will only install the certificate when the certificate is about to expire in 'min days' or 60 for this example.

This method gives you 1 day to verify your certificates if you are running acme.sh every 59 days but in reality you have already tested this and know it works.  In another example, we will show how to use the renew-hook option of acme.sh

This document is a work in progress... Will show other methods including a central server where you do not have to install .acme.sh on any zimbra server and just the deploy-zimbra-letsencrypt.sh script.

If you have other methods, please share.


