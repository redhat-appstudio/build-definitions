#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

TEMPLATES=$SCRIPTDIR/build-templates-bundle
 
if [  -z "$MY_QUAY_USER" ]; then 
    echo "Set MY_QUAY_USER to use devmode"
    exit 1 
fi   
if [ "$MY_QUAY_USER" = "redhat-appstudio" ]; then
    echo "Cannot use devmode as redhat-appstudio user "
    exit 1  
fi
BUILD_TAG=$(date +"%Y-%m-%d-%H%M%S") 
BUNDLE=quay.io/$MY_QUAY_USER/build-templates-bundle:v$BUILD_TAG

# create a new bundle and install as default for this namespace
$SCRIPTDIR/util-package-bundle.sh $BUNDLE 
$SCRIPTDIR/util-install-bundle.sh $BUNDLE
   