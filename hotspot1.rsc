# nov/20/2022 21:42:19 by RouterOS 6.49.7
#Radius hotspot
/interface bridge
add comment=LAN name=bridge
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n channel-width=20/40mhz-XX \
    country=no_country_set disabled=no frequency=auto frequency-mode=\
    superchannel hw-retries=10 mode=ap-bridge multicast-helper=disabled ssid=\
    "test Hostpot" wireless-protocol=802.11 wps-mode=disabled
/interface ethernet
set [ find default-name=ether1 ] comment=WAN
/interface list
add name=WANs
add name=LANs
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/ip hotspot profile
add dns-name=free.wifi.net hotspot-address=192.168.15.1 login-by=\
    cookie,http-chap,http-pap,mac-cookie name=hsprof1 nas-port-type=ethernet \
    use-radius=yes
/ip hotspot
add addresses-per-mac=unlimited disabled=no interface=bridge name=hotspot1 \
    profile=hsprof1
/ip pool
add name=hotspot1-pool ranges=192.168.15.2-192.168.15.254
/ip dhcp-server
add address-pool=hotspot1-pool disabled=no interface=bridge lease-time=1h \
    name=dhcp1
/queue type
add kind=pcq name=PLAN2M-UP pcq-classifier=src-address pcq-rate=512k
add kind=pcq name=PLAN2M-DOWN pcq-classifier=dst-address pcq-rate=1024k
add kind=pcq name=TOTAL-UP pcq-classifier=src-address
add kind=pcq name=TOTAL-DOWN pcq-classifier=dst-address
/queue tree
add name="DOWNLOAD TOTAL" parent=global queue=TOTAL-DOWN
add name="UPLOAD TOTAL" parent=global queue=PLAN2M-UP
add name=PLAN-2M-DOWN packet-mark=plan2M_down parent="DOWNLOAD TOTAL" queue=\
    PLAN2M-DOWN
add name=PLAN-2M-UP packet-mark=plan2M_up parent="UPLOAD TOTAL" queue=\
    PLAN2M-UP
/interface bridge port
add bridge=bridge interface=ether2
add bridge=bridge interface=ether3
add bridge=bridge interface=ether4
add bridge=bridge interface=wlan1
/interface list member
add interface=ether1 list=WANs
add interface=bridge list=LANs
/ip address
add address=192.168.15.1/24 comment="IPs Hotspot" interface=bridge network=\
    192.168.15.0
add address=10.147.0.1/24 comment="IPs Residenciales" interface=bridge \
    network=10.147.0.0
/ip dhcp-client
add disabled=no interface=ether1 use-peer-dns=no use-peer-ntp=no
/ip dhcp-server network
add address=192.168.15.0/24 comment="hotspot network" dns-server=\
    192.168.15.1,8.8.8.8,8.8.4.4 gateway=192.168.15.1
/ip dns
set allow-remote-requests=yes servers=8.8.8.8,8.8.4.4
/ip firewall address-list
add address=10.147.0.254 comment=CLIENTE1 list=PLAN_2M
/ip firewall filter
add action=accept chain=input comment=\
    "Accept Related or Established Connections" connection-state=\
    established,related
add action=accept chain=forward comment="Accept New Connections" \
    connection-state=new
add action=accept chain=forward comment=\
    "Accept Related or Established Connections" connection-state=\
    established,related
add action=drop chain=input comment="Drop Invalid Connections" \
    connection-state=invalid
add action=drop chain=forward comment="Drop Invalid Connections" \
    connection-state=invalid
add action=add-src-to-address-list address-list="(WAN High Connection Rates)" \
    chain=input comment="Add WAN High Connections to Address List" \
    connection-limit=100,32 protocol=tcp
add action=add-src-to-address-list address-list="(LAN High Connection Rates)" \
    chain=forward comment="Add LAN High Connections to Address List" \
    connection-limit=100,32 protocol=tcp
add action=drop chain=forward comment="Drop all other LAN Traffic"
add action=drop chain=input comment="Drop all other WAN Traffic"
add chain=output comment="Section Break" disabled=yes
/ip firewall mangle
add action=mark-packet chain=forward comment="PLAN 2M" new-packet-mark=\
    plan2M_up passthrough=no src-address-list=PLAN_2M
add action=mark-packet chain=forward dst-address-list=PLAN_2M \
    new-packet-mark=plan2M_down passthrough=no
/ip firewall nat
add action=masquerade chain=srcnat out-interface-list=WANs
add action=masquerade chain=srcnat comment="Masquerade hotspot network" \
    src-address=192.168.15.0/24
add action=masquerade chain=srcnat comment="Masquerade Residencial network" \
    src-address=10.147.0.0/24
/ip hotspot ip-binding
add comment="Cliente 1" address=10.147.0.254 mac-address=F8:E4:3B:15:95:8A to-address=\
    10.147.0.254 type=bypassed
/ip service
set telnet disabled=yes
set ftp disabled=yes
set ssh port=25
set api disabled=yes
set api-ssl disabled=yes
/system clock
set time-zone-name=America/Mexico_City
/system ntp client
set enabled=yes primary-ntp=216.239.35.8
/system scheduler
add comment=">>RENEW DHCP" interval=5m name=Renew-dhcp-client on-event=\
    renew-dhcp-client policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=jan/01/1970 start-time=18:45:37
/system script
add comment=">>RENEW DHCP" dont-require-permissions=no name=renew-dhcp-client \
    owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":\
    if ( [/ping 8.8.8.8 interface=ether1 count=6 ] = 0 ) do={/ip dhcp-client r\
    enew ether1}"