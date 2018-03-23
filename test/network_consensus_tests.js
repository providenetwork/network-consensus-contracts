let NetworkConsensus = artifacts.require('./mock/NetworkConsensusMock')
let RegistryExec = artifacts.require('./mock/RegistryExec')
let RegistryStorage = artifacts.require('./RegistryStorage')

let InitRegistry = artifacts.require('./InitRegistry')
let AppConsole = artifacts.require('./AppConsole')
let VersionConsole = artifacts.require('./VersionConsole')
let ImplementationConsole = artifacts.require('./ImplementationConsole')

let Aura = artifacts.require('./Aura')
let ValidatorConsole = artifacts.require('./ValidatorConsole')
let VotingConsole = artifacts.require('./VotingConsole')

contract('NetworkConsensus', function(accounts) {
    let consensus
    let registry
    let storage
    let masterOfCeremony

    let initRegistry
    let appConsole
    let versionConsole
    let implConsole

    let initAura
    let validatorConsole
    let votingConsole

    beforeEach(async () => {
        initRegistry = await InitRegistry.new().should.be.fulfilled
        appConsole = await AppConsole.new().should.be.fulfilled
        versionConsole = await VersionConsole.new().should.be.fulfilled
        implConsole = await ImplementationConsole.new().should.be.fulfilled

        initAura = await Aura.new().should.be.fulfilled
        validatorConsole = await ValidatorConsole.new().should.be.fulfilled
        votingConsole = await VotingConsole.new().should.be.fulfilled

        storage = await RegistryStorage.new().should.be.fulfilled
        masterOfCeremony = accounts[0]
        consensus = await NetworkConsensus.new(
            masterOfCeremony,
            storage.address,
            initRegistry.address,
            appConsole.address,
            versionConsole.address,
            implConsole.address,
            initAura.address,
            validatorConsole.address,
            votingConsole.address
        ).should.be.fulfilled

        let registryAddr = await consensus.getRegistryAddress()
        registry = await RegistryExec.at(registryAddr)
    })

    describe('initialization', async () => {
        it('should have a reference to the given master of ceremony address', async () => {
            masterOfCeremony.should.be.eq(accounts[0])
        })

        describe('auth-os application registry', async() => {
            it('should have initialized the auth-os application registry', async() => {
                registry.should.not.eq(null)
            })

            it('should have set a default application storage contract on the application registry', async() => {
                let defaultStorage = await registry.default_storage()
                defaultStorage.should.eq(storage.address)
            })

            it('should have set a default updater on the application registry', async() => {
                let defaultUpdater = await registry.default_updater()
                defaultUpdater.should.eq(consensus.address)
            })

            it('should have set a default provider on the application registry', async() => {
                let defaultProvider = await registry.default_provider()
                let expectedProvider = await consensus.getAppProviderHash(consensus.address).should.be.fulfilled
                defaultProvider.should.eq(expectedProvider)
            })

            it('should have set a default registry exec id on the application registry', async() => {
                let defaultExecId = await registry.default_registry_exec_id()
                defaultExecId.should.not.deep.eq('0x0000000000000000000000000000000000000000000000000000000000000000')
            })

            it('should have set the initial exec admin on the application registry to the consensus contract', async() => {
                let execAdmin = await registry.exec_admin()
                execAdmin.should.eq(consensus.address)
            })
        })

        it('should expose the validator console', async() => {
            let validatorConsoleAddr = await consensus.getValidatorConsoleAddress.call()
            validatorConsoleAddr.should.not.eq(null)
        })

        it('should expose the voting console', async() => {
            let votingConsoleAddr = await consensus.getVotingConsoleAddress.call()
            votingConsoleAddr.should.not.eq(null)
        })
    })

    describe('#initRegistry', async () => {
        beforeEach(async () => {
        })

        describe('#getAppLatestInfo', async () => {
            it('should return the latest finalized version of the Aura consensus application', async () => {
                let registryAddr = await consensus.getRegistryAddress()
                let registry = await RegistryExec.at(registryAddr)
                let registryExecId = await registry.default_registry_exec_id()

                providerInfo = await initRegistry.getProviderInfoFromAddress(storage.address, registryExecId, consensus.address).should.be.fulfilled
                providerInfo.should.not.eq(null)
                providerInfo[1].length.should.be.eq(1)

                let provider = await consensus.getAppProviderHash(consensus.address).should.be.fulfilled

                appInfo = await initRegistry.getAppLatestInfo(storage.address, registryExecId, provider, 'Aura').should.be.fulfilled
                appInfo.should.not.eq(null)
                appInfo[appInfo.length - 1].length.should.be.eq(2)
            })
        })
    })

    describe('getValidator', async () => {
        context('immediately after the consensus delegate has been configured', async () => {
            beforeEach(async () => {
            })

            it('should return nil when attempting retrieve the master of ceremony validator struct', async () => {
                let execId = await consensus.getConsensusAppExecId.call()
                let validator = await initAura.getValidator.call(storage.address, execId, masterOfCeremony)
                validator.should.be.eq(null)
            })
        })
    })

    describe('getValidatorMetadata', async () => {
        context('immediately after the consensus delegate has been configured', async () => {
            beforeEach(async () => {
            })

            it('should return nil when attempting retrieve the master of ceremony validator struct', async () => {
                let execId = await consensus.getConsensusAppExecId.call()
                let validatorMeta = await initAura.getValidatorMetadata.call(storage.address, execId, masterOfCeremony)
                validatorMeta.should.be.eq(null)
            })
        })
    })

    describe('getValidatorSupportDivisor', async () => {
        context('immediately after the consensus delegate has been configured', async () => {
            beforeEach(async () => {
            })

            it('should initialize the validator support divisor to the default validator support divisor of 2', async () => {
                let execId = await consensus.getConsensusAppExecId.call()
                let validatorSupportDivisor = await initAura.getValidatorSupportDivisor.call(storage.address, execId)
                validatorSupportDivisor.toNumber().should.be.eq(2)
            })
        })
    })

    describe('getValidatorSupportCount', async () => {
        context('immediately after the consensus delegate has been configured', async () => {
            beforeEach(async () => {
            })

            it('should initialize the master of ceremony with support for itself', async () => {
                let execId = await consensus.getConsensusAppExecId.call()
                let validatorSupportCount = await initAura.getValidatorSupportCount.call(storage.address, execId, masterOfCeremony)
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
})
