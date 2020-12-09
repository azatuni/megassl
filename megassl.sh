#!/bin/bash
# Megassl v1.1.1
# Date: 2020.12.09
# Author: https://github.com/azatuni/
# Purpose: Bash script for manipulating with ssl certificates and private keys. 

function colour-variables () {
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
CYAN='\e[1;96m'
BLINK='\e[1;5m'
DARKGREY='\e[1;90m'
DIM='\e[1;2m'
OK_STATUS="\t${GREEN}${BOLD}[ OK ]${NORMAL}"
FAILED_STATUS="\t${RED}${BOLD}[ FAILED ]${NORMAL}"
}

function check-cert-key () {
if [ "`openssl rsa -noout -modulus -in $PWD'/'$1 | openssl md5`" ==  "`openssl x509 -noout -modulus -in $PWD'/'$2 | openssl md5`" ]
	then	echo -e "$1 and $2 match status:$OK_STATUS"
	else	echo -e "$1 and $2 match status:$FAILED_STATUS" && exit 1
fi
}

function pem-gen () {
        CON=`openssl x509 -noout -subject -in $PWD'/'$2 | grep -o CN=.*| sed s/CN=//`
        COMMONNAME=`echo "$CON" | sed s/'*.'//`
	PEMFILENAME="$COMMONNAME"."pem"
	openssl rsa -in $PWD"/"$1 -text > "$PEMFILENAME"
        openssl x509 -in $PWD"/"$2  -out $COMMONNAME"."pem.crt -outform PEM
        cat $COMMONNAME"."pem.crt >> "$PEMFILENAME" && rm -f $COMMONNAME"."pem.crt
        test -f $PWD"/"$3 && cat $PWD"/"$3 >> "$PEMFILENAME"
        test -f $PWD"/"$4 && cat $PWD"/"$4 >> "$PEMFILENAME"
        test -f $PWD"/"$5 && cat $PWD"/"$5 >> "$PEMFILENAME"
        echo -e "Certificate CN is:\t$CON"
        echo -e "Generated PEM file:\t${BOLD}$COMMONNAME"."pem${NORMAL}"
}

function check-cert-file-date () {
echo -e "$1 is valid till:\t`openssl x509 -enddate -noout -in $PWD"/"$1 | awk -F= '{print $2}'`"
}

function check-server-cert-date () {
echo -e "$1 is valid till:\t`echo | openssl s_client -connect $1:443 2> /dev/null| openssl x509 -noout -dates| tail -n1`"
}


function csr-key-gen () {
CSRKEYDIR="$PWD"/"$1"
        if [ -d $CSRKEYDIR ]
		then	echo -e "Creating $CSRKEYDIR directory:$FAILED_STATUS" && echo -e "${RED}${BOLD}ERROR! Directory exists!${NORMAL}" && exit 1
                else    mkdir $CSRKEYDIR && cd $CSRKEYDIR && echo -e "Creating $CSRKEYDIR directory:$OK_STATUS"
                        openssl genrsa -out $1.key 2048
                        openssl req -new -sha256 -key $1.key -out $1.csr
			echo -e "Certificate Signing Request(CSR) file is:\t\t${GREEN}${BOLD}$CSRKEYDIR/$1.csr${NORMAL}"
			echo -e "Private key file is:\t\t\t${GREEN}${BOLD}$CSRKEYDIR/$1.key${NORMAL}"
        fi
}

function decode-csr () {
openssl req -in $1 -noout -text
}

function extract-from-pfx () {
openssl pkcs12 -in $PFX_FILE -nocerts -out pfx-extract-tmp.key
openssl pkcs12 -in $PFX_FILE -clcerts -nokeys -out pfx-extract-tmp.crt
COMMON_NAME=`openssl x509 -noout -subject -in pfx-extract-tmp.crt | cut -d'/' -f6| sed 's/CN=//'` && echo -e "$PFX_FILE file common name: $COMMON_NAME"
mv pfx-extract-tmp.crt $COMMON_NAME.crt && echo -e "Extracted $COMMON_NAME.crt certificate from $PFX_FILE$OK_STATUS"
openssl rsa -in pfx-extract-tmp.key -out $COMMON_NAME.key && echo -e "Extracted $COMMON_NAME.key private key from $PFX_FILE$OK_STATUS"
rm -f pfx-extract-tmp.key
}

function megassl-usage () 
{
echo -e "${BOLD}${CYAN}
\t                                         __
\t   ____ ___  ___  ____ _____ ___________/ /
\t  / __ \`__ \/ _ \/ __ \`/ __ \`/ ___/ ___/ /
\t / / / / / /  __/ /_/ / /_/ (__  (__  / /
\t/_/ /_/ /_/\___/\__, /\__,_/____/____/_/
\t               /____/
${BLUE}_____________________________________________________________
\t\t${NORMAL}${DARKGREY}${DIM}https://github.com/azatuni/
${BLUE}=============================================================${NORMAL}
${BOLD}Usage:${NORMAL} $0 --key argument|arguments
KEYS:${NORMAL}
    ${BOLD}--check-cert-key private_key_file ssl_certificate_file${NORMAL}
\tCheck SSL certificate and private key matching
    ${BOLD}--pem-gen private_key_file ssl_certificate_file [intermediary_certificate_file|files(until 5)]${NORMAL}
\tGenerate pem file
    ${BOLD}--check-cert-file-date ssl_certificate_file${NORMAL}
\tCheck SSL certificate experation date
    ${BOLD}--check-server-cert-date domain|subdomain${NORMAL}
\tCheck SSL certificate on remote server
    ${BOLD}--csr-key-gen FQDN${NORMAL}
\tCreate folder with FQDN name and generate CSR and certificate inside of it
    ${BOLD}--decode-csr csr_file${NORMAL}
\tDecodes existing CSR file
    ${BOLD}--extract-pfx pfx_file${NORMAL}
\tExtrcat certificate and private key from pfx file
"
}

colour-variables

if [ "$1" != "--help" ]
	then	if [ $# -lt 2 ]
			then echo -e "${RED}${BOLD}Need mininum one key and argument, for more info run: $0 --help${NORMAL}" && exit 2 
	fi
fi

case "$1" in
        "--check-cert-key")
                check-cert-key $2 $3
                ;;
        "--check-cert-file-date")
                check-cert-file-date $2
                ;;
	"--check-server-cert-date")
		check-server-cert-date $2
		;;
        "--pem-gen")
                check-cert-key $2 $3 && check-cert-file-date $3 && pem-gen $2 $3 $4 $5 $6
                ;;
        "--csr-key-gen")
                csr-key-gen $2
                ;;
	"--decode-csr")
		decode-csr $2
		;;
	"--extract-pfx")
		PFX_FILE=$2
		extract-from-pfx
		;;
        *)
                megassl-usage && exit
                ;;
esac

