git clone git@gitlab.com:seaside1/crypto-hunters-ar-game/crypto-hunters-ar-game.git
git clone git@gitlab.com:seaside1/crypto-hunters-ar-game/crypto-hunters-mobile-app.git

cd crypto-hunters-ar-game
git checkout refactor_integration_IOS
cd ..
cd crypto-hunters-mobile-app
git checkout current
yarn install
./node_modules/.bin/rn-nodeify --hack --install
mkdir -p unity/builds/ios
cd ..

/Applications/Unity/Unity.app/Contents/MacOS/Unity -batchmode -quit -projectPath crypto-hunters-ar-game -executeMethod BuildTools.AutoBuild.BuildProject
