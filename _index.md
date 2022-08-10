---
title: >
  Getting Started
type: "docs"
---

{{< include file="_partials/what-is/_short.md" >}}

```bash
sh-4.2$ ./ec2-mac-ami-scan

A vulnerability scanner for MacOS AMis.

Supported commands/types:
  ec2-mac-ami-scan ami-id	    		| Read and scan using an AWS AMI-ID

Usage:
  ec2-mac-ami-scan ami-id [flags]
  ec2-mac-ami-scan [command]

Available Commands:
  completion  Generate the autocompletion script for the specified shell
  help        Help about any command
  license     License show/activate
  version     Show the version

Flags:
  -c, --config string          application config file
  -u, --disable-db-update      disable updating scanner DB automatically
  -h, --help                   help for ec2-mac-ami-scan
  -i, --ignore-system-volume   do not scan the system volume (for anka VM)
  -l, --license-file string    license file path (default "scanner.lic")
      --min-score float32      don't show vulnerabilities with lesser score
      --min-severity string    don't show vulnerabilities with lesser severity
  -q, --quiet                  suppress all console output
  -o, --report-file string     write report to file
  -f, --report-format string   report output format, formats=[json table] (default "table")
  -p, --show-packages          do not scan and only show packages

Use "ec2-mac-ami-scan [command] --help" for more information about a command.
```

## Licensing

### How to License

1. [Obtain a trial or full license](https://veertu.com/ec2-mac-ami-scan-trial/)
2. Execute the license CLI to activate it:

    ```bash
    sh-4.2$ ./ec2-mac-ami-scan license
    License show/activate

    Usage:
      ec2-mac-ami-scan license [command]

    Available Commands:
      activate    Activate the license
      show        Show the license

    Flags:
      -h, --help   help for license

    Global Flags:
      -c, --config string         application config file
      -l, --license-file string   license file path (default "scanner.lic")

    Use "ec2-mac-ami-scan license [command] --help" for more information about a command.
    ```

    ```bash
    sh-4.2$ ./ec2-mac-ami-scan ami-0b117cb41d1dcb87f
    Error: failed to validate the license 'scanner.lic': No such file or directory
    ```

    ```bash
    sh-4.2$ ./ec2-mac-ami-scan license activate XXXX-XXXX-XXXX-XXXX
    Activated

    sh-4.2$ ./ec2-mac-ami-scan license show
    Product:          com.veertu.macami.scan
    Version:          1.0
    Expiration Date:  31-dec-2022
    ```

{{< hint info >}}
By default the `scanner.lic` file is created in the directory where you execute `license activate`. If you execute the scanner in a directory outside of the location with the `scanner.lic`, it will not see the file and fail. You can however set the path the scanner looks for the license file in by modifying the `config-example.yaml` and the `license-file: 'scanner.lic'` to a different location.
{{< /hint >}}

## Preparing an EC2 instance

- Create a **Linux** EC2 instance with a minimum of 1 CPU, 0.5GiB of RAM, and ~1GB of space for storage of the vulnerability database.

- In order to have the permissions necessary for mounting AMI volumes and scanning them, you can either:

    1. Create and attach an ec2 service policy to the instance and ensure it has the following permissions.
    2. Configure the instance with `sudo aws configure` (scanning requires and will run as root) through SSH using an Access key and secret for a user that has the following permissions.

        - ec2.DescribeVolumes
        - ec2.DescribeInstanceAttribute
        - ec2.CreateVolume
        - ec2.DeleteVolume
        - ec2.AttachVolume
        - ec2.DetachVolume
        - ec2.DescribeImages
        - ec2.CreateTags

## Usage

{{< hint warning >}}
**The scanner will not scan marketplace AMIs. You must have access to the AMI snapshot in the same region as your EC2 instance in order to scan it. You also cannot currently scan across regions. You can, however, deploy instances of EC2 Mac AMI Scanner in multiple regions.**
{{< /hint >}}

Currently, we provide a scanner binary for each linux distribution that has been requested by our customers. They are then archived into a tar.gz and available on our site or at https://downloads.veertu.com/#ec2-mac-ami-scan.

{{< hint info >}}
If you do not see your distro's binary, please reach out to support@veertu.com.
{{< /hint >}}

### Installation

1. [Download the latest Linux package.](https://veertu.com/downloads/ec2-mac-ami-scan/)
    ```bash
    FULL_FILE_NAME=$(echo $(curl -Ls -r 0-1 -o /dev/null -w %{url_effective} https://veertu.com/downloads/ec2-mac-ami-scan) | cut -d/ -f5)
    PARTIAL_FILE_NAME=$(echo $FULL_FILE_NAME | awk -F'.tar.gz' '{print $1}')
    mkdir -p $PARTIAL_FILE_NAME
    cd $PARTIAL_FILE_NAME
    curl -Ls https://veertu.com/downloads/ec2-mac-ami-scan -o $FULL_FILE_NAME
    tar -xzvf $FULL_FILE_NAME
    rm -f $FULL_FILE_NAME
    ```
2. Place the binary under /usr/local/bin (or just execute with `./` in-place).

### Features / Examples

The scanner is very simple. You can set the `ami-id` as your first argument and the scanner will find the snapshot, mount it as a volume, and then perform the scan inside of it.

```bash
sh-4.2$ sudo ./ec2-mac-ami-scan ami-07eec7bea34f42837
 ✔ Vulnerability DB Update [completed]
 ✔ Attaching an AMI        [attached vol-077126acd2775d6e1]
 ✔ Cataloged packages      [266 packages]
 ✔ Indexed Data Volume
 ✔ Cataloged packages      [335 packages]
 ✔ Indexed System Volume
 ✔ Detaching an AMI        [detached vol-077126acd2775d6e1]
 ✔ Analyzed packages       [138 vulnerabilities]
TYPE       NAME         VERSION   VULNERABILITY   SCORE  SEVERITY
brew       openssl@1.1  1.1.1o    CVE-2022-2068   10.0   critical
brew       openssl@1.1  1.1.1o    CVE-2022-2097   7.5    high
brew       python@3.9   3.9.12_1  CVE-2015-20107  10.0   critical
gem        bundler      1.17.2    CVE-2019-3881   7.8    high
gem        bundler      1.17.2    CVE-2020-36327  9.3    critical
gem        bundler      1.17.2    CVE-2021-43809  9.3    critical
gem        date         2.0.0     CVE-2012-1626   6.0    medium
gem        date         2.0.0     CVE-2021-41817  7.5    high  
. . .
```

#### Report Formats

By default the human readable table output does not include paths or other information about how the vulnerability was found. Fortunately, we allow you to produce verbose JSON output with that information.

{{< hint info >}}
The use of `--quiet` here is important to avoid any output which is not json parsable.
{{< /hint >}}

```bash
sh-4.2$ sudo ./ec2-mac-ami-scan ami-07eec7bea34f42837 --report-format json --quiet
{
 "matches": [
  {
   "vulnerability": {
    "id": "CVE-2019-3881",
    "base-score": 7.8,
    "severity": "high",
    "url": "https://nvd.nist.gov/vuln/detail/CVE-2019-3881"
   },
   "matchDetails": [
    {
     "matched-cpe": "cpe:/a:bundler:bundler:::~~~ruby~~",
     "matched-version": "1.17.2",
     "matched-constraint": "< 2.1.0",
     "match-type": "Semantic"
    }
   ],
   "artifact": {
    "name": "bundler",
    "version": "1.17.2",
    "type": "gem",
    "locations": [
     {
      "path": "/Library/Ruby/Gems/2.6.0/specifications/default/bundler-1.17.2.gemspec"
     }
    ],
    "language": "ruby",
    "licenses": [
     "MIT"
    ],
    "cpes": [
     "cpe:2.3:a:jessica-lynn-suttles:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:jessica_lynn_suttles:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:david-rodr\\\ufffd\\\ufffdguez:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:andr\\\ufffd\\\ufffd-medeiros:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:david_rodr\\\ufffd\\\ufffdguez:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:stephanie-morillo:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:andr\\\ufffd\\\ufffd_medeiros:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:stephanie_morillo:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:hiroshi-shibata:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:colby-swandale:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:hiroshi_shibata:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:samuel-giddins:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:andr\\\ufffd\\\ufffd-arko:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:colby_swandale:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:samuel_giddins:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:andr\\\ufffd\\\ufffd_arko:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:chris-morris:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:carl-lerche:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:chris_morris:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:terence-lee:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:yehuda-katz:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:carl_lerche:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:grey-baker:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:terence_lee:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:yehuda_katz:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:grey_baker:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:james-wen:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:ruby-lang:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:tim-moore:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:james_wen:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:ruby_lang:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:tim_moore:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:bundler:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:ruby:bundler:1.17.2:*:*:*:*:*:*:*",
     "cpe:2.3:a:*:bundler:1.17.2:*:*:*:*:*:*:*"
    ],
    "purl": "pkg:gem/bundler@1.17.2",
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
sh-4.2$ sudo ./ec2-mac-ami-scan ami-07eec7bea34f42837 --report-format json --config /tmp/customConfig.yaml --report-file /tmp/report_i18n_python.json
 ✔ Vulnerability DB Update [completed]
 ✔ Attaching an AMI        [attached vol-0e25f5c07490615a4]
 ✔ Cataloged packages      [266 packages]
 ✔ Indexed Data Volume
 ✔ Cataloged packages      [335 packages]
 ✔ Indexed System Volume
 ✔ Detaching an AMI        [detached vol-0e25f5c07490615a4]
 ✔ Analyzed packages       [357 vulnerabilities]
Report written to "/tmp/report_i18n_python.json"
```
