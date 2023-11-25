#!/bin/bash

# Внешний интерфейс сервера
IF_EXT="ens3"

# Внутренние интерфейсы (обслуживающие ВПН-клиентов)
IF_INT="ppp+"

# Сеть, адреса из которой будут получать ВПН-клиенты
NET_INT="172.28.253.64/26"

# Сбрасываем все правила
iptables -F
iptables -F -t nat

# Устанавливаем политики по умолчанию
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP

# Разрешаем весь трафик на петлевом интерфейсе
iptables -A INPUT -i lo -j ACCEPT

# Разрешаем всё для ВПН-клиентов
iptables -A INPUT -i ${IF_INT} -s ${NET_INT} -j ACCEPT

# Разрешаем входящие соединения к L2TP
# Но только с шифрованием!
#iptables -A INPUT -p udp -m policy --dir in --pol ipsec -m udp --dport 1701 -j ACCEPT
iptables -A INPUT -p udp -m udp --dport 1701 -j ACCEPT


# Разрешаем IPSec
iptables -A INPUT -p esp -j ACCEPT
iptables -A INPUT -p ah -j ACCEPT
iptables -A INPUT -p udp --dport 500 -j ACCEPT
iptables -A INPUT -p udp --dport 4500 -j ACCEPT

# Разрешаем доступ к серверу по SSH
#iptables -A INPUT -m tcp -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -m tcp -p tcp -s 217.66.0.0/16 --dport 22 -j ACCEPT
iptables -A INPUT -m tcp -p tcp -s 94.25.228.1/23 --dport 22 -j ACCEPT

#Разрешаем openvpn по стандартному порту
iptables -A INPUT -p udp --dport openvpn -j ACCEPT

# Разрешаем входящие ответы на исходящие соединения
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# NAT для локальной сети (ВПН-клиентов)
iptables -t nat -A POSTROUTING -s ${NET_INT} -j MASQUERADE -o ${IF_EXT}
iptables -A FORWARD -i ${IF_INT} -o ${IF_EXT} -s ${NET_INT} -j ACCEPT
iptables -A FORWARD -i ${IF_EXT} -o ${IF_INT} -d ${NET_INT} -m state --state RELATED,ESTABLISHED -j ACCEPT
