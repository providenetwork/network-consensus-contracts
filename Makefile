.PHONY: clean compile flat solhint test

clean:
	rm -rf build/
	rm -rf flat/
	rm -rf tmp/

compile: clean
	node_modules/.bin/truffle compile

flat: clean
	mkdir flat
	mkdir tmp

	cp contracts/*.sol tmp/
	cp contracts/lib/*.sol tmp/
	cp contracts/lib/aura/contracts/*.sol tmp/
	cp contracts/lib/aura/contracts/classes/validators/* tmp/
	cp contracts/lib/aura/contracts/classes/voting/* tmp/
	cp contracts/lib/bridges/contracts/*.sol tmp/
	cp contracts/lib/bridges/contracts/classes/* tmp/

	rm tmp/Migrations.sol

	sed -i '' -e "s/\(import \)\(.*\)\/\(.*\).sol/import '.\/\3.sol/g" tmp/*
	node_modules/.bin/truffle-flattener tmp/* | sed "1s/.*/pragma solidity ^0.4.23;/" > flat/Network.sol

solhint:
	solhint contracts/*.sol contracts/util/*.sol

test:
	node_modules/.bin/truffle test --network test
