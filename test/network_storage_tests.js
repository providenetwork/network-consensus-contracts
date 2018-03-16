let NetworkConsensusMock = artifacts.require('./mock/NetworkConsensusMock');
let NetworkStorageMock = artifacts.require('./mock/NetworkStorageMock');

contract('NetworkStorage', function(accounts) {
  let networkStorage
  let masterOfCeremony = accounts[0]

  beforeEach(async () => {
    networkStorage = await NetworkStorageMock.new();
    networkConsensus = await NetworkConsensusMock.new(networkStorage.address, masterOfCeremony);
  })

  describe('#hashStorageKey', async () => {
    it('returns a hash specific to the calling contract', async () => {
      let ourHash = await networkStorage.hashStorageKey('path.to.key');
      let consensusHash = await networkConsensus.hashStorageKey('path.to.key');
      ourHash.should.not.be.equal(consensusHash);
    });

    it('is deterministic', async () => {
      let hash = await networkStorage.hashStorageKey('path.to.key');
      hash.should.be.equal(await networkStorage.hashStorageKey('path.to.key'));
    });
  })

  describe('generic eternal storage', async () => {
    describe('addressStorage', async () => {
      beforeEach(async () => {
        await networkStorage.setAddress('addrkey', accounts[0]);
      })

      describe('#getAddress', async () => {
        it('should return the address from storage', async () => {
          let addr = await networkStorage.getAddress('addrkey');
          addr.should.be.equal(accounts[0]);
        })
      })
    })
  
    describe('addressArrayStorage', async () => {
      beforeEach(async () => {
        await networkStorage.setAddressArray('addrskey', [accounts[0], accounts[1]]);
      })

      describe('#getAddressArray', async () => {
        it('should return the address array from storage', async () => {
          let addrArr = await networkStorage.getAddressArray('addrskey');
          addrArr.should.be.deep.equal([accounts[0], accounts[1]]);
        })
      })

      describe('#getAddressArrayItem', async () => {
        it('should return the address array item from storage', async () => {
          let item = await networkStorage.getAddressArrayItem('addrskey', 1);
          item.should.be.equal(accounts[1]);
        })
      })

      describe('#setAddressArrayItem', async () => {
        it('should set the address array item in storage at the givem index', async () => {
          await networkStorage.setAddressArrayItem('addrskey', 1, [accounts[2]]);
          let item = await networkStorage.getAddressArrayItem('addrskey', 1);
          item.should.be.equal(accounts[2]);
        })
      })

      describe('#deleteAddressArrayItem', async () => {
        it('should delete the address array item at the given index from storage', async () => {
          await networkStorage.deleteAddressArrayItem('addrskey', 1)
          let length = await networkStorage.getAddressArrayLength('addrskey')
          length.toNumber(10).should.be.equal(1)
        })
      })

      describe('#getAddressArrayLength', async () => {
        it('should return the length of the address array in storage', async () => {
          let length = await networkStorage.getAddressArrayLength('addrskey')
          length.toNumber(10).should.be.equal(2)
        })
      })
    })
  
    describe('addressToAddressStorage', async () => {
      beforeEach(async () => {
        await networkStorage.setAddressToAddress('addrtoaddrkey', accounts[0], accounts[1]);
      })

      describe('#getAddressToAddress', async () => {
        it('should return the mapped address from storage', async () => {
          let addr = await networkStorage.getAddressToAddress('addrtoaddrkey', accounts[0]);
          addr.should.be.equal(accounts[1]);
        })
      })
    })
  
    describe('addressToAddressArrayStorage', async () => {
      beforeEach(async () => {
        await networkStorage.setAddressToAddressArray('addrtoaddrskey', accounts[0], [accounts[1], accounts[2]]);
      })

      describe('#getAddressToAddressArray', async () => {
        it('should return the mapped address array from storage', async () => {
          let addrArr = await networkStorage.getAddressToAddressArray('addrtoaddrskey', accounts[0]);
          addrArr.should.be.deep.equal([accounts[1], accounts[2]]);
        })
      })
    })
  
    describe('addressToBoolStorage', async () => {
      beforeEach(async () => {
        await networkStorage.setAddressToBool('addrtoboolkey', accounts[0], true);
      })

      describe('#getAddressToBool', async () => {
        it('should return the mapped bool value from storage', async () => {
          let val = await networkStorage.getAddressToBool('addrtoboolkey', accounts[0]);
          val.should.be.equal(true);
        })
      })
    })
  
    describe('addressToUintStorage', async () => {
      beforeEach(async () => {
        await networkStorage.setAddressToUint('addrtouintkey', accounts[0], 678910);
      })

      describe('#getAddressToUint', async () => {
        it('should return the mapped uint value from storage', async () => {
          let val = await networkStorage.getAddressToUint('addrtouintkey', accounts[0]);
          val.toNumber(10).should.be.equal(678910);
        })
      })
    })
  
    describe('addressToUintArrayStorage', async () => {
      beforeEach(async () => {
        await networkStorage.setAddressToUintArray('addrtouintarrkey', accounts[0], [1, 2, 3]);
      })

      describe('#getAddressToUintArray', async () => {
        it('should return the mapped uint array from storage', async () => {
          let val = await networkStorage.getAddressToUintArray('addrtouintarrkey', accounts[0]);
          val.length.should.be.equal(3);
          val[0].toNumber(10).should.be.equal(1);
          val[1].toNumber(10).should.be.equal(2);
          val[2].toNumber(10).should.be.equal(3);
        })
      })
    })
  
    describe('boolStorage', async () => {
      beforeEach(async () => {
        await networkStorage.setBool('boolkey', true);
      })

      describe('#getBool', async () => {
        it('should return the bool value from storage', async () => {
          let val = await networkStorage.getBool('boolkey');
          val.should.be.equal(true);
        })
      })
    })
  
    describe('uintStorage', async () => {
      beforeEach(async () => {
        await networkStorage.setUint('uintkey', 123456);
      })

      describe('#getUint', async () => {
        it('should return the uint value from storage', async () => {
          let val = await networkStorage.getUint('uintkey');
          val.toNumber(10).should.be.equal(123456);
        })
      })
    })
  })
})
