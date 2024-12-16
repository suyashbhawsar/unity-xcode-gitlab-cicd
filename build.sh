#!/bin/bash

#git clone git@gitlab.com:seaside1/crypto-hunters-ar-game/crypto-hunters-mobile-app.git
#git clone git@gitlab.com:seaside1/crypto-hunters-ar-game/crypto-hunters-ar-game.git

cd crypto-hunters-ar-game
git checkout refactor_integration_IOS
mkdir -p Assets/Editor
cd ..
cd crypto-hunters-mobile-app
git checkout current
yarn install
./node_modules/.bin/rn-nodeify --hack --install
mkdir -p unity/builds/ios
cd ..

wget -O crypto-hunters-ar-game/Assets/Editor/AutoBuild.cs https://raw.githubusercontent.com/suyashbhawsar/unity-xcode-gitlab-cicd/refs/heads/main/AutoBuild.cs
/Applications/Unity/Unity.app/Contents/MacOS/Unity -batchmode -quit -projectPath crypto-hunters-ar-game -executeMethod BuildTools.AutoBuild.BuildProject

wget https://raw.githubusercontent.com/suyashbhawsar/unity-xcode-gitlab-cicd/refs/heads/main/modify_xcode_project.rb
ruby modify_xcode_project.rb
