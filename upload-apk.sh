#!/bin/sh
set -e

export PUBLISH_BRANCH=${PUBLISH_BRANCH:-master}
export DEVELOPMENT_BRANCH=${DEVELOPMENT_BRANCH:-travischeck}

#setup git
git config --global user.email "noreply@travis.com"
git config --global user.name "Travis CI" 
echo "How git looks like branch -vv ....................."
git branch -vv
echo "How git looks like remote -v....................."
git remote -v
#clone the repository into a folder named apk
git clone --quiet --branch=apk https://CloudyPadmal:$GITHUB_API_KEY@github.com/CloudyPadmal/travispslabandroid apk > /dev/null
echo "How outside folder looks like ....................."
ls -l
echo "Going into apk folder ....................."
cd apk
echo "How apk folder looks like ....................."
ls -l
echo "Copying build files into apk folder ....................."
\cp -r ../app/build/outputs/apk/*/**.apk .
\cp -r ../app/build/outputs/apk/debug/output.json debug-output.json
\cp -r ../app/build/outputs/apk/release/output.json release-output.json
\cp -r ../README.md .
echo "Current remotes are ....................."
git remote -v

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
    echo "Push to travischeck branch detected ..."
    echo "This is how the folder looks now ................................"
    ls -l
    mv app-debug.apk app-debug-devel.apk
    echo "This is how the folder looks after ................................"
    ls -la
    # Checkout to branch
    git checkout apk
    git add -A
    # Commit APK
    git commit -am "[Auto] Update Test Apk ($(date +%Y-%m-%d.%H:%M:%S))"
    # Delete the existing apk branch
    #git branch -D apk
    # Move orphan branch stuff to new apk branch
    #git branch -m apk
    #git config user.name "CloudyPadmal" 
    git push origin apk --force --quiet> /dev/null
fi

