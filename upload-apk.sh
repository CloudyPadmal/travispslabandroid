#!/bin/sh
set -e

export PUBLISH_BRANCH=${PUBLISH_BRANCH:-master}
export DEVELOPMENT_BRANCH=${DEVELOPMENT_BRANCH:-bb2}

#setup git
git config --global user.email "noreply@travis.com"
git config --global user.name "Travis CI" 

#clone the repository into a folder named apk
git clone --quiet --branch=apk https://CloudyPadmal:$GITHUB_API_KEY@github.com/fossasia/pslab-android apk > /dev/null

cd apk

echo "PR is ..."
echo $TRAVIS_PULL_REQUEST

\cp -r ../app/build/outputs/apk/*/**.apk .
\cp -r ../app/build/outputs/apk/debug/output.json debug-output.json
\cp -r ../app/build/outputs/apk/release/output.json release-output.json
\cp -r ../README.md .

# Signing Apps
git remote add padmals https://github.com/CloudyPadmal/travispslabandroid.git
echo "-------------------"

if [ "$TRAVIS_BRANCH" == "$PUBLISH_BRANCH" ]; then
    echo "Push to master branch detected, signing the app..."
    mv app-debug.apk app-debug-master.apk
    cp app-release-unsigned.apk app-release-unaligned.apk
    jarsigner -tsa http://timestamp.comodoca.com/rfc3161 -sigalg SHA1withRSA -digestalg SHA1 -keystore ../scripts/key.jks -storepass $STORE_PASS -keypass $KEY_PASS app-release-unaligned.apk $ALIAS
    \rm -f app-release.apk
    ${ANDROID_HOME}/build-tools/27.0.3/zipalign -v -p 4 app-release-unaligned.apk app-release.apk
    git checkout --orphan workaround
    git add -A
    #commit
    git commit -am "Travis build pushed to master [skip ci]"
    git branch -D apk
    git branch -m apk
    #push to the branch apk
    git push padmals apk --force --quiet> /dev/null
fi

if [ "$TRAVIS_BRANCH" == "$DEVELOPMENT_BRANCH" ]; then
    echo "Push to development branch detected ..."
    mv app-debug.apk app-debug-devel.apk
    cp app-debug-devel.apk app-debug-${TRAVIS_PULL_REQUEST}.apk
    ls -la
    # Checkout to branch
    git checkout --orphan workaround
    git add -A
    # Commit APK
    git commit -am "Travis build pushed to development [skip ci]"
    
    # Delete the existing apk branch
    git branch -D apk
    # Move orphan branch stuff to new apk branch
    git branch -m apk
    git config user.name "CloudyPadmal" 
    git push padmals apk --force --quiet> /dev/null
fi

