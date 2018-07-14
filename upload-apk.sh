#!/bin/sh
set -e

export PUBLISH_BRANCH=${PUBLISH_BRANCH:-master}
export DEVELOPMENT_BRANCH=${DEVELOPMENT_BRANCH:-development}

#setup git
git config --global user.email "noreply@travis.com"
git config --global user.name "Travis CI" 

#clone the repository
git clone --quiet --branch=apk https://fossasia:$GITHUB_API_KEY@github.com/fossasia/pslab-android apk > /dev/null

cd apk

\cp -r ../app/build/outputs/apk/*/**.apk .
\cp -r ../app/build/outputs/apk/debug/output.json debug-output.json
\cp -r ../app/build/outputs/apk/release/output.json release-output.json
\cp -r ../README.md .

# Signing Apps
echo "------------------"
echo $PUBLISH_BRANCH
echo $DEVELOPMENT_BRANCH
echo "Editing remotes"
git remote add padmals https://github.com/CloudyPadmal/travispslabandroid.git
echo "Travis Branch"
echo $TRAVIS_BRANCH
echo "Git branches"
git branch -vv
echo "Git remotes"
git remote -v
echo "-------------------"

if [ "$TRAVIS_BRANCH" == "$PUBLISH_BRANCH" ]; then
    echo "Push to master branch detected, signing the app..."
    cp app-release-unsigned.apk app-release-unaligned.apk
	jarsigner -tsa http://timestamp.comodoca.com/rfc3161 -sigalg SHA1withRSA -digestalg SHA1 -keystore ../scripts/key.jks -storepass $STORE_PASS -keypass $KEY_PASS app-release-unaligned.apk $ALIAS
	\rm -f app-release.apk
	${ANDROID_HOME}/build-tools/27.0.3/zipalign -v -p 4 app-release-unaligned.apk app-release.apk
fi

git checkout --orphan workaround
git add -A

#commit

git commit -am "Travis build pushed [skip ci]"

git branch -D apk
git branch -m apk

#push to the branch apk
git push padmals apk --force --quiet> /dev/null

# Publish App to Play Store
if [ "$TRAVIS_BRANCH" != "$PUBLISH_BRANCH" ]; then
    echo "We publish apk only for changes in master branch. So, let's skip this shall we ? :)"
    exit 0
fi
