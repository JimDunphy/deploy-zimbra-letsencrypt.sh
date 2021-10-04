#!/bin/bash

# Author: Jim Dunphy <jad aesir.com>
# License (ISC): It's yours. Enjoy
# Date: 10/9/2016
#   updated: 2/7/2017 - decoupled cert renewal and added more comments
#   updated: 10/3/2021 - decoupled cert renewal and added more comments

#
# Run as zimbra (only for Zimbra 8.7+)
#
#   Assumes that acme.sh has been installed and has been run 
#
#   https://github.com/Neilpang/acme.sh or see README.acme
#
#   General Zimbra steps for generating certificate and directory structure.
#   Choose method best for installation. I use the dns method which can
#      be done on a different machine. Lots of examples and methods in link above.
#
#   This script doesn't generate the certs. Here are my steps:
#       as another non zimbra user:
#       % git clone https://github.com/Neilpang/acme.sh
#       % cd acme.sh
#       % ./acme.sh --install
#       % chmod 755 .acme.sh   #to faciliate cp later by zimbra user
#       % su - zimbra
#       % zmhostname
#       % exit
#       % acme.sh --issue --dns -d mail.example.net -d mail.example.org -d ...
#       Add txt records to zone from command above
#       % acme.sh --renew -d mail.example.net -d mail.example.org -d ...
#       You now have certificates that can be used by zimbra. Run script below
#
#   Steps:
#      PreInstallation: install acme.sh and generate cert for non-zimbra user.
#      Installation: Put this script in /opt/letsencrypt
#                    chown -R zimbra:zimbra /opt/letsencrypt
#                    cp -r ~user/.acme.sh /opt/letsencrypt/
#                    # watch for permission errors above
#      Renewal: Decide how you want to repeat step above. Can be scp/cp or
#       see extra script I use via cron.
#
# Note: you can install acme.sh as the zimbra user but be aware of upgrades/installation/etc that
#       may remove any work you have done.

# NOTE (4 items to configure):
# %%% This needs to below the current threashold for challenge/validation
#     It is currently set for 60 days from letsencrypt to match when
#     we will be getting new certs. This is the days to the CERT will expire.
min=60 #make larger to make zimbra load a new CERT
domain="mail.example.com"
user="/home/YourName" # ~user/.acme.sh --- owner that runs acme.sh
# verbose output
d=1  # change to 0 if run from cron
exit # comment this out after adjusting the top two values

# This is the result of running acme.sh and your letsencrypt certs
# As zimbra: cp -r ~user/.acme.sh /opt/letsencrypt/
# This validates permissions for zimbra later.
certs=/opt/letsencrypt/.acme.sh/$domain/ 

# Where zimbra stores certs
zimbra_certs=/opt/zimbra/ssl

debug() {
  if [ $d == 1 ]; then
	echo "$1 - Hit Enter to Continue"
	read var
  fi
} 

say() {
  if [ $d == 1 ]; then
     echo "$1"
  fi
}

#Step 0 - verify if its time
/opt/zimbra/bin/zmcertmgr checkcrtexpiration -days $min > /dev/null
if [ $? == 0 ]; then
    say "not time yet to renew"
    exit 0
fi

#
# Step 1 (Decoupled... run this separately now)
#
#debug "Renew certs:"
#.acme.sh/acme.sh --force --cron --home /home/user/.acme.sh | grep "END CERTIFICATE"
# return 1 if didn't generate a new certificate
#if [ $? == 1 ]; then
#   echo Did not renew  # shouldn't happen
#   exit 1
#fi
#
/bin/cp -rf $user/.acme.sh/$domain $certs
if [ $? == 1 ]; then
   say "Check permissions: CERT cp failed for $user/.acme.sh"
fi

# Step 2 - backup (comment out later)
cd $zimbra_certs
tar cvf zimbra.tar.$(date "+%Y%m%d") zimbra

# Step 3 - verify cert
cd "$certs"
# from: wget -q "https://letsencrypt.org/certs/isrgrootx1.pem.txt" -O
cat << EOF >> fullchain.cer
-----BEGIN CERTIFICATE-----
MIIFazCCA1OgAwIBAgIRAIIQz7DSQONZRGPgu2OCiwAwDQYJKoZIhvcNAQELBQAw
TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMTUwNjA0MTEwNDM4
WhcNMzUwNjA0MTEwNDM4WjBPMQswCQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJu
ZXQgU2VjdXJpdHkgUmVzZWFyY2ggR3JvdXAxFTATBgNVBAMTDElTUkcgUm9vdCBY
MTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAK3oJHP0FDfzm54rVygc
h77ct984kIxuPOZXoHj3dcKi/vVqbvYATyjb3miGbESTtrFj/RQSa78f0uoxmyF+
0TM8ukj13Xnfs7j/EvEhmkvBioZxaUpmZmyPfjxwv60pIgbz5MDmgK7iS4+3mX6U
A5/TR5d8mUgjU+g4rk8Kb4Mu0UlXjIB0ttov0DiNewNwIRt18jA8+o+u3dpjq+sW
T8KOEUt+zwvo/7V3LvSye0rgTBIlDHCNAymg4VMk7BPZ7hm/ELNKjD+Jo2FR3qyH
B5T0Y3HsLuJvW5iB4YlcNHlsdu87kGJ55tukmi8mxdAQ4Q7e2RCOFvu396j3x+UC
B5iPNgiV5+I3lg02dZ77DnKxHZu8A/lJBdiB3QW0KtZB6awBdpUKD9jf1b0SHzUv
KBds0pjBqAlkd25HN7rOrFleaJ1/ctaJxQZBKT5ZPt0m9STJEadao0xAH0ahmbWn
OlFuhjuefXKnEgV4We0+UXgVCwOPjdAvBbI+e0ocS3MFEvzG6uBQE3xDk3SzynTn
jh8BCNAw1FtxNrQHusEwMFxIt4I7mKZ9YIqioymCzLq9gwQbooMDQaHWBfEbwrbw
qHyGO0aoSCqI3Haadr8faqU9GY/rOPNk3sgrDQoo//fb4hVC1CLQJ13hef4Y53CI
rU7m2Ys6xt0nUW7/vGT1M0NPAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNV
HRMBAf8EBTADAQH/MB0GA1UdDgQWBBR5tFnme7bl5AFzgAiIyBpY9umbbjANBgkq
hkiG9w0BAQsFAAOCAgEAVR9YqbyyqFDQDLHYGmkgJykIrGF1XIpu+ILlaS/V9lZL
ubhzEFnTIZd+50xx+7LSYK05qAvqFyFWhfFQDlnrzuBZ6brJFe+GnY+EgPbk6ZGQ
3BebYhtF8GaV0nxvwuo77x/Py9auJ/GpsMiu/X1+mvoiBOv/2X/qkSsisRcOj/KK
NFtY2PwByVS5uCbMiogziUwthDyC3+6WVwW6LLv3xLfHTjuCvjHIInNzktHCgKQ5
ORAzI4JMPJ+GslWYHb4phowim57iaztXOoJwTdwJx4nLCgdNbOhdjsnvzqvHu7Ur
TkXWStAmzOVyyghqpZXjFaH3pO3JLF+l+/+sKAIuvtd7u+Nxe5AW0wdeRlN8NwdC
jNPElpzVmbUq4JUagEiuTDkHzsxHpFKVK7q4+63SM1N95R1NbdWhscdCb+ZAJzVc
oyi3B43njTOQ5yOf+1CceWxG1bQVs5ZufpsMljq4Ui0/1lvh+wjChP4kqKOJ2qxq
4RgqsahDYVvTH9w7jXbyLeiNdd8XM2w9U/t7y0Ff/9yi0GE44Za4rF2LN9d11TPA
mRGunUHBcnWEvgJBQl9nJEiU0Zsnvgc/ubhPgXRR4Xq37Z0j4r7g1SgEEzwxA57d
emyPxgcYxn/eR44/KJ4EBs+lVDR3veyJm+kXQ99b21/+jh5Xos1AnX5iItreGCc=
-----END CERTIFICATE-----
EOF
/opt/zimbra/bin/zmcertmgr verifycrt comm $domain.key $domain.cer fullchain.cer
if [ $? == 1 ]; then
   say "cert did not verify"
   exit 1
fi

# Step 4 - Deploy to Zimbra
debug "Observe ... did it verify"
cd $certs
cp $domain.key /opt/zimbra/ssl/zimbra/commercial/commercial.key
if [ $? == 1 ]; then
   say "Cert permission problem - commercial.key"
   exit 1
fi

debug "About to Deploy: Watch for permission problem"
# as zimbra
cd $certs
/opt/zimbra/bin/zmcertmgr deploycrt comm $domain.cer fullchain.cer

debug "If no errors than proceed to restart zimbra"
zmcontrol restart
