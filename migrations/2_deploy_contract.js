var KeyManager = artifacts.require('./KeyManager.sol');
var NetworkStorage = artifacts.require('./NetworkStorage.sol');
var NetworkConsensus = artifacts.require('./NetworkConsensus.sol');
var NetworkConsensusMock = artifacts.require('./NetworkConsensusMock.sol');
var NetworkStorageMock = artifacts.require('./NetworkStorageMock.sol');
var NetworkContract = artifacts.require('./NetworkContract.sol');

module.exports = async function(deployer, network, accounts) {
  let masterOfCeremonyAddress = process.env.MASTER_OF_CEREMONY;
  let networkStorageAddress = process.env.NETWORK_STORAGE_ADDRESS;
  let networkConsensusAddress = process.env.NETWORK_CONSENSUS_ADDRESS;
  let previousKeysManager = process.env.OLD_KEYSMANAGER || '0x0000000000000000000000000000000000000000';

  let networkConsensus;
  let networkStorage;

  if (!!process.env.DEPLOY === true && network === 'unicorn') {
    networkStorage = await NetworkStorage.at(networkStorageAddress);
    networkConsensus = await NetworkConsensus.at(networkConsensusAddress);

    let validators = await networkConsensus.getValidators();
    let moc = validators.indexOf(masterOfCeremonyAddress.toLowerCase())
    if (moc > -1) {
      validators.splice(moc, 1);
    }

    networkStorage = await deployer.deploy(NetworkStorage);
    networkConsensus = await deployer.deploy(NetworkConsensus, networkStorage, masterOfCeremonyAddress, validators);
  }

  if (network === 'unicorn') {
    try {
      networkStorage = networkStorage || await NetworkStorage.at(networkStorageAddress);
      networkConsensus = networkConsensus || await NetworkConsensus.at(networkConsensusAddress);

      await deployer.deploy(KeysManager);
    } catch (error) {
      console.error(error);
    }
  }
};
