# Dnspod DDNS with BashShell
# Github:https://github.com/kkkgo/dnspod-ddns-with-bashshell
# Blog: https://blog.03k.org/post/dnspod-ddns-with-bashshell.html
# API DOCS : https://docs.dnspod.cn/api/update-dns-records/  
#CONF START
API_ID=123456
API_Token=abcdefghijklmnopq2333333
# myhome.example.com
domain=example.com
sub_domain=myhome
CHECKURL="http://ipsu.03k.org"
#OUT="pppoe"
#CONF END

# INIT
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/bin:/opt/sbin:$PATH"
date +"%Y-%m-%d %H:%M:%S %Z"
HOST=$sub_domain.$domain
if [ "$sub_domain" = "@" ];then
	HOST=$domain
fi

# DNS IP <-> URL IP
if (echo $CHECKURL |grep -q "://");then
	IPREX='([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])'
	URLIP=$(curl -4ks $(if [ -n "$OUT" ]; then echo "--interface $OUT"; fi) $CHECKURL|grep -Eo "$IPREX"|tail -n1)
	if echo $URLIP|grep -qEvo "$IPREX";then
		URLIP="Get $HOST URLIP Failed.["$CHECKURL"]"
	fi
	echo "[URL IP]:$URLIP"
	DNSIP="Get $HOST DNS Failed."
	DNSTEST=$(ping -4 -c1 -W1 $HOST 2>&1|grep -Eo "$IPREX"|head -1)
	if echo $DNSTEST|grep -Eqo "$IPREX";then
		DNSIP=$DNSTEST
		else
			DNSTEST=$(nslookup $HOST 2>&1|grep -Eo "$IPREX"|tail -1)
			if echo $DNSTEST|grep -Eqo "$IPREX";then
			DNSIP=$DNSTEST
			else
				DNSTEST=$(curl -4kvs $HOST -m 1 2>&1|grep -Eo "$IPREX"|head -1)
				if echo $DNSTEST|grep -Eqo "$IPREX";then
				DNSIP=$DNSTEST
				else
					DNSTEST=$(wget --spider -T1 -t1 $HOST 2>&1|grep -Eo "$IPREX"|head -1)
					if echo $DNSTEST|grep -Eqo "$IPREX";then
					DNSIP=$DNSTEST
					fi
				fi
			fi
	fi
	echo "[DNS IP]:$DNSIP"
	if [ "$DNSIP" = "$URLIP" ];then
	echo "IP SAME IN DNS,SKIP UPDATE."
	exit
	fi
fi

# API IP
login_token=${API_ID},${API_Token}
token="login_token=${login_token}&format=json&lang=en&error_on_empty=yes&domain=${domain}&sub_domain=${sub_domain}"
Record="$(curl -4ks $(if [ -n "$OUT" ]; then echo "--interface $OUT"; fi) -X POST https://dnsapi.cn/Record.List -d "${token}")"
if echo $Record|grep -qEo "Operation successful";then
	record_ip=$(echo $Record|grep -Eo "$IPREX"|head -1)
	echo "[API IP]:$record_ip"

	if [ "$record_ip" = "$URLIP" ];then
	echo "IP SAME IN API,SKIP UPDATE."
	exit
	fi
	
# DDNS UPDATE
	record_id=$(echo $Record|grep -Eo '"records"[:\[{" ]+"id"[:" ]+[0-9]+'|grep -Eo [0-9]+|head -1)
	record_line_id=$(echo $Record|grep -Eo 'line_id[": ]+[0-9]+'|grep -Eo [0-9]+|head -1)
	echo Start DDNS update...
	ddns="$(curl -4ks $(if [ -n "$OUT" ]; then echo "--interface $OUT"; fi) -X POST https://dnsapi.cn/Record.Ddns -d "${token}&record_id=${record_id}&record_line_id=${record_line_id}")"
	ddns_result=$(echo $ddns|grep -Eo 'message[": ]+[A-Za-z0-9. -]+"'|grep -Eo '"[A-Za-z0-9. -]+"')
	result="DDNS "$ddns_result" - "$HOST"["$record_ip"]->["$(echo $ddns|grep -Eo "$IPREX"|tail -n1)"]"
else
    ddns_result=$(echo $Record|grep -Eo 'message[": ]+[A-Za-z0-9. -]+"'|grep -Eo '"[A-Za-z0-9. -]+"')	
	result="Get "$HOST" error :"$ddns_result
fi
echo $result
