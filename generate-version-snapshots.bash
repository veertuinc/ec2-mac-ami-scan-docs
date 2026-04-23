#! /bin/bash
set -exo pipefail
PAGER=""
REGION="us-west-1"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Legacy automation for Hugo + Anka docs. The Docusaurus site uses docs/ in-repo; see https://docusaurus.io/docs/versioning
if [[ ! -f "$SCRIPT_DIR/config.toml" ]]; then
  echo "generate-version-snapshots.bash: config.toml not found (Hugo removed). Exiting."
  exit 0
fi
CURRENT_VERSION=$(grep "^version =" "$SCRIPT_DIR/config.toml" | head -n 1 | cut -d\" -f2)

function write_to_config() {
    TOML_LOCATION=$1
    if [[ -z "$(grep params.versions.\"$VERSIONS\" $TOML_LOCATION)" ]]; then
      # Deployment
      if [[ $(uname) == "Darwin" ]]; then
      sed -i '' "s/\[deployment\]/\[deployment\]\\
  \[\[deployment.targets\]\]\\
  name = \"$VERSIONS_NODOTS\"\\
  url = \"s3:\/\/docs-$URL_VERSIONS?region=$REGION\"/g" $TOML_LOCATION
      # Params
      sed -i '' "s/\[params\.versions\]/\[params\.versions\]\\
  \[params\.versions\.\"$VERSIONS_NODOTS\"\]\\
  version = \"$VERSIONS_NODOTS\"\\
  url = \"http:\/\/docs-${URL_VERSIONS}\.s3-website\.$REGION\.amazonaws\.com\"/g" $TOML_LOCATION
      # Convert back to dots
      sed -i '' "s/$VERSIONS_NODOTS/$(echo $VERSIONS_NODOTS | sed 's/\-/\./g')/g" $TOML_LOCATION
      
      else # Ubuntu sed doesn't do -i '' like Darwin does

      sed -i "s/\[deployment\]/\[deployment\]\\
  \[\[deployment.targets\]\]\\
  name = \"$VERSIONS_NODOTS\"\\
  url = \"s3:\/\/docs-$URL_VERSIONS?region=$REGION\"/g" $TOML_LOCATION
      # Params
      sed -i "s/\[\[params\.versions\]\]/\[\[params\.versions\]\]\\
  \[\[params\.versions\.\"$VERSIONS_NODOTS\"\]\]\\
  version = \"$VERSIONS_NODOTS\"\\
  url = \"http:\/\/docs-${URL_VERSIONS}\.s3-website\.$REGION\.amazonaws\.com\"/g" $TOML_LOCATION
      # Convert back to dots
      sed -i "s/$VERSIONS_NODOTS/$(echo $VERSIONS_NODOTS | sed 's/\-/\./g')/g" $TOML_LOCATION
    fi
  fi
}
for FULL_BRANCH in $(git branch -a | grep remotes/origin/release/v | grep -E -v "v1.6.0|v1.7.0|v1.8.0|v1.9.0|v1.10."); do
  BRANCH=$(echo $FULL_BRANCH | cut -d/ -f4)
  # Get config.toml & version
  CLONE_BRANCH=$(echo $FULL_BRANCH | cut -d/ -f3,4)
  TMP_STORAGE="/tmp/$BRANCH"
  [[ -d $TMP_STORAGE ]] && rm -rf $TMP_STORAGE
  mkdir -p $TMP_STORAGE
  cd $TMP_STORAGE
  git clone -n git@bitbucket.org:veertunew/anka-docs.git -b $CLONE_BRANCH --depth 1 .
  cd $TMP_STORAGE
  git checkout HEAD config.toml
  VERSIONS=$(grep "^version =" config.toml | head -n 1 | cut -d\" -f2)
  [[ $VERSIONS == $CURRENT_VERSION ]] && continue # Skip if the branch matches the current
  echo $VERSIONS
  CONTROLLER_VERSION="$(echo $VERSIONS | cut -d/ -f1)"
  ANKA_CLI_VERSION="$(echo $VERSIONS | cut -d/ -f2)"
  URL_VERSIONS="${CONTROLLER_VERSION}-and-${ANKA_CLI_VERSION}"
  echo "CONTROLLER_VERSION: $CONTROLLER_VERSION"
  echo "ANKA_CLI_VERSION: $ANKA_CLI_VERSION"
  VERSIONS_NODOTS=$(echo $VERSIONS | sed 's/\./-/g' | sed 's/\//\\\//g')
  # Clone the rest
  cd $TMP_STORAGE
  git pull --unshallow
  git checkout HEAD .
  npm install
  git submodule update --init --recursive --force
  # Create bucket
  BUCKET_NAME="docs-$URL_VERSIONS"
  if ! aws s3api get-bucket-website --bucket=$BUCKET_NAME; then
    aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION  --create-bucket-configuration LocationConstraint=$REGION
  POLICY=$(cat <<-EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${BUCKET_NAME}/*"
        }
    ]
}
EOM
)
    aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy "$POLICY"
    aws s3 website s3://$BUCKET_NAME/ --index-document index.html
    echo "$BUCKET_NAME.s3-website.$REGION.amazonaws.com"
  fi
  write_to_config ./config.toml
  # hugo -e production --minify --baseURL "http://docs-$URL_VERSIONS.s3-website.us-west-1.amazonaws.com/"
  # hugo deploy -v --target=$VERSIONS --maxDeletes -1

  # Add entries to master config.toml
  write_to_config $SCRIPT_DIR/config.toml

done
