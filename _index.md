---
title: >
  Getting Started
type: "docs"
---

{{< include file="_partials/what-is/_short.md" >}}

```bash
[ec2-user@ip-172-31-52-78 ~]$ ./ami-scanner_amazonlinux_amd64 --help

A vulnerability scanner for MacOS AMis.

Supported commands/types:
  ami-scanner_amazonlinux_amd64 ami-id	    		| Read and scan using an AWS AMI-ID

Usage:
  ami-scanner_amazonlinux_amd64 ami-id [flags]
  ami-scanner_amazonlinux_amd64 [command]

Available Commands:
  completion  Generate the autocompletion script for the specified shell
  help        Help about any command
  license     License show/activate
  version     Show the version

Flags:
  -c, --config string          application config file
  -u, --disable-db-update      disable updating scanner DB automatically
  -h, --help                   help for ami-scanner_amazonlinux_amd64
  -i, --ignore-system-volume   do not scan the system volume (for anka VM)
  -l, --license-file string    license file path (default "scanner.lic")
      --min-score float32      don't show vulnerabilities with lesser score
      --min-severity string    don't show vulnerabilities with lesser severity
  -q, --quiet                  suppress all console output
  -o, --report-file string     write report to file
  -f, --report-format string   report output format, formats=[json table] (default "table")
  -p, --show-packages          do not scan and only show packages

Use "ami-scanner_amazonlinux_amd64 [command] --help" for more information about a command.
```

## Licensing

### How to License

1. [Obtain a trial or full license](https://veertu.com/ami-scanner-trial/)
2. Execute the license CLI to activate it:

    ```bash
    [ec2-user@ip-172-31-52-78 ~]$ sudo ./ami-scanner_amazonlinux_amd64 license
    License show/activate

    Usage:
      ami-scanner_amazonlinux_amd64 license [command]

    Available Commands:
      activate    Activate the license
      show        Show the license

    Flags:
      -h, --help   help for license

    Global Flags:
      -c, --config string         application config file
      -l, --license-file string   license file path (default "scanner.lic")

    Use "ami-scanner_amazonlinux_amd64 license [command] --help" for more information about a command.
    ```

    ```bash
    [ec2-user@ip-172-31-52-78 ~]$ sudo ./ami-scanner_amazonlinux_amd64 ami-0bc85a735fb855603
    Error: failed to validate the license 'scanner.lic': No such file or directory

    [ec2-user@ip-172-31-52-78 ~]$ ./ami-scanner_amazonlinux_amd64 license activate XXXX-XXXX-XXXX-XXXX
    Activated

    [ec2-user@ip-172-31-52-78 ~]$ sudo ./ami-scanner_amazonlinux_amd64 license show
    Product:          com.veertu.macami.scan
    Version:          1.0
    Expiration Date:  31-dec-2022
    ```

{{< hint info >}}
By default the `scanner.lic` file is created in the directory where you execute `license activate`. If you execute the scanner in a directory outside of the location with the `scanner.lic`, it will not see the file and fail. You can however set the path the scanner looks for the license file in by modifying the `config-example.yaml` and the `license-file: 'scanner.lic'` to a different location.
{{< /hint >}}

## Preparing IAM

1. [Create a custom policy with the following permissions:](https://us-east-1.console.aws.amazon.com/iamv2/home#/policies)
    - ec2.DescribeVolumes
    - ec2.DescribeInstanceAttribute
    - ec2.CreateVolume
    - ec2.DeleteVolume
    - ec2.AttachVolume
    - ec2.DetachVolume
    - ec2.DescribeImages
    - ec2.CreateTags

2. [Create an **EC2 SERVICE** role](https://us-east-1.console.aws.amazon.com/iamv2/home#/roles) and attach the policy you created above.

## Preparing an EC2 instance

1. Create an EC2 instance with a minimum of 1 CPU, 0.5GiB of RAM, and ~1GB of space for storage of the vulnerability database.

2. Attach the IAM role to your instance (if it doesn't show, it's not an EC2 service role).

## Using the AMI Scanner

{{< hint warning >}}
**You must have access to the AMI snapshot in the same region as your EC2 instance in order to scan it. You cannot currently scan across regions.**
{{< /hint >}}

Currently, we provide a scanner binary for each linux distribution that has been requested by our customers. They are then archived into a tar.gz and available on our site or at https://downloads.veertu.com/#ami-scanner.

{{< hint info >}}
If you do not see your distro binary, please reach out to support@veertu.com.
{{< /hint >}}/

### Installation

1. [Download the latest Linux package.](https://veertu.com/downloads/ami-scanner-linux/)
    ```bash
    FULL_FILE_NAME=$(echo $(curl -Ls -r 0-1 -o /dev/null -w %{url_effective} https://veertu.com/downloads/ami-scanner-linux) | cut -d/ -f5)
    PARTIAL_FILE_NAME=$(echo $FULL_FILE_NAME | awk -F'.tar.gz' '{print $1}')
    mkdir -p $PARTIAL_FILE_NAME
    cd $PARTIAL_FILE_NAME
    curl -Ls https://veertu.com/downloads/ami-scanner-linux -o $FULL_FILE_NAME
    tar -xzvf $FULL_FILE_NAME
    rm -f $FULL_FILE_NAME
    ```
2. Place the binary under /usr/local/bin (or just execute with `./` in-place).

### Features / Examples

The scanner is very simple. You can set the `ami-id` as your first argument and the scanner will find the snapshot, mount it as a volume, and then perform the scan inside of it.

```bash
[ec2-user@ip-172-31-52-78 ~]$ sudo ./ami-scanner_amazonlinux_amd64 ami-0bc85a735fb855603
 ✔ Vulnerability DB Update [completed]
 ✔ Attaching an AMI        [attached vol-08e9b4d06bfe92e0c]
 ✔ Cataloged packages      [274 packages]
 ✔ Indexed Data Volume     
 ✔ Cataloged packages      [332 packages]
 ✔ Indexed System Volume   
 ✔ Detaching an AMI        [detached vol-08e9b4d06bfe92e0c]
 ✔ Analyzed packages       [122 vulnerabilities]
TYPE       NAME          VERSION   VULNERABILITY   SCORE  SEVERITY 
brew       openssl@1.1   1.1.1k    CVE-2021-3711   9.8    critical  
brew       openssl@1.1   1.1.1k    CVE-2021-3712   7.4    high      
brew       openssl@1.1   1.1.1k    CVE-2021-4160   5.9    medium    
brew       openssl@1.1   1.1.1k    CVE-2022-0778   7.5    high      
brew       openssl@1.1   1.1.1k    CVE-2022-1292   10.0   critical  
brew       python@3.9    3.9.6     CVE-2015-20107  10.0   critical  
brew       python@3.9    3.9.6     CVE-2019-12900  9.8    critical  
brew       python@3.9    3.9.6     CVE-2022-26488  7.0    high      
gem        i18n          0.9.5     CVE-2020-7791   7.5    high      
. . .
```

#### Report Formats

By default the human readable table output does not include paths or other information about how the vulnerability was found. Fortunately, we allow you to produce verbose JSON output with that information.

{{< hint info >}}
The use of `--quiet` here is important to avoid any output which is not json parsable.
{{< /hint >}}

```bash
[ec2-user@ip-172-31-52-78 ~]$ sudo ./ami-scanner_amazonlinux_amd64 ami-0bc85a735fb855603 --report-format json --quiet
{
 "matches": [
  {
   "vulnerability": {
    "id": "CVE-2020-7791",
    "base-score": 7.5,
    "severity": "high",
    "url": "https://nvd.nist.gov/vuln/detail/CVE-2020-7791"
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
. . .
```

#### Ignoring Vulnerabilities

Using a custom config (`--config customConfig.yaml`), you can specify a list of CPEs to ignore.

{{< hint info >}}
You need to specify the "matched-cpe" or URI binding representation in the packages to ignore. Wildcards will not work.
{{< /hint >}}

```bash
❯ cat /tmp/customConfig.yaml
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

Or, you can ignore specific CVEs:

```bash
❯ cat /tmp/customConfig.yml
ignore-cves:
  - "CVE-2020-7791"
```

```bash
[ec2-user@ip-172-31-52-78 ~]$ sudo ./ami-scanner_amazonlinux_amd64 ami-0bc85a735fb855603 --report-format json --config /tmp/customConfig.yaml --report-file /tmp/report_i18n_python.json
 ✔ Vulnerability DB Update [completed]
 ✔ Attaching an AMI        [attached vol-05fee845685723d5c]
 ✔ Cataloged packages      [274 packages]
 ✔ Indexed Data Volume     
 ✔ Cataloged packages      [332 packages]
 ✔ Indexed System Volume   
 ✔ Detaching an AMI        [detached vol-05fee845685723d5c]
 ✔ Analyzed packages       [118 vulnerabilities]

Report written to "/tmp/report_i18n_python.json"
```
