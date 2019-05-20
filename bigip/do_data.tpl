{
    "schemaVersion": "1.0.0",
    "class": "Device",
    "async": true,
        "Common": {
            "class": "Tenant",
                "hostname": "${host_name}",
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
                    "timezone": "America/Chicago"
                },
                "myProvisioning": {
                    "class": "Provision",
                    "ltm": "nominal"
                },
                "external": {
                    "class": "VLAN",
                    "interfaces": [
                        {
                            "name": "1.1"
                        }
                    ]
                },
                "external-self": {
                    "class": "SelfIp",
                    "address": "${external_ip}",
                    "vlan": "external",
                    "allowService": "none",
                    "trafficGroup": "traffic-group-local-only"
                },
                "internal": {
                    "class": "VLAN",
                    "interfaces": [
                        {
                            "name": "1.2"
                        }
                    ]
                },
                "internal-self": {
                    "class": "SelfIp",
                    "address": "${internal_ip}",
                    "vlan": "internal",
                    "allowService": "none",
                    "trafficGroup": "traffic-group-local-only"
                },
                "configsync": {
                    "class": "ConfigSync",
                    "configsyncIp": "/Common/internal-self/address"
                },
                "failoverAddress": {
                    "class": "FailoverUnicast",
                    "address": "/Common/internal-self/address"
                }
        }
}
