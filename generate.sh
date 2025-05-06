Инструкция:
1) Создать public репозиторий на github.com
2) Добавить файл generate.sh с кодом (Код ниже)
3) Скопировать RAW ссылку на generate.sh
4) bash <(wget -qO- ССЫЛКАизТРЕТЬЕГОпункта)
5) Открыть и вставить эту команду в debian (https://terminator.aeza.net/en/)
6) Скопировать конфиг и добавить в hiddify

Код для generate.sh:

#!/bin/bash

clear
echo "Установка зависимостей..."
apt update -y && apt install sudo -y # Для Aeza Terminator, там sudo не установлен по умолчанию
sudo apt-get update -y --fix-missing && sudo apt-get install wireguard-tools jq wget qrencode -y --fix-missing # Update второй раз, если sudo установлен и обязателен (в строке выше не сработал)

priv="${1:-$(wg genkey)}"
pub="${2:-$(echo "${priv}" | wg pubkey)}"
api="https://api.cloudflareclient.com/v0i1909051800"
ins() { curl -s -H 'user-agent:' -H 'content-type: application/json' -X "$1" "${api}/$2" "${@:3}"; }
sec() { ins "$1" "$2" -H "authorization: Bearer $3" "${@:4}"; }
response=$(ins POST "reg" -d "{\"install_id\":\"\",\"tos\":\"$(date -u +%FT%T.000Z)\",\"key\":\"${pub}\",\"fcm_token\":\"\",\"type\":\"ios\",\"locale\":\"en_US\"}")

id=$(echo "$response" | jq -r '.result.id')
token=$(echo "$response" | jq -r '.result.token')
response=$(sec PATCH "reg/${id}" "$token" -d '{"warp_enabled":true}')
peer_pub=$(echo "$response" | jq -r '.result.config.peers[0].public_key')
#peer_endpoint=$(echo "$response" | jq -r '.result.config.peers[0].endpoint.host')
client_ipv4=$(echo "$response" | jq -r '.result.config.interface.addresses.v4')
client_ipv6=$(echo "$response" | jq -r '.result.config.interface.addresses.v6')
reserved64=$(echo "$response" | jq -r '.result.config.client_id')
reservedHex=$(echo "$reserved64" | base64 -d | hexdump -v -e '/1 "%02x\n"')
reservedDec=$(printf '%s\n' "${reservedHex}" | while read -r hex; do printf "%d, " "0x${hex}"; done)
reservedDec="[${reservedDec%, }]"
reservedHex=$(echo "${reservedHex}" | awk 'BEGIN { ORS=""; print "0x" } { print }')

json_conf=$(cat <<-EOM
{
  "outbounds":   [
    {
      "type": "wireguard",
      "tag": "WARP",
      "reserved": ${reservedDec},
      "local_address":       [
        "${client_ipv4}/32",
        "${client_ipv6}/128"
      ],
      "private_key": "${priv}",
      "server": "engage.cloudflareclient.com",
      "server_port": 500,
      "peer_public_key": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
      "mtu": 1280,
      "fake_packets": "5-10",
      "fake_packets_size": "40-100",
      "fake_packets_delay": "20-250",
      "fake_packets_mode": "m4"
    }
  ]
}
EOM
)
[ -t 1 ] && echo "########## НАЧАЛО КОНФИГА ##########"
# Вывод готового JSON
echo "${json_conf}"
[ -t 1 ] && echo "########### КОНЕЦ КОНФИГА ###########"


echo "\"reserved\": \"${reserved64}\","
echo "\"reserved\": \"${reservedHex}\","
echo "\"reserved\": \"${reservedDec}\","
