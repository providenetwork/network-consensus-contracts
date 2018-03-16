let NetworkConsensusMock = artifacts.require('./mock/NetworkConsensusMock')
let NetworkStorageMock = artifacts.require('./mock/NetworkStorageMock')


contract('NetworkConsensus', function(accounts) {
    let networkConsensus, networkStorage
    masterOfCeremony = accounts[0]

    beforeEach(async () => {
        networkStorage = await NetworkStorageMock.new()
        networkConsensus = await NetworkConsensusMock.new(networkStorage.address, masterOfCeremony)
    })

    describe('initialization', async () => {
        it('should receive a reference to the default system address', async () => {
            let systemAddress = await networkConsensus.getSystemAddress()
            systemAddress.should.not.be.eq(null)
            systemAddress.should.be.deep.eq('0xfffffffffffffffffffffffffffffffffffffffe')
        })

        it('should receive a reference to the network storage contract', async () => {
            let storage = await networkConsensus.getNetworkStorage()
            storage.should.not.be.eq(null)
            storage.should.be.deep.eq(networkStorage.address)
        })

        it('should not appoint any non-pending validators', async () => {
            let validators = await networkConsensus.getValidators()
            validators.should.be.deep.eq([])
        })

        it('should appoint the master of ceremony as the initial pending validator', async () => {
            let pendingValidators = await networkConsensus.getPendingValidators()
            pendingValidators.should.be.deep.eq([masterOfCeremony])
        })

        it('should not be finalized per Aura consensus spec', async () => {
            let finalized = await networkConsensus.finalized()
            finalized.should.be.false
        })

    })

    context('when changes to the validators list is not finalized', async () => {
        describe('#finalizeChange', async () => {
            context('when invoked by the system address', async () => {
                beforeEach(async () => {
                    await networkConsensus.setSystemAddress(accounts[0])
                })

                it('should finalize the pending validator state', async () => {
                    await networkConsensus.finalizeChange().should.be.fulfilled
                    let finalized = await networkConsensus.finalized()
                    finalized.should.be.true
                })

                it('should reject subsequent attempts to finalize the pending validator state', async () => {
                    await networkConsensus.finalizeChange().should.be.fulfilled
                    await networkConsensus.finalizeChange().should.be.rejectedWith(exports.EVM_ERR_REVERT)
                })

                it('should emit a ChangeFinalized event per Aura consensus spec', async () => {
                    const { logs } = await networkConsensus.finalizeChange().should.be.fulfilled
                    logs[0].event.should.be.eq('ChangeFinalized')
                })

                it('should promote the pending validators set to the finalized set of current validators', async () => {
                    await networkConsensus.finalizeChange().should.be.fulfilled
                    let validators = await networkConsensus.getValidators()
                    validators.should.be.deep.eq([masterOfCeremony])
                })
            })

            context('when not invoked by the system address', async () => {
                it('should reject the attempt to finalize the pending validator state', async () => {
                    await networkConsensus.finalizeChange().should.be.rejectedWith(exports.EVM_ERR_REVERT)
                })
            })
        })
    })

    describe('#addValidator', async () => {
        context('when not invoked by the key manager', async () => {
            it('should reject the attempt to add the validator', async () => {
                await networkConsensus.addValidator(accounts[1], true, { from: accounts[2] }).should.be.rejectedWith(exports.EVM_ERR_REVERT)
            })
        })

        context('when invoked by the key manager', async () => {
            beforeEach(async () => {
                await networkConsensus.setKeyManagerMock(accounts[0])
            })

            context('when the given address is not a current validator', async () => {
                it('should attempt to add a new validator', async () => {
                    await networkConsensus.addValidator(accounts[1], true).should.be.fulfilled
                })

                it('should reject an attempt to add 0x0 as a validator', async () => {
                    await networkConsensus.addValidator('0x0', true).should.be.rejectedWith(exports.EVM_ERR_REVERT)
                    await networkConsensus.addValidator('0x0000000000000000000000000000000000000000', true).should.be.rejectedWith(exports.EVM_ERR_REVERT)
                })

                it('should set validator meta for new validator', async () => {
                    await networkConsensus.addValidator(accounts[1], true).should.be.fulfilled
                    let isValidator = await networkConsensus.isValidator(accounts[1])
                    isValidator.should.be.true
                })

                it('should increase length of pending validators', async () => {
                    let pendingValidators0 = await networkConsensus.getPendingValidators()
                    pendingValidators0.length.should.be.eq(1)
                    await networkConsensus.addValidator(accounts[1], true).should.be.fulfilled
                    let pendingValidators1 = await networkConsensus.getPendingValidators()
                    pendingValidators1.length.should.be.eq(2)
                })

                it('should set finalized to false', async () => {
                    await networkConsensus.addValidator(accounts[1], true).should.be.fulfilled
                    let finalized = await networkConsensus.finalized()
                    finalized.should.be.false
                })

                it('should emit an InitiateChange event containing the pending validators list per Aura consensus spec', async () => {
                    const { logs } = await networkConsensus.addValidator(accounts[accounts.length - 1], true).should.be.fulfilled
                    logs[0].event.should.be.eq('InitiateChange')
                    logs[0].args.newSet.should.be.deep.eq([masterOfCeremony, accounts[accounts.length - 1]])
                })
            })

            context('when the given address is a current validator', async () => {
                beforeEach(async () => {
                    await networkConsensus.setKeyManagerMock(accounts[0])
                    await networkConsensus.addValidator(accounts[1], true).should.be.fulfilled
                })

                it('should reject an attempt to add a duplicate validator', async () => {
                    await networkConsensus.addValidator(accounts[1], true).should.be.rejectedWith(exports.EVM_ERR_REVERT)
                })
            })
        })
    })

    describe('#removeValidator', async () => {
        context('when not invoked by the key manager', async () => {
            it('reject the attempt to remove the validator', async () => {
                await networkConsensus.removeValidator(accounts[1], true).should.be.rejectedWith(exports.EVM_ERR_REVERT)
            })
        })

        context('when invoked by the key manager', async () => {
            beforeEach(async () => {
                await networkConsensus.setKeyManagerMock(accounts[0])
                await networkConsensus.setSystemAddress(accounts[0])
            })

            context('when the validator being removed is not a current validator', async () => {
                it('should reject an attempt by the key manager to remove an address which is not a current validator', async () => {
                    await networkConsensus.removeValidator(accounts[1], true).should.be.rejectedWith(exports.EVM_ERR_REVERT)
                })
            })

            context('when the validator being removed is a current validator', async () => {
                beforeEach(async () => {
                    await networkConsensus.addValidator(accounts[1], true).should.be.fulfilled
                })
    
                it('should attempt to remove the given validator', async () => {
                    await networkConsensus.removeValidator(accounts[1], true).should.be.fulfilled
                })

                it('should emit an InitiateChange event per Aura consensus spec', async () => {
                    let { logs } = await networkConsensus.removeValidator(accounts[1], true).should.be.fulfilled
                    logs[0].event.should.be.eq('InitiateChange')
                    logs[0].args.newSet.length.should.be.eq(1)
                    logs[0].args.newSet.should.be.deep.eq([masterOfCeremony])
                })

                it('should decrease length of pending validators', async () => {
                    let pendingValidators0 = await networkConsensus.getPendingValidators()
                    pendingValidators0.length.should.be.eq(2)

                    let { logs } = await networkConsensus.removeValidator(accounts[1], true).should.be.fulfilled
                    logs[0].args.newSet.length.should.be.eq(1)
                    logs[0].args.newSet.should.be.deep.eq([masterOfCeremony])

                    let pendingValidators1 = await networkConsensus.getPendingValidators()
                    pendingValidators1.length.should.be.eq(1)
                })

                it('should update validator meta for the removed validator', async () => {
                    let isValidator0 = await networkConsensus.isValidator(accounts[1])
                    isValidator0.should.be.true
                    await networkConsensus.removeValidator(accounts[1], true).should.be.fulfilled
                    let isValidator1 = await networkConsensus.isValidator(accounts[1])
                    isValidator1.should.be.false
                })

                it('should not be finalized per Aura consensus spec', async () => {
                    let finalized = await networkConsensus.finalized()
                    finalized.should.be.false
                })
            })
        })
    })

    describe('#isValidator', async () => {
        it('should return true when the queried network address belongs to a validator', async () => {
            (await networkConsensus.isValidator(masterOfCeremony)).should.be.true
        })

        it('should return false when the queried network address does not belong to a validator', async () => {
            (await networkConsensus.isValidator(accounts[accounts.length - 1])).should.be.false
        })
    })
})
