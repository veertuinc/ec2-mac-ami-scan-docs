---
title: >
  Getting Started
type: "docs"
---

{{< include file="_partials/what-is/_short.md" >}}

```bash
❯ docker run -it --rm -v /Library/Application\ Support/Veertu/Anka/registry:/mnt public.ecr.aws/k5c2b8e5/anka-scanner:0.0.1 --help                

A vulnerability scanner for Anka VMs and images.

Supported commands/types:
  scanner registry_template:uuid[:tag]    | Read and scan from registry Anka VM using the UUID and optional tag
                                            - [:tag] defaults to latest tag
  scanner ank_image:/path/to/image.ank    | Read and scan using an Anka image at the specified path
  scanner dir:/path/to/folder             | Scan from the specified path

Usage:
  scanner type:source [flags]
  scanner [command]

Available Commands:
  completion  generate the autocompletion script for the specified shell
  help        Help about any command
  version     show the version

Flags:
  -c, --config string          application config file
  -h, --help                   help for scanner
  -i, --ignore-system-volume   do not scan the system volume (for anka VM)
  -q, --quiet                  suppress all console output
  -o, --report-file string     write report to file
  -f, --report-format string   report output format, formats=[json table] (default "table")
  -p, --show-packages          do not scan and only show packages
  -s, --storage-dir string     the location in the container where you have mounted the registry storage or other host directory (default "/mnt")

Use "scanner [command] --help" for more information about a command.
```

## Prerequisites

- Access to the Anka Registry storage directory
- Docker
- ~200MBs of space
- 16GB of RAM or more

## Usage

{{< hint info >}}
While in beta, we are providing only a docker image/tag for running the scanner. The database is inside of the container for now.
{{< /hint >}}

There are three different commands/types available in the scanner:

1. [`registry_template`](#anka-registry-vm)
2. [`ank_image`](#anka-image)

### Anka Registry VM

This type will automatically scan the registry storage directory you've mounted and find the proper .ank file to scan. It's essentially `anka_image` under the hood.

Let's say I have three tags for an Anka VM Template: `vanilla`, `vanilla+port-forward-22`, and `vanilla+port-forward-22+brew-git`. If I wanted to scan `vanilla`, I would run:

```bash
export REGISTRY_PATH="/Library/Application Support/Veertu/Anka/registry"
❯ docker run -it --rm -v "${REGISTRY_PATH}:/mnt" public.ecr.aws/k5c2b8e5/anka-scanner:0.0.1 registry_template:ea663a61-0e5c-4419-8194-697104fb693a:vanilla
 ✔ Indexed Data Volume      ✔ Cataloged packages      [10 packages]
 ✔ Indexed System Volume    ✔ Cataloged packages      [344 packages]

TYPE       NAME          VERSION   VULNERABILITY   SCORE  SEVERITY 
macos-app  python        2.7.18    CVE-2017-17522  8.8    high      
macos-app  python        2.7.18    CVE-2021-23336  5.9    medium    
macos-app  python        2.7.18    CVE-2015-5652   7.2    high      
macos-app  python        2.7.18    CVE-2017-18207  6.5    medium    
macos-app  python        2.7.18    CVE-2019-20907  7.5    high      
macos-app  python        2.7.18    CVE-2019-9674   7.5    high      
python     cryptography  2.9.2     CVE-2020-36242  9.1    critical  
python     numpy         1.8.0rc1  CVE-2014-1859   5.5    medium    
python     numpy         1.8.0rc1  CVE-2014-1858   5.5    medium    
python     numpy         1.8.0rc1  CVE-2017-12852  7.5    high      
python     numpy         1.8.0rc1  CVE-2019-6446   9.8    critical 
```

Or, write the report to a file:

```bash
❯ docker run -it --rm -v "${REGISTRY_PATH}:/mnt" -v "$(pwd):/reports" public.ecr.aws/k5c2b8e5/anka-scanner:0.0.1 registry_template:ea663a61-0e5c-4419-8194-697104fb693a:vanilla --report-file /reports/report-$(date +"%m_%d_%Y_%H:%M")
 ✔ Indexed Data Volume      ✔ Cataloged packages      [10 packages]
 ✔ Indexed System Volume    ✔ Cataloged packages      [344 packages]
Report written to "/reports/report-12_06_2021_16:44"

❯ cat report-12_06_2021_16:44 
TYPE       NAME          VERSION   VULNERABILITY   SCORE  SEVERITY 
macos-app  python        2.7.18    CVE-2019-20907  7.5    high      
macos-app  python        2.7.18    CVE-2019-9674   7.5    high      
macos-app  python        2.7.18    CVE-2021-23336  5.9    medium    
macos-app  python        2.7.18    CVE-2017-17522  8.8    high      
macos-app  python        2.7.18    CVE-2015-5652   7.2    high      
macos-app  python        2.7.18    CVE-2017-18207  6.5    medium    
python     cryptography  2.9.2     CVE-2020-36242  9.1    critical  
python     numpy         1.8.0rc1  CVE-2014-1859   5.5    medium    
python     numpy         1.8.0rc1  CVE-2014-1858   5.5    medium    
python     numpy         1.8.0rc1  CVE-2017-12852  7.5    high      
python     numpy         1.8.0rc1  CVE-2019-6446   9.8    critical  
```

### Ank Image

If you're a more advanced user, you can determine the root .ank file inside of the metadata yaml for your VM/Template. This allows you to scan on your registry but also on an Anka host machine as well.

I'm going to track down the `hard_drives > controller > file` value first:

```bash
❯ cat $(anka config vm_lib_dir)/ea663a61-0e5c-4419-8194-697104fb693a/ea663a61-0e5c-4419-8194-697104fb693a.yaml | grep -5 hard_drives
    width: 1024
ram: 8G
uuid: ea663a61-0e5c-4419-8194-697104fb693a
creation_date: '2021-10-25T22:21:58.406768Z'
nvram: true
hard_drives:
- controller: ablk
  file: ce87816df16f4661a1be0684add6ca2f.ank
  pci_slot: 4
network_cards:
- mode: shared

❯ docker run -it --rm -v "$(anka config img_lib_dir)/..:/mnt" public.ecr.aws/k5c2b8e5/anka-scanner:0.0.1 ank_image:/mnt/img_lib/ce87816df16f4661a1be0684add6ca2f.ank
 ✔ Indexed Data Volume      ✔ Cataloged packages      [214 packages]
 ✔ Indexed System Volume    ✔ Cataloged packages      [344 packages]

TYPE       NAME          VERSION   VULNERABILITY   SCORE  SEVERITY 
gem        i18n          0.9.5     CVE-2020-7791   7.5    high      
gem        i18n          1.8.10    CVE-2020-7791   7.5    high      
gem        parallel      1.21.0    CVE-2015-4156   3.6    low       
gem        parallel      1.21.0    CVE-2015-4155   3.6    low       
gem        webrick       1.7.0     CVE-2008-1145   5.0    medium    
macos-app  python        3.8.9     CVE-2021-29921  9.8    critical  
macos-app  python        2.7.18    CVE-2021-23336  5.9    medium    
macos-app  python        2.7.18    CVE-2019-20907  7.5    high      
macos-app  python        2.7.18    CVE-2017-18207  6.5    medium    
macos-app  python        2.7.18    CVE-2015-5652   7.2    high      
macos-app  python        2.7.18    CVE-2019-9674   7.5    high      
macos-app  python        2.7.18    CVE-2017-17522  8.8    high      
python     cryptography  2.9.2     CVE-2020-36242  9.1    critical  
python     numpy         1.8.0rc1  CVE-2014-1858   5.5    medium    
python     numpy         1.8.0rc1  CVE-2017-12852  7.5    high      
python     numpy         1.8.0rc1  CVE-2019-6446   9.8    critical  
python     numpy         1.8.0rc1  CVE-2014-1859   5.5    medium  
```