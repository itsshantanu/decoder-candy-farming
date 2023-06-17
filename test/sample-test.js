const { ethers } = require('hardhat');
const { expect } = require('chai');

const { Contract, BigNumber } = require('ethers');
const { SignerWithAddress } = require('@nomiclabs/hardhat-ethers/signers');
const { time } = require('@openzeppelin/test-helpers');

describe('CandyFarm', () => {

  let owner // : SignerWithAddress;

  // owner accounts, crypto acthors
  let jane;
  let mike;

  // response
  let res;

  let candyFarm; //: Contract;
  let candyToken; //: Contract;
  let mockDai; //: Contract;

  const daiAmount = ethers.utils.parseEther('25000');

  beforeEach(async () => {
    /**
     * get smart contracts
     */
    const CandyFarm = await ethers.getContractFactory('CandyFarm');
    const CandyToken = await ethers.getContractFactory('CandyToken');
    const MockDai = await ethers.getContractFactory('MockDai');

    /**
     * deploy mockDai contract
     */
    mockDai = await MockDai.deploy("MockDai", "mDai");

    [owner, jane, mike] = await ethers.getSigners();

    await Promise.all([
      mockDai.mint(owner.address, daiAmount),
      mockDai.mint(jane.address, daiAmount),
      mockDai.mint(mike.address, daiAmount)
    ]);

    /**
     * deploy candyToken contract
     */
    candyToken = await CandyToken.deploy();

    /**
     * deploy candyFarm contract
     */
    candyFarm = await CandyFarm.deploy(mockDai.address, candyToken.address);
  })

  describe('Init', async () => {
    it('should initialize', async () => {
      /**
       * verfy what all is initialized okay
       */
      expect(candyToken).to.be.ok;
      expect(candyToken).to.be.ok;
      expect(mockDai).to.be.ok;
    })
  })

  /**
   * here's initialize testing for function Stake()
   */
  describe('Stake', async () => {
    it('should accept DAI and update mapping', async () => {
      /// parse to ether quantity for transfer
      let toTransfer = ethers.utils.parseEther('100');

      /// send DAI to account
      await mockDai.connect(jane).approve(candyFarm.address, toTransfer);

      // expectative of test, return the update of address in mapping
      expect(await candyFarm.isStaking(jane.address));

      // expect return of mapping address to false
      expect(await candyFarm.isStaking(jane.address)).to.eq(false);

      expect(await candyFarm.connect(jane).stake(toTransfer)).to.be.ok;

      expect(await candyFarm.stakingBalance(jane.address)).to.eq(toTransfer);

      expect(await candyFarm.isStaking(jane.address)).to.eq(true);
    });

    it('should update balance with multiple stakes', async () => {
      /// parse to ether quantity for transfer
      let toTransfer = ethers.utils.parseEther('100');

      /// approve send of tokens
      await mockDai.connect(jane).approve(candyFarm.address, toTransfer);

      /// stake tokens sended
      await candyFarm.connect(jane).stake(toTransfer);

      /// send again quantity of tokens
      await mockDai.connect(jane).approve(candyFarm.address, toTransfer);

      /// stake tokens sended again
      await candyFarm.connect(jane).stake(toTransfer);

      /// expectative of test, return a balance updated later of make more of one stake
      expect(await candyFarm.stakingBalance(jane.address))
        .to.eq(ethers.utils.parseEther('200'));
    });

    it('should revert with not enough funds', async () => {
      let toTransfer = ethers.utils.parseEther('1000000');
      await mockDai.approve(candyFarm.address, toTransfer);

      // await expect(candyFarm.connect(mike).stake(toTransfer))
      //   .to.be.revertedWith('You cannot stake zero tokens');
      await candyFarm.connect(mike).stake(toTransfer);
    })

    it('should revert with 0 tokens as a stake', async () => {
      let toTransfer = ethers.utils.parseEther('0');

      await mockDai.approve(candyFarm.address, toTransfer);

      // await expect(candyFarm.connect(jane).stake(toTransfer))
      //   .to.be.revertedWith('You cannot stake zero tokens');

        await candyFarm.connect(jane).stake(toTransfer);

    });
  });

  describe('Unstake', async () => {
    /// we stake before run test of unstake
    beforeEach(async () => {
      /// parse quantity to ethers
      let toTransfer = ethers.utils.parseEther('100');
      /// approve send of tokens
      await mockDai.connect(jane).approve(candyFarm.address, toTransfer);
      /// stake of tokens
      await candyFarm.connect(jane).stake(toTransfer);
    })

    it('should unstake balance from user', async () => {
      /// parse quantity to ethers
      let toTransfer = ethers.utils.parseEther('100');
      /// unstake tokens
      await candyFarm.connect(jane).unstake(toTransfer);

      /// request balance of subject in staking contract
      res = await candyFarm.stakingBalance(jane.address);

      // expect later of unstake balance of subject from contract, returns me in 0
      expect(Number(res)).to.eq(0);

      expect(await candyFarm.isStaking(jane.address)).to.eq(false);

    })
  });

  // describe.skip('WithdrawYield', async () => {
  //   beforeEach(async () => {
  //     await candyToken.transferOwnership(candyFarm.address);
  //     let toTransfer = ethers.utils.parseEther('10');
  //     await mockDai.connect(jane).approve(candyFarm.address, toTransfer);
  //     await candyFarm.connect(jane).stake(toTransfer);
  //   });

  //   it("should return correct yield time", async () => {
  //     let timeStart = await candyFarm.startTime(jane.address)
  //     expect(Number(timeStart))
  //       .to.be.greaterThan(0)

  //     // Fast-forward time
  //     await time.increase(86400)

  //     expect(await candyFarm.calculateYieldTime(jane.address))
  //       .to.eq((86400))
  //   });

  //   it("should mint correct token amount in total supply and user", async () => {
  //     await time.increase(86400)

  //     let _time = await candyFarm.calculateYieldTime(jane.address)
  //     let formatTime = _time / 86400
  //     let staked = await candyFarm.stakingBalance(jane.address)
  //     let bal = staked * formatTime
  //     let newBal = ethers.utils.formatEther(bal.toString())
  //     let expected = Number.parseFloat(newBal).toFixed(3)

  //     await candyFarm.connect(jane).withdrawYield()

  //     res = await candyToken.totalSupply()
  //     let newRes = ethers.utils.formatEther(res)
  //     let formatRes = Number.parseFloat(newRes).toFixed(3).toString()

  //     expect(expected)
  //       .to.eq(formatRes)

  //     res = await candyToken.balanceOf(jane.address)
  //     newRes = ethers.utils.formatEther(res)
  //     formatRes = Number.parseFloat(newRes).toFixed(3).toString()

  //     expect(expected)
  //       .to.eq(formatRes)
  //   });

  //   it("should update yield balance when unstaked", async () => {
  //     await time.increase(86400)
  //     await candyFarm.connect(jane).unstake(ethers.utils.parseEther("5"))

  //     res = await candyFarm.candyBalance(jane.address)
  //     expect(Number(ethers.utils.formatEther(res)))
  //       .to.be.approximately(10, .001)
  //   });
  // })
})