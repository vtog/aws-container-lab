{
    "schemaVersion": "1.0.0",
    "class": "Device",
    "async": true,
        "Common": {
            "class": "Tenant",
                "hostname": "bigip1.f5demos.com",
                "myDns": {
                    "class": "DNS",
                    "nameServers": [
                        "8.8.8.8",
                        "8.8.4.4"
                    ],
                    "search": [
                        "f5demos.com",
                        "tognaci.com"
                    ]
                },
                "myNtp": {
                    "class": "NTP",
                    "servers": [
                        "pool.ntp.org"
                    ],
                    "timezone": "UTC"
                },
                "myProvisioning": {
                    "class": "Provision",
                    "ltm": "nominal"
                },
                "ext-vlan": {
                    "class": "VLAN",
                    "interfaces": [
                        {
                            "name": "1.1"
                        }
                    ]
                },
                "ext-self": {
                    "class": "SelfIp",
                    "address": "${external_ip}",
                    "vlan": "ext-vlan",
                    "allowService": "none",
                    "trafficGroup": "traffic-group-local-only"
                },
                "int-vlan": {
                    "class": "VLAN",
                    "interfaces": [
                        {
                            "name": "1.2"
                        }
                    ]
                },
                "int-self": {
                    "class": "SelfIp",
                    "address": "${internal_ip}",
                    "vlan": "int-vlan",
                    "allowService": "none",
                    "trafficGroup": "traffic-group-local-only"
                }
        }
}
