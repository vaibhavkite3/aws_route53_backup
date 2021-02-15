#!/bin/bash
# _   _       _ _     _                 _   __
#| | | |     (_) |   | |               | | / /
#| | | | __ _ _| |__ | |__   __ ___   _| |/ / 
#| | | |/ _` | | '_ \| '_ \ / _` \ \ / /    \ 
#\ \_/ / (_| | | |_) | | | | (_| |\ V /| |\  \
# \___/ \__,_|_|_.__/|_| |_|\__,_| \_/ \_| \_/
######################################################
# Script to take backup of AWS route53 (MultiProfile)#
# backup on disk and mail the backup status          #
######################################################
# REQUIREMENTS:
# cli53 binary is required - instruction & download avaible on link below
# https://github.com/barnybug/cli53
##############################################
# ~/.aws/credentials
# Profile Name (Credentials to Use for authentication)
CREDENTIAL_PROFILE_NAME="AWS01"
##############################################
# Update backup location as per requirement here
BACKUP_LOCATION="/root/DNS_BACKUP/AWS_ROUTE_53"
##############################################
# Update recepeint mail address here
MAIL_TO="contact@mail.com"
##############################################
BACKUP_DATE=`date +%F`
# Take backup
echo "Creating directory $BACKUP_LOCATION/$CREDENTIAL_PROFILE_NAME/$BACKUP_DATE"
mkdir -p $BACKUP_LOCATION/$CREDENTIAL_PROFILE_NAME/$BACKUP_DATE

cli53 list --profile $CREDENTIAL_PROFILE_NAME | awk '{print $2}' | grep -v 'Name' | 
while read line; 
do
cli53 export --profile $CREDENTIAL_PROFILE_NAME ${line} >> $BACKUP_LOCATION/$CREDENTIAL_PROFILE_NAME/$BACKUP_DATE/${line}bk;
done

ACTUAL_COUNT=`cli53 list --profile $CREDENTIAL_PROFILE_NAME | wc -l`
BACKUP_COUNT=`ls -l $BACKUP_LOCATION/$CREDENTIAL_PROFILE_NAME/$BACKUP_DATE | wc -l`

if [ $ACTUAL_COUNT -eq $BACKUP_COUNT ]; then
# Mail the report
> /tmp/aws_dns_backup
echo "<html><body><h3>AWS R53 DNS BACKUP COMPLETED for $CREDENTIAL_PROFILE_NAME ON $BACKUP_DATE @ LOCATION $BACKUP_LOCATION/$CREDENTIAL_PROFILE_NAME/$BACKUP_DATE</h3><table border='1'><tr><th>&nbsp;&nbsp;Domain Name&nbsp;&nbsp;</th><th>&nbsp;&nbsp;Record Count&nbsp;&nbsp;</th></tr>" >> /tmp/aws_dns_backup

cli53 list --profile $CREDENTIAL_PROFILE_NAME | awk '{print $2 " " $3}' | grep -v 'Name' | 
while read line; 
do
	echo "${line}" | awk '{print "<tr><td>&nbsp;&nbsp;" $1 "&nbsp;&nbsp;</td><td>&nbsp;&nbsp;" $2 "&nbsp;&nbsp;</td></tr>"}' >> /tmp/aws_dns_backup
done
echo "</table></body></html>" >> /tmp/aws_dns_backup

cat /tmp/aws_dns_backup | mail -a "Content-type: text/html;" -s "AWS R53 DNS BACKUP" $MAIL_TO

else 
 
echo "
AWS R53 DNS BACKUP FAILED for $CREDENTIAL_PROFILE_NAME ON $BACKUP_DATE, Please check.
" | mail -a "Content-type: text/html;" -s "AWS R53 DNS BACKUP" $MAIL_TO

fi

exit 0