import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const productionUrl = 'https://docs.veertu.com';

const config: Config = {
  title: "Veertu's AWS EC2 Mac AMI Scan Documentation",
  tagline: 'Documentation for Veertu AWS EC2 Mac AMI Scan',
  favicon: 'img/favicon.ico',

  future: {
    v4: true,
  },

  url: process.env.DOCUSAURUS_URL ?? productionUrl,
  baseUrl: '/ec2-mac-ami-scan/',
  trailingSlash: false,

  organizationName: 'veertuinc',
  projectName: 'ec2-mac-ami-scan-docs',

  onBrokenLinks: 'throw',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          routeBasePath: '/',
          sidebarPath: './sidebars.ts',
          editUrl:
            'https://github.com/veertuinc/ec2-mac-ami-scan-docs/edit/main/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    image: 'img/docusaurus-social-card.jpg',
    colorMode: {
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'EC2 Mac AMI Scan',
      logo: {
        alt: 'Veertu',
        src: 'img/logo.svg',
      },
      items: [
        {
          href: 'https://veertu.com/downloads/ec2-mac-ami-scan-linux',
          label: 'Download',
          position: 'right',
        },
        {
          href: 'https://github.com/veertuinc/ec2-mac-ami-scan-docs',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Veertu',
          items: [
            {
              label: 'Downloads',
              href: 'https://veertu.com/downloads/ec2-mac-ami-scan-linux',
            },
            {
              label: 'Trial license',
              href: 'https://veertu.com/ec2-mac-ami-scan-trial/',
            },
            {
              label: 'Email support',
              href: 'mailto:support@veertu.com',
            },
          ],
        },
        {
          title: 'Community',
          items: [
            {
              label: 'Twitter',
              href: 'https://twitter.com/veertu_labs',
            },
            {
              label: 'Slack',
              href: 'https://slack.veertu.com/',
            },
            {
              label: 'GitHub',
              href: 'https://github.com/veertuinc/ec2-mac-ami-scan-docs',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Veertu, Inc.`,
    },
    prism: {
      theme: prismThemes.oneLight,
      darkTheme: prismThemes.oneDark,
    },
  } satisfies Preset.ThemeConfig,

  customFields: {
    /** Product version shown in docs; keep in sync with release notes. */
    docVersion: '2.0.0',
  },
};

export default config;
