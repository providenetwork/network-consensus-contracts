.PHONY: flatten merge solhint test testrpc travis_test

flatten:
	#pip3 install solidity-flattener --no-cache-dir -U
	rm -rf flat/ && mkdir flat
	rm -fr tmp
	mkdir tmp

	cp contracts/*.sol tmp/
	cp contracts/interfaces/* tmp/
	cp contracts/lib/* tmp/
	cp contracts/network/* tmp/
	cp contracts/storage/* tmp/

	sed -i '' -e "s/\(import \)\(.*\)\/\(.*\).sol/import '.\/\3.sol/g" tmp/*
	solidity_flattener tmp/KeyManager.sol | sed "1s/.*/pragma solidity ^0.4.20;/" > flat/KeyManager_flat.sol
	solidity_flattener tmp/NetworkConsensus.sol | sed "1s/.*/pragma solidity ^0.4.20;/" > flat/NetworkConsensus_flat.sol

merge:
	node_modules/.bin/sol-merger "src/*.sol" build

solhint:
	solhint contracts/*.sol contracts/util/*.sol

test:
	node_modules/.bin/truffle test --network test

testganache:
	node_modules/.bin/truffle test --network ganache

testrpc:
	node_modules/.bin/testrpc -p 8544

travis_test:
	nohup make testrpc &
	make test
