let KeyManager = artifacts.require('./mock/KeyManagerMock')
let NetworkConsensusMock = artifacts.require('./mock/NetworkConsensusMock');
let NetworkStorageMock = artifacts.require('./mock/NetworkStorageMock');

contract('KeyManager', function (accounts) {
    let keyManager, networkStorage, networkConsensus
    let masterOfCeremony = accounts[0]

    beforeEach(async () => {
        networkStorage = await NetworkStorageMock.new();
        networkConsensus = await NetworkConsensusMock.new(networkStorage.address, masterOfCeremony);
        keyManager = await KeyManager.new(networkConsensus.address, '0x0000000000000000000000000000000000000000');
        await networkConsensus.initKeyManager(keyManager.address);

        await keyManager.setVotingContractMock(accounts[0])  // FIXME? -- this sets default behavior of this test suite to execute from the context of an abstract voting contract
    })

    describe('initialization', async () => {
        it('should configure the max initial validators', async () => {
            let maxNumberOfInitialKeys = await keyManager.getMaxInitialValidators();
            maxNumberOfInitialKeys.toNumber(10).should.be.eq(12);
        })

        it('should configure the max total validators', async () => {
            let maxTotalValidators = await keyManager.getMaxTotalValidators();
            maxTotalValidators.toNumber(10).should.be.eq(200);
        })

        it('should initialize keys for the master of ceremony', async () => {
            let validator = await keyManager.unmarshalValidatorKeysMock(masterOfCeremony);
            validator.should.be.deep.equal(['0x0000000000000000000000000000000000000000', '0x0000000000000000000000000000000000000000', true, false, false])
        })
    })

    describe('#initiateKeys', async () => {
        it('should allow the master of ceremony to initialize keys for validators', async () => {
            await keyManager.initiateKeys(accounts[2], { from: masterOfCeremony }).should.be.fulfilled;
            await keyManager.initiateKeys(accounts[2], { from: accounts[1] }).should.be.rejectedWith(exports.EVM_ERR_REVERT);
        })

        it('should not allow 0x0 addresses', async () => {
            await keyManager.initiateKeys('0x0000000000000000000000000000000000000000').should.be.rejectedWith(exports.EVM_ERR_REVERT);
            await keyManager.initiateKeys('0x0').should.be.rejectedWith(exports.EVM_ERR_REVERT);
        })

        it('should not allow to initialize already initialized key', async () => {
            await keyManager.initiateKeys(accounts[2], { from: masterOfCeremony }).should.be.fulfilled;
            await keyManager.initiateKeys(accounts[2], { from: masterOfCeremony }).should.be.rejectedWith(exports.EVM_ERR_REVERT);
        })

        it('should not allow to initialize already initialized key after validator created mining key', async () => {
            await keyManager.initiateKeys(accounts[2], { from: masterOfCeremony }).should.be.fulfilled;
            await keyManager.createKeys(accounts[3], accounts[4], accounts[5], { from: accounts[2] }).should.be.fulfilled;
            await keyManager.initiateKeys(accounts[2], { from: masterOfCeremony }).should.be.rejectedWith(exports.EVM_ERR_REVERT);
        })

        it('should not allow an initial key to be created for the master of ceremony address', async () => {
            await keyManager.initiateKeys(masterOfCeremony, { from: masterOfCeremony }).should.be.rejectedWith(exports.EVM_ERR_REVERT);
        })

        it('should not allow to initialize more than the max initial validators', async () => {
            let maxNumberOfInitialKeys = await keyManager.getMaxInitialValidators();
            maxNumberOfInitialKeys.should.be.bignumber.equal(12);
            await keyManager.initiateKeys('0x0000000000000000000000000000000000000001', { from: masterOfCeremony }).should.be.fulfilled;
            await keyManager.initiateKeys('0x0000000000000000000000000000000000000002', { from: masterOfCeremony }).should.be.fulfilled;
            await keyManager.initiateKeys('0x0000000000000000000000000000000000000003', { from: masterOfCeremony }).should.be.fulfilled;
            await keyManager.initiateKeys('0x0000000000000000000000000000000000000004', { from: masterOfCeremony }).should.be.fulfilled;
            await keyManager.initiateKeys('0x0000000000000000000000000000000000000005', { from: masterOfCeremony }).should.be.fulfilled;
            await keyManager.initiateKeys('0x0000000000000000000000000000000000000006', { from: masterOfCeremony }).should.be.fulfilled;
            await keyManager.initiateKeys('0x0000000000000000000000000000000000000007', { from: masterOfCeremony }).should.be.fulfilled;
            await keyManager.initiateKeys('0x0000000000000000000000000000000000000008', { from: masterOfCeremony }).should.be.fulfilled;
            await keyManager.initiateKeys('0x0000000000000000000000000000000000000009', { from: masterOfCeremony }).should.be.fulfilled;
            await keyManager.initiateKeys('0x0000000000000000000000000000000000000010', { from: masterOfCeremony }).should.be.fulfilled;
            await keyManager.initiateKeys('0x0000000000000000000000000000000000000011', { from: masterOfCeremony }).should.be.fulfilled;
            await keyManager.initiateKeys('0x0000000000000000000000000000000000000012', { from: masterOfCeremony }).should.be.fulfilled;
            await keyManager.initiateKeys('0x0000000000000000000000000000000000000013', { from: masterOfCeremony }).should.be.rejectedWith(exports.EVM_ERR_REVERT);
        })

        it('should increment the initial keys count', async () => {
            let initialKeysCount = await keyManager.getInitialKeyCount();
            initialKeysCount.should.be.bignumber.equal(0);
            await keyManager.initiateKeys(accounts[1], { from: masterOfCeremony }).should.be.fulfilled;
            initialKeysCount = await keyManager.getInitialKeyCount();
            initialKeysCount.should.be.bignumber.equal(1);
        })

        it('should mark the initial key status as activated', async () => {
            new web3.BigNumber(0).should.be.bignumber.equal(await keyManager.getInitialKey(accounts[1]));
            let { logs } = await keyManager.initiateKeys(accounts[1], { from: masterOfCeremony }).should.be.fulfilled;
            new web3.BigNumber(1).should.be.bignumber.equal(await keyManager.getInitialKey(accounts[1]));
            let initialKeysCount = await keyManager.getInitialKeyCount();
            // event InitialKeyCreated(address indexed initialKey, uint256 time, uint256 initialKeysCount);
            logs[0].event.should.equal("InitialKeyCreated");
            logs[0].args.initialKey.should.be.equal(accounts[1]);
            initialKeysCount.should.be.bignumber.equal(logs[0].args.initialKeysCount);
        })
    });

    describe('#createKeys', async () => {
        context('when the initial key has not been activated', async () => {
            it('should reject the attempt to associate mining, payout and voting keys with the initial key', async () => {
                await keyManager.createKeys(accounts[2], accounts[3], accounts[4], { from: accounts[1] }).should.be.rejectedWith(exports.EVM_ERR_REVERT);
            });
        })

        context('when the initial key has been marked as activated', async () => {
            beforeEach(async () => {
                await keyManager.initiateKeys(accounts[1], { from: masterOfCeremony }).should.be.fulfilled;
                await keyManager.initiateKeys(accounts[2], { from: masterOfCeremony }).should.be.fulfilled;
            })

            context('when the given mining, payout or voting key is identical to the initial key', async () => {
                it('should reject the attempt to associate mining, payout and voting keys with the initial key', async () => {
                    await keyManager.createKeys(accounts[2], accounts[1], accounts[3], { from: accounts[2] }).should.be.rejectedWith(exports.EVM_ERR_REVERT);
                    await keyManager.createKeys(accounts[1], accounts[2], accounts[3], { from: accounts[2] }).should.be.rejectedWith(exports.EVM_ERR_REVERT);
                    await keyManager.createKeys(masterOfCeremony, accounts[3], accounts[2], { from: accounts[2] }).should.be.rejectedWith(exports.EVM_ERR_REVERT);
                });
            })

            context('when the given mining, payout or voting keys contain an duplicate key', async () => {
                it('should reject the attempt to associate mining, payout and voting keys with the initial key', async () => {
                    await keyManager.createKeys(accounts[2], accounts[3], accounts[3], { from: accounts[2] }).should.be.rejectedWith(exports.EVM_ERR_REVERT);
                    await keyManager.createKeys(accounts[2], accounts[3], accounts[2], { from: accounts[2] }).should.be.rejectedWith(exports.EVM_ERR_REVERT);
                    await keyManager.createKeys(accounts[2], accounts[2], accounts[3], { from: accounts[2] }).should.be.rejectedWith(exports.EVM_ERR_REVERT);
                });
            })

            context('when the given mining, payout and voting keys are unique and valid', async () => {
                let log0

                beforeEach(async () => {
                    let { logs } = await keyManager.createKeys(accounts[3], accounts[4], accounts[5], { from: accounts[2] }).should.be.fulfilled;
                    log0 = logs[0]
                })

                it('should associate the given mining, payout, and voting keys with the activated initial key', async () => {
                    true.should.be.equal(await keyManager.isMiningActive(accounts[3]))
                    true.should.be.equal(await keyManager.isPayoutActive(accounts[3]))
                    true.should.be.equal(await keyManager.isVotingActive(accounts[5]))
                })

                it('should emit a ValidatorInitialized event when valid mining, payout and voting keys are set', async () => {
                    log0.event.should.be.equal('ValidatorInitialized');
                    log0.args.miningKey.should.be.equal(accounts[3]);
                    log0.args.payoutKey.should.be.equal(accounts[4]);
                    log0.args.votingKey.should.be.equal(accounts[5]);
                })

                it('should assigns voting <-> mining key relationship', async () => {
                    let miningKey = await keyManager.getMiningKeyByVoting(accounts[5]);
                    miningKey.should.be.equal(accounts[3]);
                })

                it('adds validator mining key to network consensus contract', async () => {
                    let pendingValidators = await networkConsensus.getPendingValidators();
                    pendingValidators[pendingValidators.length - 1].should.be.equal(accounts[3]);
                })

                it('should update the managed validator keys in storage', async () => {
                    let validator = await keyManager.unmarshalValidatorKeysMock(accounts[3]);
                    validator.should.be.deep.equal([accounts[4], accounts[5], true, true, true])
                })

                it('should wipe validator key storage associated with the initial key', async () => {
                    let validatorStorage = await keyManager.unmarshalValidatorKeysMock(accounts[2]);
                    validatorStorage.should.be.deep.equal(['0x0000000000000000000000000000000000000000', '0x0000000000000000000000000000000000000000', false, false, false])
                })
            })
        })
    })

    describe('#addMiningKey', async () => {
        context('when invoked from outside the voting contract', async () => {
            beforeEach(async () => {
                await keyManager.setVotingContractMock(accounts[2]);
            })

            it('should reject the unauthorized attempt to add the mining key', async () => {
                await keyManager.addMiningKey(accounts[1], { from: accounts[accounts.length - 1] }).should.be.rejectedWith(exports.EVM_ERR_REVERT);
            })
        })

        context('when invoked by the voting contract', async () => {
            beforeEach(async () => {
                await keyManager.addMiningKey(accounts[1]).should.be.fulfilled
            })

            it('should not let the number of managed validators exceed the network maximum', async () => {
              await keyManager.setMaxTotalValidators(1);
              await keyManager.addMiningKey(accounts[2]).should.be.rejectedWith(exports.EVM_ERR_REVERT);
            })

            it('should update the managed validator keys in storage', async () => {
                const validator = await keyManager.unmarshalValidatorKeysMock(accounts[1]);
                validator.should.be.deep.equal(['0x0000000000000000000000000000000000000000', '0x0000000000000000000000000000000000000000', true, false, false])
            })

            it('should emit a MiningKeyChanged event', async () => {
                const { logs } = await keyManager.addMiningKey(accounts[2]).should.be.fulfilled
                logs[0].event.should.be.equal('MiningKeyChanged')
                logs[0].args.key.should.be.equal(accounts[2])
                logs[0].args.action.should.be.equal('added')
            })
        })

    })

    describe('#addVotingKey', async () => {
        it('should add VotingKey', async () => {
            await keyManager.addVotingKey(accounts[2], accounts[1], { from: accounts[3] }).should.be.rejectedWith(exports.EVM_ERR_REVERT);
            await keyManager.addMiningKey(accounts[1]).should.be.fulfilled;
            const { logs } = await keyManager.addVotingKey(accounts[2], accounts[1]).should.be.fulfilled;
            true.should.be.equal(await keyManager.isVotingActive(accounts[2]));
            logs[0].event.should.be.equal('VotingKeyChanged');
            logs[0].args.key.should.be.equal(accounts[2]);
            logs[0].args.miningKey.should.be.equal(accounts[1]);
            logs[0].args.action.should.be.equal('added');

            const miningKey = await keyManager.getMiningKeyByVoting(accounts[2]);
            miningKey.should.be.equal(accounts[1]);
        })

        it('should only be called if mining is active', async () => {
            await keyManager.addMiningKey(accounts[1]).should.be.fulfilled;
            await keyManager.removeMiningKey(accounts[1]).should.be.fulfilled;
            await keyManager.addVotingKey(accounts[2], accounts[1]).should.be.rejectedWith(exports.EVM_ERR_REVERT);
        })

        it('swaps keys if voting already exists', async () => {
            await keyManager.addMiningKey(accounts[1]).should.be.fulfilled;
            await keyManager.addVotingKey(accounts[2], accounts[1]).should.be.fulfilled;
            await keyManager.addVotingKey(accounts[3], accounts[1]).should.be.fulfilled;
            false.should.be.equal(await keyManager.isVotingActive(accounts[2]));
            true.should.be.equal(await keyManager.isVotingActive(accounts[3]));
            const validator = await keyManager.unmarshalValidatorKeysMock(accounts[1]);
            validator.should.be.deep.equal(['0x0000000000000000000000000000000000000000', accounts[3], true, false, true])
        })
    })

    describe('#addPayoutKey', async () => {
        it('should add PayoutKey', async () => {
            await keyManager.addPayoutKey(accounts[2], accounts[1]).should.be.rejectedWith(exports.EVM_ERR_REVERT);
            await keyManager.addMiningKey(accounts[1]).should.be.fulfilled;
            const { logs } = await keyManager.addPayoutKey(accounts[2], accounts[1]).should.be.fulfilled;
            logs[0].event.should.be.equal('PayoutKeyChanged');
            logs[0].args.key.should.be.equal(accounts[2]);
            logs[0].args.miningKey.should.be.equal(accounts[1]);
            logs[0].args.action.should.be.equal('added');
        })

        it('should only be called if mining is active', async () => {
            await keyManager.addMiningKey(accounts[1]).should.be.fulfilled;
            await keyManager.removeMiningKey(accounts[1]).should.be.fulfilled;
            await keyManager.addPayoutKey(accounts[2], accounts[1]).should.be.rejectedWith(exports.EVM_ERR_REVERT);
        })

        it('swaps keys if voting already exists', async () => {
            await keyManager.addMiningKey(accounts[1]).should.be.fulfilled;
            await keyManager.addPayoutKey(accounts[2], accounts[1]).should.be.fulfilled;
            await keyManager.addPayoutKey(accounts[3], accounts[1]).should.be.fulfilled;
            true.should.be.equal(await keyManager.isPayoutActive(accounts[1]));
            const validator = await keyManager.unmarshalValidatorKeysMock(accounts[1]);
            validator.should.be.deep.equal([accounts[3], '0x0000000000000000000000000000000000000000', true, true, false])
        })
    })

    describe('#removeMiningKey', async () => {
        it('should remove miningKey', async () => {
            await keyManager.removeMiningKey(accounts[1], { from: accounts[3] }).should.be.rejectedWith(exports.EVM_ERR_REVERT);
            await keyManager.addMiningKey(accounts[1]).should.be.fulfilled;
            await keyManager.addVotingKey(accounts[3], accounts[1]).should.be.fulfilled;
            const { logs } = await keyManager.removeMiningKey(accounts[1]).should.be.fulfilled;
            const validator = await keyManager.unmarshalValidatorKeysMock(accounts[1]);
            validator.should.be.deep.equal(['0x0000000000000000000000000000000000000000', '0x0000000000000000000000000000000000000000', false, false, false])
            logs[0].event.should.be.equal('MiningKeyChanged');
            logs[0].args.key.should.be.equal(accounts[1]);
            logs[0].args.action.should.be.equal('removed');
            const miningKey = await keyManager.getMiningKeyByVoting(validator[0]);
            miningKey.should.be.equal('0x0000000000000000000000000000000000000000');
        })

        it('removes validator from network consensus.', async () => {
            await keyManager.addMiningKey(accounts[1]).should.be.fulfilled;
            await networkConsensus.setSystemAddress(accounts[0]);
            await networkConsensus.finalizeChange().should.be.fulfilled;
            await keyManager.removeMiningKey(accounts[1]).should.be.fulfilled;
            let currentValidatorsLength = await networkConsensus.getValidatorsCount();
            let pendingList = [];
            let pendingValidators = await networkConsensus.getPendingValidators();
            for (let i = 0; i < currentValidatorsLength.sub(1).toNumber(); i++) {
                pendingList.push(pendingValidators[i]);
            }
            pendingList.should.not.contain(accounts[1]);
            await networkConsensus.finalizeChange().should.be.fulfilled;
            const validators = await networkConsensus.getValidators();
            validators.should.not.contain(accounts[1]);
            const expected = currentValidatorsLength.sub(1);
            const actual = await networkConsensus.getValidatorsCount();
            expected.should.be.bignumber.equal(actual);
        })

        it('should still enforce removal of votingKey to 0x0 even if voting key did not exist', async () => {
            await keyManager.removeMiningKey(accounts[1]).should.be.rejectedWith(exports.EVM_ERR_REVERT);
            await keyManager.setVotingContractMock(masterOfCeremony);
            await keyManager.addMiningKey(accounts[1]).should.be.fulfilled;
            const { logs } = await keyManager.removeMiningKey(accounts[1]).should.be.fulfilled;
            const validator = await keyManager.unmarshalValidatorKeysMock(accounts[1]);
            const miningKey = await keyManager.getMiningKeyByVoting(validator[0]);
            miningKey.should.be.equal('0x0000000000000000000000000000000000000000');
        })
    })

    describe('#removeVotingKey', async () => {
        it('should remove votingKey', async () => {
            const { mining, payout, voting } = { mining: accounts[1], payout: accounts[2], voting: accounts[2] };
            await keyManager.removeVotingKey(mining, { from: accounts[3] }).should.be.rejectedWith(exports.EVM_ERR_REVERT);
            await keyManager.addMiningKey(mining).should.be.fulfilled;
            await keyManager.addPayoutKey(payout, mining).should.be.fulfilled;
            await keyManager.addVotingKey(voting, mining).should.be.fulfilled;
            const { logs } = await keyManager.removeVotingKey(mining).should.be.fulfilled;
            const validator = await keyManager.unmarshalValidatorKeysMock(mining);
            validator.should.be.deep.equal([payout, '0x0000000000000000000000000000000000000000', true, true, false])
            logs[0].event.should.be.equal('VotingKeyChanged');
            logs[0].args.key.should.be.equal(voting);
            logs[0].args.action.should.be.equal('removed');
            const miningKey = await keyManager.getMiningKeyByVoting(accounts[1]);
            miningKey.should.be.equal('0x0000000000000000000000000000000000000000');
        })
    })

    describe('#removePayoutKey', async () => {
        it('should remove payoutKey', async () => {
            await keyManager.removePayoutKey(accounts[1], { from: accounts[4] }).should.be.rejectedWith(exports.EVM_ERR_REVERT);
            await keyManager.addMiningKey(accounts[1]).should.be.fulfilled;
            await keyManager.addPayoutKey(accounts[2], accounts[1]).should.be.fulfilled;
            await keyManager.addVotingKey(accounts[3], accounts[1]).should.be.fulfilled;
            const { logs } = await keyManager.removePayoutKey(accounts[1]).should.be.fulfilled;
            const validator = await keyManager.unmarshalValidatorKeysMock(accounts[1]);
            validator.should.be.deep.equal(['0x0000000000000000000000000000000000000000', accounts[3], true, false, true])
            logs[0].event.should.be.equal('PayoutKeyChanged');
            logs[0].args.key.should.be.equal(accounts[2]);
            logs[0].args.action.should.be.equal('removed');
        })
    })

    describe('#swapMiningKey', async () => {
        context('when the given mining key does not exist', async () => {
            it('should fail when attempting to swap a mining key which does not exist', async () => {
                keyManager.swapMiningKey(accounts[1], accounts[2], { from: accounts[4] }).should.be.rejectedWith(exports.EVM_ERR_REVERT);
            })
        })

        context('when the given mining key exists and is swappable', async () => {
            let initialMiningKey = accounts[1]
            let initialPayoutAndPostSwapMiningKey = accounts[3]
            let initialVotingKey = accounts[2]
            let postSwapMiningKey, postSwapPayoutKey, postSwapVotingKey, postSwapValidatorMiningActive, postSwapValidatorPayoutActive, postSwapValidatorVotingActive, postSwapValidatorKeys

            beforeEach(async () => {
                await keyManager.addMiningKey(initialMiningKey).should.be.fulfilled;
                await keyManager.addPayoutKey(initialPayoutAndPostSwapMiningKey, initialMiningKey).should.be.fulfilled;
                await keyManager.addVotingKey(initialVotingKey, initialMiningKey).should.be.fulfilled;
                await keyManager.swapMiningKey(initialPayoutAndPostSwapMiningKey, initialMiningKey).should.be.fulfilled;

                postSwapValidatorKeys = await keyManager.unmarshalValidatorKeysMock(initialPayoutAndPostSwapMiningKey);
                postSwapMiningKey = initialPayoutAndPostSwapMiningKey
                postSwapPayoutKey = postSwapValidatorKeys[0]
                postSwapVotingKey = postSwapValidatorKeys[1]
                postSwapValidatorMiningActive = postSwapValidatorKeys[2]
                postSwapValidatorPayoutActive = postSwapValidatorKeys[3]
                postSwapValidatorVotingActive = postSwapValidatorKeys[4]
            })

            it('should wipe validator key storage associated with the initial mining key', async () => {
                let validatorStorage = await keyManager.unmarshalValidatorKeysMock(initialMiningKey);
                validatorStorage.should.be.deep.equal(['0x0000000000000000000000000000000000000000', '0x0000000000000000000000000000000000000000', false, false, false])
            })

            it('should swap the mining key', async () => {
                let swappedValidatorStorage = await keyManager.unmarshalValidatorKeysMock(initialPayoutAndPostSwapMiningKey);
                swappedValidatorStorage.should.be.deep.equal(['0x0000000000000000000000000000000000000000', initialVotingKey, true, true, true])
            })

            it('should maintain the existing payout key', async () => {
                postSwapPayoutKey.should.be.deep.eq('0x0000000000000000000000000000000000000000')
                postSwapValidatorPayoutActive.should.be.true
            })

            it('should maintain the existing voting key', async () => {
                postSwapVotingKey.should.be.deep.eq(initialVotingKey)
                postSwapValidatorVotingActive.should.be.true
            })

            it('should maintain a reference to the uninstalled mining key history', async () => {
                let lastMiningKey = await keyManager.getMiningKeyHistory(postSwapMiningKey)
                lastMiningKey.should.be.deep.eq(initialMiningKey)
            })

            describe('finalizing pending changes to validators via network consensus contract exection', async () => {
                beforeEach(async () => {
                    await networkConsensus.setSystemAddress(accounts[0]);
                    await networkConsensus.finalizeChange().should.be.fulfilled;
                })

                it('should delegate the finalization of the key swap to the network consensus contract', async () => {
                    let validators = await networkConsensus.getValidators();
                    validators.should.not.contain(initialMiningKey);
                    validators.should.contain(postSwapMiningKey);
                })
            })
        })
    })

    describe('#swapPayoutKey', async () => {
        it('should swap payout key', async () => {
            await keyManager.swapPayoutKey(accounts[1], accounts[2], { from: accounts[4] }).should.be.rejectedWith(exports.EVM_ERR_REVERT);
            await keyManager.addMiningKey(accounts[1]).should.be.fulfilled;
            await keyManager.addPayoutKey(accounts[2], accounts[1]).should.be.fulfilled;
            await keyManager.swapPayoutKey(accounts[3], accounts[1]).should.be.fulfilled;
            let validator = await keyManager.unmarshalValidatorKeysMock(accounts[1]);
            validator.should.be.deep.equal([accounts[3], '0x0000000000000000000000000000000000000000', true, true, false])
        })
    })

    describe('#swapVotingKey', async () => {
        it('should swap voting key', async () => {
            await keyManager.swapVotingKey(accounts[1], accounts[2], { from: accounts[4] }).should.be.rejectedWith(exports.EVM_ERR_REVERT);
            await keyManager.addMiningKey(accounts[1]).should.be.fulfilled;
            await keyManager.addVotingKey(accounts[2], accounts[1]).should.be.fulfilled;
            await keyManager.swapVotingKey(accounts[3], accounts[1]).should.be.fulfilled;
            const validator = await keyManager.unmarshalValidatorKeysMock(accounts[1]);
            validator.should.be.deep.equal(['0x0000000000000000000000000000000000000000', accounts[3], true, false, true])
        })
    })

    describe('#migrateInitialKey', async () => {
        let newKeyManager

        context('when the initial key is not eligible for migration', async () => {
            it('should reject the attempt to migrate the ineligible key', async () => {
                await keyManager.migrateInitialKey(accounts[2]).should.be.rejectedWith(exports.EVM_ERR_REVERT)
            })
        })

        context('when the initial key exists and is eligible for migration', async () => {
            let logs0

            beforeEach(async () => {
                await keyManager.initiateKeys(accounts[2])
                newKeyManager = await KeyManager.new(networkConsensus.address, keyManager.address)
                let { logs } = await newKeyManager.migrateInitialKey(accounts[2]).should.be.be.fulfilled
                logs0 = logs[0]
            })

            it('should emit a Migrated event', async () => {
                logs0.event.should.equal("Migrated");
                logs0.args.key.should.be.equal(accounts[2]);
                logs0.args.name.should.be.equal("initialKey");
            })

            describe('relationship between new and previous key manager contracts', async () => {
                it('should result in the new key manager maintaining a reference to the previous key manager', async () => {
                    let prevKeyManager = await newKeyManager.getPreviousKeyManager();
                    prevKeyManager.should.be.deep.equal(keyManager.address)
                })

                it('should result in the new key manager inheriting the key state from the previous key manager', async () => {
                    let initialKeys = await newKeyManager.getInitialKeyCount()
                    initialKeys.should.be.bignumber.equal(1)

                    let initialKeyState0 = await newKeyManager.getInitialKey(accounts[1])
                    initialKeyState0.should.be.bignumber.eq(0) // key state

                    let initialKeyState1 = await newKeyManager.getInitialKey(accounts[2])
                    initialKeyState1.should.be.bignumber.eq(1) // key state
                })

                // context('when the mining key is migrated')

                // it('should retain a copy of the inhereited validator keys', async () => {
                //     let miningKey = accounts[2];
                //     let votingKey = accounts[3];
                //     let payoutKey = accounts[4];
                //     let mining2 = accounts[5];
                //     await keyManager.setVotingContractMock(accounts[2]);
                //     await keyManager.addMiningKey(mining2, { from: accounts[2] }).should.be.fulfilled;

                //     await keyManager.initiateKeys(accounts[1], { from: masterOfCeremony }).should.be.fulfilled;
                //     await keyManager.createKeys(miningKey, payoutKey, votingKey, { from: accounts[1] }).should.be.fulfilled;
                //     const validatorKeyFromOld = await keyManager.unmarshalValidatorKeysMock(miningKey);
                //     validatorKeyFromOld.should.be.deep.equal([payoutKey, votingKey, true, true, true])
                //     let newKeyManager = await KeyManager.new(networkConsensus.address, keyManager.address);

                //     // mining #1
                //     let { logs } = await newKeyManager.migrateMiningKey(miningKey);
                //     logs[0].event.should.equal("Migrated");
                //     logs[0].args.key.should.be.equal(miningKey);
                //     logs[0].args.name.should.be.equal("miningKey");
                //     // FIXME-- lots of logs missed here in coverage

                //     let initialKeys = await newKeyManager.getInitialKeyCount();
                //     initialKeys.should.be.bignumber.equal(1);
                //     const validatorKey = await newKeyManager.unmarshalValidatorKeysMock(miningKey);
                //     validatorKey.should.be.deep.equal([payoutKey, votingKey, true, true, true])
                //     true.should.be.equal(await newKeyManager.hasValidatorClone(miningKey))

                //     miningKey.should.be.equal(await newKeyManager.getMiningKeyByVoting(votingKey));

                //     true.should.be.equal(await newKeyManager.isMiningActive(miningKey))
                //     true.should.be.equal(await newKeyManager.isPayoutActive(miningKey))
                //     true.should.be.equal(await newKeyManager.isVotingActive(votingKey))

                //     // mining#2
                //     await newKeyManager.migrateMiningKey(mining2);
                //     const validatorKey2 = await newKeyManager.unmarshalValidatorKeysMock(mining2);
                //     validatorKey2.should.be.deep.equal(['0x0000000000000000000000000000000000000000', '0x0000000000000000000000000000000000000000', true, false, false])

                //     true.should.be.equal(await newKeyManager.isMiningActive(mining2))
                //     true.should.be.equal(await newKeyManager.hasValidatorClone(mining2))
                // })

                context('when the new key manager successfully cloned inherited mining key state', async () => {
                    it('should reject the attempt to migrate a previously cloned mining key', async () => {
                        (await newKeyManager.hasValidatorClone(masterOfCeremony)).should.be.true
                        await newKeyManager.migrateMiningKey(masterOfCeremony).should.be.rejectedWith(exports.EVM_ERR_REVERT);
                    })
                })
            })
        })
    })
})
