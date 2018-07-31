let AbstractStorage = artifacts.require('./AbstractStorage')
let NetworkConsensus = artifacts.require('./mock/NetworkConsensusMock')

let RegistryIdx = artifacts.require('./RegistryIdx')
let Provider = artifacts.require('./Provider')

let Aura = artifacts.require('./Aura')
let ValidatorConsole = artifacts.require('./ValidatorConsole')
let VotingConsole = artifacts.require('./VotingConsole')

contract('NetworkConsensus', function(accounts) {
    let consensus
    let storage
    let masterOfCeremony

    let registryIdx
    let provider

    let aura
    let validatorConsole
    let votingConsole

    beforeEach(async () => {
        registryIdx = await RegistryIdx.new().should.be.fulfilled
        provider = await Provider.new().should.be.fulfilled

        aura = await Aura.new().should.be.fulfilled
        validatorConsole = await ValidatorConsole.new().should.be.fulfilled
        votingConsole = await VotingConsole.new().should.be.fulfilled

        storage = await AbstractStorage.new().should.be.fulfilled
        masterOfCeremony = accounts[0]
        consensus = await NetworkConsensus.new(
            masterOfCeremony,
            storage.address,
            registryIdx.address,
            provider.address,
            aura.address,
            validatorConsole.address,
            votingConsole.address
        ).should.be.fulfilled
    })

    describe('addValidator', async () => {
        context('initial key ceremony', async () => {
            beforeEach(async () => {
                await consensus.addValidator('0x87b7af6915fa56a837fa85e31ad6a450c41e8fab').should.be.fulfilled
            })

            it('should have added a pending validator', async () => {
                let pendingValidatorCount = await consensus.getPendingValidatorCount.call()
                pendingValidatorCount.toNumber().should.be.eq(2)

                let pendingValidators = await consensus.getPendingValidators.call()
                pendingValidators.length.should.be.eq(2)

                pendingValidators.indexOf('0x87b7af6915fa56a837fa85e31ad6a450c41e8fab').should.be.eq(1)
            })
        })
    })

    describe('getValidatorMetadata', async () => {
        context('immediately after the consensus delegate has been configured', async () => {
            beforeEach(async () => {
            })

            it('should return empty validator metadata when attempting retrieve the master of ceremony validator struct', async () => {
                let validatorMeta = await consensus.getValidatorMetadata.call(masterOfCeremony)
                validatorMeta.should.not.be.eq(null)
                validatorMeta.length.should.be.eq(9)
            })
        })
    })

    describe('getValidatorSupportDivisor', async () => {
        context('immediately after the consensus delegate has been configured', async () => {
            beforeEach(async () => {
            })

            it('should initialize the validator support divisor to the default validator support divisor of 2', async () => {
                let validatorSupportDivisor = await consensus.getValidatorSupportDivisor.call()
                validatorSupportDivisor.toNumber().should.be.eq(2)
            })
        })
    })

    describe('getValidatorSupportCount', async () => {
        context('immediately after the consensus delegate has been configured', async () => {
            beforeEach(async () => {
            })

            it('should initialize the master of ceremony with support for itself', async () => {
                let validatorSupportCount = await consensus.getValidatorSupportCount.call(masterOfCeremony)
                validatorSupportCount.toNumber().should.be.eq(1)
            })
        })
    })

    describe('getValidators', async () => {
        context('immediately after the consensus delegate has been configured', async () => {
            beforeEach(async () => {
            })

            it('should return the master of ceremony as the sole validator', async () => {
                let validators = await consensus.getValidators()
                validators.should.be.deep.eq([masterOfCeremony])
            })
        })
    })

    describe('getValidatorCount', async () => {
        context('immediately after the consensus delegate has been configured', async () => {
            beforeEach(async () => {
            })

            it('should return 1', async () => {
                let validatorCount = await consensus.getValidatorCount.call()
                validatorCount.toNumber().should.be.eq(1)
            })
        })
    })

    describe('getPendingValidators', async () => {
        context('immediately after the consensus delegate has been configured', async () => {
            beforeEach(async () => {
            })

            it('should return the master of ceremony as the sole validator', async () => {
                let pendingValidators = await consensus.getPendingValidators()
                pendingValidators.should.be.deep.eq([masterOfCeremony])
            })
        })
    })

    describe('getPendingValidatorCount', async () => {
        context('immediately after the consensus delegate has been configured', async () => {
            beforeEach(async () => {
            })

            it('should return 1', async () => {
                let pendingValidatorCount = await consensus.getPendingValidatorCount.call()
                pendingValidatorCount.toNumber().should.be.eq(1)
            })
        })
    })

    describe('getMinimumValidatorCount', async () => {
        context('immediately after the consensus delegate has been configured', async () => {
            beforeEach(async () => {
            })

            it('should return 12', async () => {
                let minimumValidatorCount = await consensus.getMinimumValidatorCount.call()
                minimumValidatorCount.toNumber().should.be.eq(12)
            })
        })
    })

    describe('getMaximumValidatorCount', async () => {
        context('immediately after the consensus delegate has been configured', async () => {
            beforeEach(async () => {
            })

            it('should return 1024', async () => {
                let maximumValidatorCount = await consensus.getMaximumValidatorCount.call()
                maximumValidatorCount.toNumber().should.be.eq(1024)
            })
        })
    })
})
