#ПРОВЕРЯЕТ СЕРТИКИ ПО ХОСТНЕЙМУ ДЛЯ СЕРВЕРОВ (опенссл на айпи адрес) Не достает сертификаты с 127.0.0.1 
#!/bin/bash
ip2=`awk '/32 host/ { print f } {f=$2}' <<< "$(</proc/net/fib_trie)" | sort -u | grep -v '127.0.0.1' | head -n 1`

n=0
for x in `netstat -ntlp | awk '{print $4}' | grep -Po ':[0-9][0-9]*'|tr -d \:`;do
    ports[n]=$x
    n=$((n+1)); done

n2=0
for x in `awk '/32 host/ { print f } {f=$2}' <<< "$(</proc/net/fib_trie)" | sort -u | grep -v '127.0.0.1'`;do 
    dnsname[n2]=`host $x | awk '{print $5}'|sed 's/.$//'`
    n2=$((n2+1)); done

result='['

for x in ${ports[@]}; do
    for x2 in ${dnsname[@]}; do
        bash -c '( cmdpid=$BASHPID; (sleep 1; kill $cmdpid &> /dev/null  ) &  exec  echo | openssl s_client -servername '$x2' -connect '$ip2:$x' 2>/dev/null | openssl x509 -noout -dates| grep notAfter | cut -d'=' -f2  > /dev/null 2>&1)' 2> /dev/null    
        if [ $? -eq 0 ];
            then
                if echo | openssl s_client -servername $x2 -connect $ip2:$x 2>/dev/null | openssl x509 -noout -dates > /dev/null 2>&1;
                    then
                        x22=`echo | openssl s_client -servername $x2 -connect $ip2:$x 2>/dev/null | openssl x509 -noout -dates | grep notAfter | cut -d'=' -f2`
                        x3=`date -d "${x22}" +%s`
                        x4=$(( ${x3} - `date +%s` ))
                        x5=$(( ${x4} / 24 / 3600 ))
                        result=$result"{"\"ip\":\"$ip2\"", \"dns"\":\"$x2\"", \"port"\":\"$x\"", \"expire_days"\":\""$x5\"""}",
                fi
        fi; done

done
 
result=${​result%,}​"]​"
echo $result
