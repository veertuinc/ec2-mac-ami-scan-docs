---
title: >
  Getting Started
type: "docs"
---

{{< include file="_partials/what-is/_short.md" >}}

```bash
❯ docker run -it --rm -v /Library/Application\ Support/Veertu/Anka/registry:/mnt public.ecr.aws/k5c2b8e5/scanner:0.0.1 --help

A vulnerability scanner for Anka VM images and macOS filesystems.

Supported commands/types:
  scanner anka_registry_vm:uuid[:tag]    | Read and scan from registry Anka VM using the UUID and optional tag
                                           - [:tag] defaults to latest tag
  scanner anka_image:/path/to/image.ank  | Read and scan using an Anka image at the specified path
  scanner dir:/path/to/folder            | Scan from the specified path

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
  -i, --ignore-system-volume   do not scan system volume (for anka VM)
  -q, --quiet                  suppress all console output
  -o, --report-file string     write report to file in storage directory (--storage-dir)
  -f, --report-format string   report output format, formats=[json table] (default "table")
  -p, --show-packages          do not scan and only show packages
  -s, --storage-dir string     the location in the container where you have mounted the registry or other storage directory (default "/mnt")

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

1. [`anka_registry_vm`](#anka-registry-vm)
2. [`anka_image`](#anka-image)
3. [`dir`](#directory)

### Anka Registry VM

This type will automatically scan the registry storage directory you've mounted and find the proper .ank file to scan. It's essentially `anka_image` under the hood.

Let's say I have three tags for an Anka VM Template: `vanilla`, `vanilla+port-forward-22`, and `vanilla+port-forward-22+brew-git`. If I wanted to scan `vanilla`, I would run:

```bash
❯ docker run -it --rm -v /Library/Application\ Support/Veertu/Anka/registry:/mnt public.ecr.aws/k5c2b8e5/scanner:0.0.1 anka_registry_vm:ea663a61-0e5c-4419-8194-697104fb693a:vanilla
] You are using a beta/trial version which expires on 2022-01-31
 ✔ Indexed Data Volume      ✔ Cataloged packages      [10 packages]
 ✔ Indexed System Volume    ✔ Cataloged packages      [344 packages]
TYPE       NAME          VERSION   VULNERABILITY   SCORE  SEVERITY 
macos-app  python        2.7.18    CVE-2021-23336  5.9    medium    
macos-app  python        2.7.18    CVE-2019-20907  7.5    high      
macos-app  python        2.7.18    CVE-2017-17522  8.8    high      
macos-app  python        2.7.18    CVE-2017-18207  6.5    medium    
macos-app  python        2.7.18    CVE-2019-9674   7.5    high      
macos-app  python        2.7.18    CVE-2015-5652   7.2    high      
python     cryptography  2.9.2     CVE-2020-36242  9.1    critical  
python     numpy         1.8.0rc1  CVE-2014-1858   5.5    medium    
python     numpy         1.8.0rc1  CVE-2014-1859   5.5    medium    
python     numpy         1.8.0rc1  CVE-2017-12852  7.5    high      
python     numpy         1.8.0rc1  CVE-2019-6446   9.8    critical 
```

Or, write the report to a file:

```bash
❯ docker run -it --rm -v /Library/Application\ Support/Veertu/Anka/registry:/mnt public.ecr.aws/k5c2b8e5/scanner:0.0.1 anka_registry_vm:ea663a61-0e5c-4419-8194-697104fb693a:vanilla
 ✔ Indexed Data Volume      ✔ Cataloged packages      [10 packages]
 ✔ Indexed System Volume    ✔ Cataloged packages      [344 packages]
Report written to "/mnt/logfile"

❯ cat /Library/Application\ Support/Veertu/Anka/registry/logfile
TYPE       NAME          VERSION   VULNERABILITY   SCORE  SEVERITY 
macos-app  python        2.7.18    CVE-2019-9674   7.5    high      
macos-app  python        2.7.18    CVE-2017-17522  8.8    high      
macos-app  python        2.7.18    CVE-2019-20907  7.5    high      
macos-app  python        2.7.18    CVE-2017-18207  6.5    medium    
macos-app  python        2.7.18    CVE-2021-23336  5.9    medium    
macos-app  python        2.7.18    CVE-2015-5652   7.2    high      
python     cryptography  2.9.2     CVE-2020-36242  9.1    critical  
python     numpy         1.8.0rc1  CVE-2014-1858   5.5    medium    
python     numpy         1.8.0rc1  CVE-2014-1859   5.5    medium    
python     numpy         1.8.0rc1  CVE-2017-12852  7.5    high      
python     numpy         1.8.0rc1  CVE-2019-6446   9.8    critical 
```

### Anka Image

If you're a more advanced user, you can determine the root .ank file inside of the metadata yaml for your VM/Template. This allows you to scan on your registry but also on an Anka host machine as well.

I'm going to track down the `hard_drives > controller > file` value first:

```bash
❯ cat ~/Library/Application\ Support/Veertu/Anka/vm_lib/ea663a61-0e5c-4419-8194-697104fb693a/ea663a61-0e5c-4419-8194-697104fb693a.yaml | grep -5 hard_drives
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

❯ docker run -it --rm -v /Users/nathanpierce/Library/Application\ Support/Veertu/Anka:/mnt public.ecr.aws/k5c2b8e5/scanner:0.0.1 anka_image:/mnt/img_lib/ce87816df16f4661a1be0684add6ca2f.ank
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
macos-app  python        2.7.18    CVE-2015-5652   7.2    high      
macos-app  python        2.7.18    CVE-2019-9674   7.5    high      
macos-app  python        2.7.18    CVE-2017-17522  8.8    high      
macos-app  python        2.7.18    CVE-2017-18207  6.5    medium    
macos-app  python        2.7.18    CVE-2019-20907  7.5    high      
python     cryptography  2.9.2     CVE-2020-36242  9.1    critical  
python     numpy         1.8.0rc1  CVE-2014-1859   5.5    medium    
python     numpy         1.8.0rc1  CVE-2017-12852  7.5    high      
python     numpy         1.8.0rc1  CVE-2019-6446   9.8    critical  
python     numpy         1.8.0rc1  CVE-2014-1858   5.5    medium
```

### Directory

Lastly, you can scan a folder on your local machine:

```bash
❯ docker run -it --rm -v /Users/user1/:/mnt public.ecr.aws/k5c2b8e5/scanner:0.0.1 dir:/mnt/myProject
 ✔ Indexed /mnt/myProject     ✔ Cataloged packages      [660 packages]
TYPE       NAME                        VERSION                                                     VULNERABILITY   SCORE  SEVERITY 
gem        actionview                  4.1.1                                                       CVE-2020-5267   4.8    medium    
gem        i18n                        0.6.9                                                       CVE-2020-7791   7.5    high      
gem        i18n                        0.6.9                                                       CVE-2014-10077  7.5    high      
gem        jquery-rails                3.1.0                                                       CVE-2015-1840   5.0    medium    
gem        json                        1.8.1                                                       CVE-2020-10663  7.5    high      
gem        json                        1.8.1                                                       CVE-2020-7712   7.2    high      
gem        mail                        2.5.4                                                       CVE-2015-9097   6.1    medium    
gem        mail                        2.5.4                                                       CVE-2016-4879   8.8    high      
gem        rack                        1.5.2                                                       CVE-2019-16782  5.9    medium    
gem        rack                        1.5.2                                                       CVE-2020-8184   7.5    high      
gem        rack                        1.5.2                                                       CVE-2015-3225   5.0    medium    
gem        rack                        1.5.2                                                       CVE-2020-8161   8.6    high      
gem        rails                       4.1.1                                                       CVE-2020-8164   7.5    high      
gem        rails                       4.1.1                                                       CVE-2020-8166   4.3    medium    
gem        rails                       4.1.1                                                       CVE-2021-22904  7.5    high      
gem        rails                       4.1.1                                                       CVE-2020-8162   7.5    high      
gem        rails                       4.1.1                                                       CVE-2019-5418   7.5    high      
gem        rails                       4.1.1                                                       CVE-2019-5420   9.8    critical  
gem        rails                       4.1.1                                                       CVE-2020-8163   8.8    high      
gem        rails                       4.1.1                                                       CVE-2020-8167   6.5    medium    
gem        rails                       4.1.1                                                       CVE-2020-8165   9.8    critical  
gem        rails                       4.1.1                                                       CVE-2019-5419   7.8    high      
gem        rake                        10.3.2                                                      CVE-2020-8130   6.9    high      
gem        rdoc                        4.1.1                                                       CVE-2021-31799  7.0    high      
gem        sprockets                   2.11.0                                                      CVE-2014-7819   5.0    medium    
gem        sprockets                   2.11.0                                                      CVE-2018-3760   7.5    high      
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2014-8179   7.5    high      
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2018-10892  5.3    medium    
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2014-0048   9.8    critical  
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2014-5278   5.3    medium    
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2019-15752  9.3    critical  
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2020-27534  5.3    medium    
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2021-21285  6.5    medium    
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2014-9356   8.6    high      
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2015-3631   3.6    low       
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2019-13139  8.4    high      
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2021-3162   7.8    high      
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2014-8178   5.5    medium    
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2014-9358   6.4    medium    
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2015-3627   7.2    high      
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2021-21284  6.8    medium    
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2014-5282   8.1    high      
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2014-6407   7.5    high      
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2017-14992  6.5    medium    
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2014-5277   5.0    medium    
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2019-13509  7.5    high      
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2019-5736   9.3    critical  
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2014-0047   7.8    high      
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2015-3630   7.2    high      
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2016-3697   7.8    high      
go-module  github.com/docker/docker    v17.12.0-ce-rc1.0.20200309214505-aa6a9891b09c+incompatible  CVE-2019-16884  7.5    high      
go-module  github.com/golang/protobuf  v1.5.2                                                      CVE-2021-3121   8.6    high      
go-module  google.golang.org/protobuf  v1.27.1                                                     CVE-2015-5237   8.8    high      
npm        ansi-regex                  3.0.0                                                       CVE-2021-3807   7.8    high      
npm        minimist                    0.0.10                                                      CVE-2020-7598   6.8    medium 
```
