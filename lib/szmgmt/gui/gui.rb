module SZMGMT
  module GUI
    DEFAULT_VM_SPEC = {
        "name" => "default",
        "type" => "szones",
        "configuration" => {
            "brand" => "solaris",
            "zonepath" => "/system/zones/%{zonename}",
            "autoboot" => '',
            "ip-type" => "exclusive",
            "resources" => [
                {
                    "type" => "anet",
                    "values" => {
                        "linkname" => "net0",
                        "lower-link" => "auto",
                        "mac-address" => "auto"
                    }
                }
            ]
        },
        "manifest" => {
            "packages" => [
                "pkg:/group/system/solaris-small-server"
            ]
        },
        "profile" => {
            "hostname" => "solaris",
            "timezone" => "Europe/Prague",
            "locale" => "en_US.UTF-8",
            "users" => [
                {
                    "type" => "root",
                    "values" => {
                        "password" => '',
                        "type" => 'role'
                    }
                },
                {
                    "type" => "user",
                    "values" => {
                        "login" => 'user',
                        "pasword" => '',
                        "shell" => "/bin/bash",
                        "type" => "normal",
                        "sudoers" => "ALL=(ALL) ALL",
                        "roles" => [
                            "root"
                        ],
                        "profiles" => [
                            "System Administrator"
                        ]
                    }
                }
            ],
            "network" => [
                {
                    "name" => "net0",
                    "address_type" => "dhcp",
                }
            ]
        }
    }
  end
end