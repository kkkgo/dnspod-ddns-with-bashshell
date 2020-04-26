#Github:https://github.com/kkkgo/dnspod-ddns-with-bashshell
#More: https://03k.org/dnspod-ddns-with-bashshell.html
#CONF START
API_ID=123456789
API_Token=4213d874131gfdg32412138
domain=example.com
host=@
record_type=A
ttl=600
CHECKURL="http://myip.ipip.net"
#OUT="eth0"
#Email=example@qq.com
#CONF END
. /etc/profile
date
if (echo $CHECKURL |grep -q "://");then
IPREX='([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])'
URLIP=$(curl -4 -k $(if [ -n "$OUT" ]; then echo "--interface $OUT"; fi) -s $CHECKURL|grep -Eo "$IPREX"|tail -n1)
if (echo $URLIP |grep -qEvo "$IPREX");then
URLIP="Get $DOMAIN URLIP Failed."
fi
echo "[URL IP]:$URLIP"
dnscmd="nslookup";type nslookup >/dev/null 2>&1||dnscmd="ping -c1"
if [[ -z $host || $host == '@' ]];then
URL=$domain
general=1
else URL=$($host.$domain)
general=0
fi
echo "[URL]:$URL"
DNSTEST=$($dnscmd $URL)
if [ "$?" != 0 ]&&[ "$dnscmd" == "nslookup" ]||(echo $DNSTEST |grep -qEvo "$IPREX");then
DNSIP="Get $URL DNS Failed."
else DNSIP=$(echo $DNSTEST|grep -Eo "$IPREX"|tail -n1)
fi
echo "[DNS IP]:$DNSIP"
if [ "$DNSIP" == "$URLIP" ];then
echo "IP SAME IN DNS,SKIP MODIFY."
exit
fi
fi

if [ $general == 0 ];then
token="login_token=${API_ID},${API_Token}&format=json&domain=${domain}&sub_domain=${host}"
else token="login_token=${API_ID},${API_Token}&format=json&domain=${domain}"
fi
Record="$(curl -4 -k $(if [ -n "$OUT" ]; then echo "--interface $OUT"; fi) -s -X POST https://dnsapi.cn/Record.List -d "${token}")"
iferr="$(echo ${Record#*code}|cut -d'"' -f3)"
if [ "$iferr" == "1" ];then
record_ip=$(echo ${Record#*value}|cut -d'"' -f3)
echo "[API IP]:$record_ip"
if [ "$record_ip" == "$URLIP" ];then
echo "IP SAME IN API,SKIP UPDATE."
exit
fi
record_id=$(echo ${Record#*\"records\"\:\[\{\"id\"}|cut -d'"' -f2)
record_line_id=$(echo ${Record#*line_id}|cut -d'"' -f3)
echo Start DDNS modify...
ddns="$(curl -4 -k $(if [ -n "$OUT" ]; then echo "--interface $OUT"; fi) -s -X POST https://dnsapi.cn/Record.Modify -d "${token}&ttl=${ttl}&record_type=${record_type}&value=${URLIP}&record_id=${record_id}&record_line_id=${record_line_id}")"
ddns_result="$(echo ${ddns#*message\"}|cut -d'"' -f2)"
printf "DDNS upadte result:$ddns_result\n"
now_record_ip=$(echo $ddns|grep -Eo "$IPREX"|tail -n1)
printf "[NOW RECORD IP]:${now_record_ip}\n" 
else echo -n Get $URL error :
echo $(echo ${Record#*message\"})|cut -d'"' -f2
fi
