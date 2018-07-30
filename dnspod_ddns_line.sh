#Dnspod DDNS with BashShell
#Github:https://github.com/lixuy/dnspod-ddns-with-bashshell
#More: https://03k.org/dnspod-ddns-with-bashshell.html
#CONF START
API_ID=12345
API_Token=abcdefghijklmnopq2333333
domain=example.com
host=home
Email=yourmail@example.com
#OUT="pppoe"
DEV="eth0"
#CONF END

date
IPREX='([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])'
ipcmd="ip addr show";type ip >/dev/null 2>&1||ipcmd="ifconfig"
DEVIP=$($ipcmd $DEV|grep -Eo "$IPREX"|head -n1)
echo "[DEV IP]:$DEVIP"
dnscmd="nslookup";type nslookup >/dev/null 2>&1||dnscmd="ping -c1"
DNSTEST=$($dnscmd $host.$domain)
if [ "$?" == 0 ];then
DNSIP=$(echo $DNSTEST|grep -Eo "$IPREX"|tail -n1)
else DNSIP="Get $host.$domain DNS Failed."
fi
echo "[DNS IP]:$DNSIP"
if [ "$DNSIP" == "$DEVIP" ];then
echo "IP SAME IN DNS,SKIP UPDATE."
exit
fi
token="login_token=${API_ID},${API_Token}&format=json&lang=en&error_on_empty=yes&domain=${domain}&sub_domain=${host}"
UA="User-Agent: 03K DDNS Client/1.0.0 ($Email)"
Record="$(curl $(if [ -n "$OUT" ]; then echo "--interface $OUT"; fi) -s -X POST https://dnsapi.cn/Record.List -d "${token}" -H "${UA}")"
iferr="$(echo ${Record#*code}|cut -d'"' -f3)"
if [ "$iferr" == "1" ];then
record_ip=$(echo ${Record#*value}|cut -d'"' -f3)
echo "[API IP]:$record_ip"
if [ "$record_ip" == "$DEVIP" ];then
echo "IP SAME IN API,SKIP UPDATE."
exit
fi
record_id=$(echo ${Record#*\"records\"\:\[\{\"id\"}|cut -d'"' -f2)
record_line_id=$(echo ${Record#*line_id}|cut -d'"' -f3)
echo Start DDNS update...
ddns="$(curl $(if [ -n "$OUT" ]; then echo "--interface $OUT"; fi) -s -X POST https://dnsapi.cn/Record.Ddns -d "${token}&record_id=${record_id}&record_line_id=${record_line_id}&value=$DEVIP" -H "${UA}")"
ddns_result="$(echo ${ddns#*message\"}|cut -d'"' -f2)"
echo -n "DDNS upadte result:$ddns_result "
echo $ddns|grep -Eo "$IPREX"|tail -n1
else echo -n Get $host.$domain error :
echo $(echo ${Record#*message\"})|cut -d'"' -f2
fi
