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
  // it('should return campaign something when created', async function () {
  //   const accounts = await ethers.getSigners();
  //   const Staking = await ethers.getContractFactory('StakingEarnBoxDKT');
  //   const staking = await Staking.deploy(accounts[0].address);
  //   const blocktime = await staking.getBlockTime();
  //   let b = {
  //     startDate: 1642411525087,
  //     endDate: 1645006941472,
  //     returnRate: 1,
  //     maxAmountOfToken: ethers.utils.parseUnits((400000).toString(), 18),
  //     stakedAmountOfToken: 0,
  //     limitStakingAmountForUser: ethers.utils.parseUnits((1000).toString(), 18),
  //     tokenAddress: '0x1f10F3Ba7ACB61b2F50B9d6DdCf91a6f787C0E82',
  //     maxNumberOfBoxes: 32000,
  //     rewardPhaseBoxId: 1,
  //     numberOfLockDays: 15,
  //   };
  //   const r = await (await staking.createNewStakingCampaign(config)).wait();
  //   const filteredEvent = <any>r.events?.filter((e) => e.event === 'NewCampaign');
  //   expect(filteredEvent.length).to.equal(1);
  // });
});
