# SZMGMT

The SZMGMT gem serves as tool for automatic management of Solaris Zones virtualization technology. It provide user interface by the means of executable `bin/szmgmt-cli` and `szmgmt-editor`.
These two command can be used to invoke automatic administrating routines for this virtualization technology. Using this tool you can create, backup, recover, manage or migrate zones
on local or remote servers.
 
## Installation

As this is the Ruby gem the installation process is very simple. This gem have not been uploaded to Ruby gems yet. So firstly you have to clone this repository:

    $ git clone https://github.com/simactom/szmgmt szmgmt

Than you have to build the gem using:
    
    $ gem build szmgmt.gemspec
    
And finally install the gem from the package:

    $ gem install szmgmt-1.0.0

## Usage

This tool provides CLI to users that can use following commands:

    $Commands:
       szmgmt_cli backup [ZONE_ID, ...]
       szmgmt_cli deploy [ZONE_ID, ...]
       szmgmt_cli editor
       szmgmt_cli help [COMMAND]
       szmgmt_cli host SUBCOMMAND
       szmgmt_cli journal [SUBCOMMAND]
       szmgmt_cli list
       szmgmt_cli manage SUBCOMMAND
       szmgmt_cli migrate [ZONE_ID, ...]
       szmgmt_cli recovery [ZONE_ID, ...] -a [BACKUP]
       szmgmt_cli template [SUBCOMMAND]
     Options:
       -f, [--force]

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/simactom/szmgmt.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
