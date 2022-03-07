---
title: >
  Getting Started
type: "docs"
---

{{< include file="_partials/what-is/_short.md" >}}

```bash
❯ docker run -it --rm -v /Library/Application\ Support/Veertu/Anka/registry:/mnt public.ecr.aws/veertu/anka-scan:0.2.1 --help
A vulnerability scanner for Anka VMs and images.

Supported commands/types:
  anka-scan registry_template:uuid[:tag]    | Read and scan from registry Anka VM using the UUID and optional tag
                                            - [:tag] defaults to latest tag
  anka-scan ank_image:/path/to/image.ank    | Read and scan using an Anka image at the specified path
  anka-scan dir:/path/to/folder             | Scan from the specified path

Usage:
  anka-scan type:source [flags]
  anka-scan [command]

Available Commands:
  completion  generate the autocompletion script for the specified shell
  help        Help about any command
  version     show the version

Flags:
  -c, --config string          application config file
  -h, --help                   help for anka-scan
  -i, --ignore-system-volume   do not scan the system volume (for anka VM)
  -q, --quiet                  suppress all console output
  -o, --report-file string     write report to file
  -f, --report-format string   report output format, formats=[json table] (default "table")
  -p, --show-packages          do not scan and only show packages
  -s, --storage-dir string     the location of the registry storage containing *_lib directories (default "/mnt")

Use "anka-scan [command] --help" for more information about a command.
```

## Prerequisites

- Access to the Anka Registry storage directory
- Docker
- ~200MBs of space
- 16GB of RAM or more

{{< hint warning >}}
If using docker, be sure that docker itself has access to more than 8GBs of memory.
{{< /hint >}}

## Usage (Docker)

{{< hint info >}}
While in beta, the database is inside of the container and cannot be updated. However, we plan on allow you to update the database in a user friendly way.
{{< /hint >}}

There are two different commands/types available in the scanner:

1. [`registry_template`](#anka-registry-vm)
2. [`ank_image`](#ank-image)

### Anka Registry VM

This type will automatically scan the registry storage directory you've mounted and find the proper .ank file to scan. It's essentially `anka_image` under the hood.

Let's say I have three tags for an Anka VM Template: `vanilla`, `vanilla+port-forward-22`, and `vanilla+port-forward-22+brew-git`. If I wanted to scan `vanilla`, I would run:

```bash
export REGISTRY_PATH="/Library/Application Support/Veertu/Anka/registry"
❯ docker run -it --rm -v "${REGISTRY_PATH}:/mnt" public.ecr.aws/veertu/anka-scan:0.2.1 registry_template:ea663a61-0e5c-4419-8194-697104fb693a:vanilla
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
❯ docker run -it --rm -v "${REGISTRY_PATH}:/mnt" -v "$(pwd):/reports" public.ecr.aws/veertu/anka-scan:0.2.1 registry_template:ea663a61-0e5c-4419-8194-697104fb693a:vanilla --report-file /reports/report-$(date +"%m_%d_%Y_%H:%M")
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
❯ cat "$(anka config vm_lib_dir)/ea663a61-0e5c-4419-8194-697104fb693a/ea663a61-0e5c-4419-8194-697104fb693a.yaml" | grep -5 hard_drives
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

❯ docker run -it --rm -v "$(anka config img_lib_dir)/..:/mnt" public.ecr.aws/veertu/anka-scan:0.2.1 ank_image:/mnt/img_lib/ce87816df16f4661a1be0684add6ca2f.ank
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


### Report Formats

By default the human readable table output does not include paths or other information about how the vulnerability was found. Fortunately, we allow you to produce verbose JSON output with that information.

{{< hint info >}}
The use of `--quiet` here is important to avoid any output which is not json parsable.
{{< /hint >}}

```bash
❯ docker run -it --rm -v "$(anka config img_lib_dir)/..:/mnt" public.ecr.aws/veertu/anka-scan:0.2.1 ank_image:/mnt/img_lib/c2deedc229ae4e8b967aef0ddf4b2813.ank --report-format json --quiet
{
 "matches": [
  {
   "vulnerability": {
    "id": "CVE-2020-7791",
    "base-score": 7.5,
    "severity": "high"
   },
   "matchDetails": [
    {
     "matched-cpe": "cpe:/a:i18n_project:i18n:::~~~asp.net~~",
     "matched-version": "0.9.5",
     "matched-constraint": "< 2.1.15",
     "match-type": "Semantic"
    }
   ],
   "artifact": {
    "name": "i18n",
    "version": "0.9.5",
    "type": "gem",
    "locations": [
     {
      "path": "/usr/local/Homebrew/docs/Gemfile.lock"
     }
    ],
    "language": "ruby",
    "licenses": [],
    "cpes": [
     "cpe:2.3:a:ruby-lang:i18n:0.9.5:*:*:*:*:*:*:*",
     "cpe:2.3:a:ruby_lang:i18n:0.9.5:*:*:*:*:*:*:*",
     "cpe:2.3:a:i18n:i18n:0.9.5:*:*:*:*:*:*:*",
     "cpe:2.3:a:ruby:i18n:0.9.5:*:*:*:*:*:*:*",
     "cpe:2.3:a:*:i18n:0.9.5:*:*:*:*:*:*:*"
    ],
    "purl": "pkg:gem/i18n@0.9.5",
    "metadata": null
   }
  },
  {
   "vulnerability": {
    "id": "CVE-2020-7791",
    "base-score": 7.5,
    "severity": "high"
   },
   "matchDetails": [
    {
     "matched-cpe": "cpe:/a:i18n_project:i18n:::~~~asp.net~~",
     "matched-version": "0.9.5",
     "matched-constraint": "< 2.1.15",
     "match-type": "Semantic"
    }
   ],
   "artifact": {
    "name": "i18n",
    "version": "0.9.5",
    "type": "gem",
    "locations": [
     {
      "path": "/usr/local/Homebrew/docs/Gemfile.lock"
     }
    ],
    "language": "ruby",
    "licenses": [],
    "cpes": [
     "cpe:2.3:a:ruby-lang:i18n:0.9.5:*:*:*:*:*:*:*",
     "cpe:2.3:a:ruby_lang:i18n:0.9.5:*:*:*:*:*:*:*",
     "cpe:2.3:a:i18n:i18n:0.9.5:*:*:*:*:*:*:*",
     "cpe:2.3:a:ruby:i18n:0.9.5:*:*:*:*:*:*:*",
     "cpe:2.3:a:*:i18n:0.9.5:*:*:*:*:*:*:*"
    ],
    "purl": "pkg:gem/i18n@0.9.5",
    "metadata": null
   }
  },
  {
   "vulnerability": {
    "id": "CVE-2020-7791",
    "base-score": 7.5,
    "severity": "high"
   },
   "matchDetails": [
    {
     "matched-cpe": "cpe:/a:i18n_project:i18n:::~~~asp.net~~",
     "matched-version": "1.8.11",
     "matched-constraint": "< 2.1.15",
     "match-type": "Semantic"
    }
   ],
   "artifact": {
    "name": "i18n",
    "version": "1.8.11",
    "type": "gem",
    "locations": [
     {
      "path": "/usr/local/Homebrew/Library/Homebrew/Gemfile.lock"
     }
    ],
    "language": "ruby",
    "licenses": [],
    "cpes": [
     "cpe:2.3:a:ruby-lang:i18n:1.8.11:*:*:*:*:*:*:*",
     "cpe:2.3:a:ruby_lang:i18n:1.8.11:*:*:*:*:*:*:*",
     "cpe:2.3:a:i18n:i18n:1.8.11:*:*:*:*:*:*:*",
     "cpe:2.3:a:ruby:i18n:1.8.11:*:*:*:*:*:*:*",
     "cpe:2.3:a:*:i18n:1.8.11:*:*:*:*:*:*:*"
    ],
    "purl": "pkg:gem/i18n@1.8.11",
    "metadata": null
   }
  },

 . . .

 ],
 "source": {
  "type": "anka image",
  "target": "/Users/nathanpierce/Library/Application Support/Veertu/Anka/img_lib/c2deedc229ae4e8b967aef0ddf4b2813.ank"
 }
}
```

### Ignoring Vulnerabilities

Using a custom config (`--config fileName.yml`), you can specify a list of CPEs to ignore.

{{< hint info >}}
You need to specify the "matched-cpe" or URI binding representation in the packages to ignore. Wildcards will not work.
{{< /hint >}}

```bash
❯ cat /tmp/customConfig.yml
ignore-packages:
  - "cpe:/a:i18n_project:i18n:::~~~asp.net~~"
  - "cpe:/a:python:python"
```

{{< hint info >}}
By default, if you don't specify a custom config, we automatically exclude `cpe:/a:apple:icloud:1.0` as there are several hundred vulnerabilities from it. You can use an empty custom config:

```yaml
ignore-packages:
 - ""
```
{{< /hint >}}

```bash
❯ docker run -it --rm -v "$(anka config img_lib_dir)/..:/mnt" -v "/tmp:/mnt/config" public.ecr.aws/veertu/anka-scan:0.2.1 ank_image:/mnt/img_lib/c2deedc229ae4e8b967aef0ddf4b2813.ank --report-format json --config /mnt/config/customConfig.yml --report-file /mnt/config/report_i18n_python.txt
 ✔ Indexed Data Volume      ✔ Cataloged packages      [220 packages]
 ✔ Indexed System Volume    ✔ Cataloged packages      [345 packages]
Report written to "/mnt/config/report_i18n_python.txt"
```

## Using the macOS binary

[Download the latest macOS package](https://veertu.com/downloads/anka-scan-macos-intel/)

The instructions for using the macOS package are identical in many ways to docker. The major differences are that the default `--storage-dir` for the binary is `/mnt` and likely not where your registry storage is located on macOS. You also of course do not include docker commands when executing the binary.

```bash
❯ ./_release/anka-scan --storage-dir "/Library/Application Support/Veertu/Anka/registry" registry_template:c12ccfa5-8757-411e-9505-128190e9854e 
 ✔ Indexed Data Volume     
 ✔ Cataloged packages      [222 packages]
 ✔ Indexed System Volume   
 ✔ Cataloged packages      [345 packages]

TYPE       NAME      VERSION   VULNERABILITY   SCORE  SEVERITY 
gem        i18n      0.9.5     CVE-2020-7791   7.5    high      
gem        i18n      1.8.11    CVE-2020-7791   7.5    high      
gem        parallel  1.21.0    CVE-2015-4155   3.6    low       
gem        parallel  1.21.0    CVE-2015-4156   3.6    low       
gem        webrick   1.7.0     CVE-2008-1145   5.0    medium    
macos-app  python    3.8.9     CVE-2021-29921  9.8    critical  
macos-app  python    2.7.18    CVE-2019-20907  7.5    high      
macos-app  python    2.7.18    CVE-2019-9674   7.5    high      
macos-app  python    2.7.18    CVE-2021-23336  5.9    medium    
macos-app  python    2.7.18    CVE-2015-5652   7.2    high      
macos-app  python    2.7.18    CVE-2017-17522  8.8    high      
macos-app  python    2.7.18    CVE-2017-18207  6.5    medium    
python     numpy     1.8.0rc1  CVE-2014-1858   5.5    medium    
python     numpy     1.8.0rc1  CVE-2014-1859   5.5    medium    
python     numpy     1.8.0rc1  CVE-2017-12852  7.5    high      
python     numpy     1.8.0rc1  CVE-2019-6446   9.8    critical  
python     numpy     1.8.0rc1  CVE-2021-41496  7.5    high      
python     numpy     1.8.0rc1  CVE-2021-41495  7.5    high      
python     numpy     1.8.0rc1  CVE-2021-34141  5.3    medium
```
