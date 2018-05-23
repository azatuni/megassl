#!/bin/bash
#Megassl v1.1
#Date: 23.05.2018
#Author: https://github.com/azatuni/
#Purpose: Bash script for manipulating with ssl certificates and private keys. 

function colour_variables () {
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
}

function megassl_banner () {
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
"
}


function check_cert_key () {
if [ "`openssl rsa -noout -modulus -in $PWD'/'$1 | openssl md5`" ==  "`openssl x509 -noout -modulus -in $PWD'/'$2 | openssl md5`" ]
	then	echo -e "$1 and $2 match status:\t${GREEN}${BOLD}[ OK ]${NORMAL}"
	else	echo -e "$1 and $2 match status:\t${RED}${BOLD}[ FAILED ]${NORMAL}" && exit 1
fi
}

function pemgen () {
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

function checkcertfiledate () {
echo -e "$1 is valid till:\t`openssl x509 -enddate -noout -in $PWD"/"$1 | awk -F= '{print $2}'`"
}

function checkservercertdate () {
echo -e "$1 is valid till:\t`echo | openssl s_client -connect $1:443 2> /dev/null| openssl x509 -noout -dates| tail -n1`"
}


function csrkeygen () {
CSRKEYDIR="$PWD"/"$1"
        if [ -d $CSRKEYDIR ]
		then	echo -e "Creating $CSRKEYDIR directory:\t\t${RED}${BOLD}[ FAILED ]${NORMAL}" && echo -e "${RED}${BOLD}ERROR! Directory exists!${NORMAL}" && exit 1
                else    mkdir $CSRKEYDIR && cd $CSRKEYDIR && echo -e "Creating $CSRKEYDIR directory:\t\t${GREEN}${BOLD}[ OK ]${NORMAL}"
                        openssl genrsa -out $1.key 2048
                        openssl req -new -sha256 -key $1.key -out $1.csr
			echo -e "Certificate Signing Request(CSR) file is:\t\t${GREEN}${BOLD}$CSRKEYDIR/$1.csr${NORMAL}"
			echo -e "Private key file is:\t\t\t${GREEN}${BOLD}$CSRKEYDIR/$1.key${NORMAL}"
        fi
}

function decode_csr () {
openssl req -in $1 -noout -text
}

function megassl_usage () 
{
echo -e "${BOLD}Usage:${NORMAL} $0 --key argument|arguments
KEYS:${NORMAL}
\t${BOLD}--checkcertkey\tprivate_key_file ssl_certificate_file${NORMAL}
\t\t\tCheck SSL certificate and private key matching
\t${BOLD}--pemgen private_key_file ssl_certificate_file [intermediary_certificate_file|files(until 5)]${NORMAL}
\t\t\tGenerate pem file
\t${BOLD}--checkcertfiledate ssl_certificate_file${NORMAL}
\t\t\tCheck SSL certificate experation date
\t${BOLD}--checkservercertdate domain|subdomain${NORMAL}
\t\t\tCheck SSL certificate on remote server
\t${BOLD}--csrkeygen FQDN${NORMAL}
\t\t\tCreate folder with FQDN name and generate CSR and certificate inside of it
\t${BOLD}--decodecsr csr_file${NORMAL}
\t\t\tDecodes existing CSR file
"
}

colour_variables
megassl_banner

if [ "$1" != "--help" ]
	then	if [ $# -lt 2 ]
			then echo -e "${RED}${BOLD}Need mininum one key and argument, for more info run: $0 --help${NORMAL}" && exit 2 
	fi
fi

case "$1" in
        "--checkcertkey")
                check_cert_key $2 $3
                ;;
        "--checkcertfiledate")
                checkcertfiledate $2
                ;;
	"--checkservercertdate")
		checkservercertdate $2
		;;
        "--pemgen")
                check_cert_key $2 $3 && checkcertfiledate $3 && pemgen $2 $3 $4 $5 $6
                ;;
        "--csrkeygen")
                csrkeygen $2
                ;;
	"--decodecsr")
		decode_csr $2
		;;
        *)
                megassl_usage && exit
                ;;
esac

