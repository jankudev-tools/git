#!/bin/bash

# parsing parameters
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -o|--origin)
      OLD_ORIGIN="$2";
      shift;;

    -n|--new)
      NEW_ORIGIN="$2";
      shift;;

    -t|--temp)
      TEMP="$2";
      shift;;

    -q|--quiet)
      QUIET=1;;

    *)
      echo "Usage: migrate.sh -o URL -n NEW [-t DIR] [-q]           ";
      echo "--------------------------------------------------------";
      echo "URL_ORIGI    url to the origin git repo to be migrated  ";
      echo "-t, --temp    temporary directory to save git mirr      ";
      echo "-q, --quiet   perform without breaking, asking, etc.    ";
      exit 1;;
  esac;
  shift;
done

# if temp not given, generate one
TEMP=`mktemp -d`

# cleanup
function fn_cleanup {
  rm -rf "${TEMP}" 
}
trap fn_cleanup EXIT

# perform the migration
# clone everything
git clone --mirror "${OLD_ORIGIN}" "${TEMP}"

# make sure mirror cloned
PROJECT_DIR=`ls ${TEMP}`
if [[ -z "${PROJECT_DIR}" ]]; then
  echo "Cloning unsuccessful of ${OLD_ORIGIN} into ${TEMP}" >&2
  exit -1
fi

# change dir to mirror
pushd "${TEMP}"

# list everything if not quiet
if [[ "1" != "${QUIET}" ]]; then
  echo "Tags in repo:"
  git tag
  echo ""
  echo "Branches in repo:"
  git branch -a
  echo ""
  read -p "Proceed with migration? [Y]/[n]:" CONFIRMATION
  if [[ "Y" != "${CONFIRMATION}" ]]; then
    echo "Migration canceled"
    exit 0
  fi
fi

# changing origin
git remote rm origin
git remote add origin "${NEW_ORIGIN}"

# push everything
git push origin --all
git push --tags

# done message
echo "Migration from ${OLD_ORIGIN} to ${NEW_ORIGIN} successful"
