# deploy-zimbra-letsencrypt

# PURPOSE
Simple method to install letsencrypt certificates with Zimbra 8.7+ without installing excessive external packages and software. Keep it simple, flexible, and allow to choose best method for certs.

# OPERATION
Letsencrypt is an automated and real-time method to create a Certificate but does require a challenge/verification to establish who you say you are. There are various modes to accomplish which generally require that you have a program listein at port 80/443 on the machine you want the cert for. This isn't appropraite sometimes, and we document the DNS method below. See: https://github.com/Neilpang/acme.sh for a full list of supported modes.

# Lessons Learned
Goals from 8 months of deployement with zimbra and letsencrypt and a topic at:
http://forums.zimbra.org/viewtopic.php?f=15&t=60781&sid=2a91c5a8f518e7b9d8147b8f26495023
1) Stay out of /opt/zimbra 
2) run as user zimbra for stuff it needs
3) run as normal user for letsencrypt stuff
4) minimize my hooks to a single cron as zimbra
5) not run as root
6) minimize downtime due to zimbra restart
7) decouple letsencrypt with automated script
8) support multi-domain, multi-architecture zimbra installs
9) support various methods of challege/response for letsencrypt certs
10) Keep it simple

