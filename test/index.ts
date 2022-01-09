import { expect } from 'chai';
import { ethers } from 'hardhat';

// describe('Greeter', function () {
//   it("Should return the new greeting once it's changed", async function () {
//     const Greeter = await ethers.getContractFactory('Greeter');
//     const greeter = await Greeter.deploy('Hello, world!');
//     await greeter.deployed();

//     expect(await greeter.greet()).to.equal('Hello, world!');

//     const setGreetingTx = await greeter.setGreeting('Hola, mundo!');

//     // wait until the transaction is mined
//     await setGreetingTx.wait();

//     expect(await greeter.greet()).to.equal('Hola, mundo!');
//   });
// });

describe('Staking', function () {
  it("Should return the new greeting once it's changed", async function () {
    const accounts = await ethers.getSigners();
    const Staking = await ethers.getContractFactory('StakingEarnBoxDKT');
    const staking = await Staking.deploy(accounts[0].address);
    await staking.deployed();

    // wait until the transaction is mined
    // await setGreetingTx.wait();

    expect(await staking.greet()).to.equal(accounts[0].address);
  });
  it('should return campaign something when created', async function () {
    const accounts = await ethers.getSigners();
    const Staking = await ethers.getContractFactory('StakingEarnBoxDKT');
    const staking = await Staking.deploy(accounts[0].address);
    const blocktime = await staking.getBlockTime();
    const config = {
      startDate: blocktime.add(Math.round(1 * 86400)),
      endDate: blocktime.add(Math.round(30 * 86400)),
      returnRate: 1,
      maxAmountOfToken: 4000000,
      stakedAmountOfToken: 0,
      limitStakingAmountForUser: 500,
      tokenAddress: '0xa6f79B60359f141df90A0C745125B131cAAfFD12',
      maxNumberOfBoxes: 32000,
      numberOfLockDays: 15,
    };
    const r = await (await staking.createNewStakingCampaign(config)).wait();
    const filteredEvent = <any>r.events?.filter((e) => e.event === 'NewCampaign');
    expect(filteredEvent.length).to.equal(1);
  });
});
