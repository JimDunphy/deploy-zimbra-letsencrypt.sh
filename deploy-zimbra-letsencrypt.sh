#!/bin/bash

# Author: Jim Dunphy <jad@aesir.com>
# License (ISC): It's yours. Enjoy
# Date: 10/9/2016
#   updated: 2/7/2017 - decoupled cert renewal and comments

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
#     we will be getting new certs.
min=159	#when you want to restart zimbra - make large to force ie. 159 for testing
domain="mail.example.com"
user="/home/jdunphy" # ~user/.acme.sh --- owner that runs acme.sh
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
	echo $1
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
/bin/cp -rf $user/.acme.sh .
if [ $? == 1 ]; then
   say "Check permissions: CERT cp failed for $user/.acme.sh"
fi

# Step 2 - backup (comment out later)
cd $zimbra_certs
tar cvf zimbra.tar.$(date "+%Y%m%d") zimbra

# Step 3 - verify cert
cd "$certs"
# from: https://www.identrust.com/certificates/trustid/root-download-x3.html
# append IdentTrust CA 
cat << EOF >> fullchain.cer
-----BEGIN CERTIFICATE-----
MIIDSjCCAjKgAwIBAgIQRK+wgNajJ7qJMDmGLvhAazANBgkqhkiG9w0BAQUFADA/
MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT
DkRTVCBSb290IENBIFgzMB4XDTAwMDkzMDIxMTIxOVoXDTIxMDkzMDE0MDExNVow
PzEkMCIGA1UEChMbRGlnaXRhbCBTaWduYXR1cmUgVHJ1c3QgQ28uMRcwFQYDVQQD
Ew5EU1QgUm9vdCBDQSBYMzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
AN+v6ZdQCINXtMxiZfaQguzH0yxrMMpb7NnDfcdAwRgUi+DoM3ZJKuM/IUmTrE4O
rz5Iy2Xu/NMhD2XSKtkyj4zl93ewEnu1lcCJo6m67XMuegwGMoOifooUMM0RoOEq
OLl5CjH9UL2AZd+3UWODyOKIYepLYYHsUmu5ouJLGiifSKOeDNoJjj4XLh7dIN9b
xiqKqy69cK3FCxolkHRyxXtqqzTWMIn/5WgTe1QLyNau7Fqckh49ZLOMxt+/yUFw
7BZy1SbsOFU5Q9D8/RhcQPGX69Wam40dutolucbY38EVAjqr2m7xPi71XAicPNaD
aeQQmxkqtilX4+U9m5/wAl0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNV
HQ8BAf8EBAMCAQYwHQYDVR0OBBYEFMSnsaR7LHH62+FLkHX/xBVghYkQMA0GCSqG
SIb3DQEBBQUAA4IBAQCjGiybFwBcqR7uKGY3Or+Dxz9LwwmglSBd49lZRNI+DT69
ikugdB/OEIKcdBodfpga3csTS7MgROSR6cz8faXbauX+5v3gTt23ADq1cEmv8uXr
AvHRAosZy5Q6XkjEGB5YGV8eAlrwDPGxrancWYaLbumR9YbK+rlmM6pZW87ipxZz
R8srzJmwN0jP41ZL9c8PDHIyh8bwRLtTcm1D9SZImlJnt1ir/md2cXjbDaJWFBM5
JDGFoqgCWjBH4d1QB7wCCZAA62RjYJsWvIjJEubSfZGL+T0yjWW06XyxV3bqxbYo
Ob8VZRzI9neWagqNdwvYkQsEjgfbKbYK7p2CNTUQ
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
