#!/bin/bash

# Очистить текущие правила iptables
iptables -F
iptables -X
iptables -Z

# Установить политику по умолчанию для цепочек
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Разрешить соединение по UDP на порту OpenVPN
iptables -A INPUT -p udp --dport openvpn -j ACCEPT

# Разрешить все входящие соединения
iptables -A INPUT -p all -j ACCEPT

# Разрешить соединения с подсетью 172.28.253.64/26
iptables -A INPUT -s 172.28.253.64/26 -j ACCEPT

# Разрешить соединение по UDP на порту L2F
iptables -A INPUT -p udp --dport l2f -j ACCEPT

# Разрешить ESP (Encapsulating Security Payload) трафик
iptables -A INPUT -p esp -j ACCEPT

# Разрешить AH (Authentication Header) трафик
iptables -A INPUT -p ah -j ACCEPT

# Разрешить соединение по UDP на порту ISAKMP
iptables -A INPUT -p udp --dport isakmp -j ACCEPT

# Разрешить соединение по UDP на порту IPsec NAT-T
iptables -A INPUT -p udp --dport ipsec-nat-t -j ACCEPT

# Разрешить соединение по TCP на порту SSH из сетей 217.66.0.0/16 и 94.25.228.0/23
iptables -A INPUT -p tcp -s 217.66.0.0/16 --dport ssh -j ACCEPT
iptables -A INPUT -p tcp -s 94.25.228.0/23 --dport ssh -j ACCEPT

# Разрешить соединение по UDP на порту OpenVPN
iptables -A INPUT -p udp --dport openvpn -j ACCEPT

# Разрешить соединения, установленные или связанные с уже установленными соединениями
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# Разрешить соединения из подсети 10.8.0.0/24
iptables -A FORWARD -s 10.8.0.0/24 -j ACCEPT

# Разрешить соединения с подсетью 172.28.253.64/26
iptables -A FORWARD -s 172.28.253.64/26 -j ACCEPT
iptables -A FORWARD -d 172.28.253.64/26 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

#Добавить правила для цепочек DOCKER, DOCKER-ISOLATION-STAGE-1, DOCKER-ISOLATION-STAGE-2, DOCKER-USER
iptables -N DOCKER
iptables -A FORWARD -o docker0 -j DOCKER
iptables -A FORWARD -o docker_gwbridge -j DOCKER
iptables -A DOCKER -d 172.28.253.64/26 ! -i docker0 -o docker0 -p tcp -m tcp --dport 3306 -j ACCEPT
iptables -A DOCKER -d 172.28.253.64/26 ! -i docker0 -o docker0 -p tcp -m tcp --dport 6379 -j ACCEPT
iptables -A DOCKER -d 172.28.253.64/26 ! -i docker0 -o docker0 -p tcp -m tcp --dport 9200 -j ACCEPT
iptables -A DOCKER-ISOLATION-STAGE-1 -i docker0 ! -o docker0 -j DOCKER-ISOLATION-STAGE-2
iptables -A DOCKER-ISOLATION-STAGE-1 -i docker_gwbridge ! -o docker_gwbridge -j DOCKER-ISOLATION-STAGE-2
iptables -A DOCKER-ISOLATION-STAGE-1 -j RETURN
iptables -A DOCKER-ISOLATION-STAGE-2 -o docker0 -j DROP
iptables -A DOCKER-ISOLATION-STAGE-2 -o docker_gwbridge -j DROP
iptables -A DOCKER-ISOLATION-STAGE-2 -j RETURN
iptables -A DOCKER-USER -j RETURN
