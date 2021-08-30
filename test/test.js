const { expect } = require("chai")
const B = require("big.js")
const { waffle } = require("hardhat")
const { deployContract } = waffle
const { Signer, Wallet, utils, Contract } = require("ethers")
const sigUtil = require("eth-sig-util")
const web3Abi = require("web3-eth-abi")
const eth = require("web3-eth")
const Web3 = require("web3")
const erc20 = require("@openzeppelin/contracts/build/contracts/ERC20.json")
const _jpyx = require("../artifacts/contracts/JPYX.sol/JPYX.json")
const provider = waffle.provider
const {
  arr,
  str,
  isErr,
  to18,
  to32,
  from18,
  UINT_MAX,
  deploy,
  a,
  b,
} = require("./utils")

describe("JPYX", function () {
  let ac, jpyc, faucet, dex, jpyd, jpye, jpyx, minter
  let p1, p2
  beforeEach(async () => {
    ;[p1, p2] = await ethers.getSigners()
    jpyc = await deploy("Token", "JPYC", "JPYC", to18(10000))
    jpyd = await deploy("Token", "JPYD", "JPYD", to18(10000))
    jpye = await deploy("Token", "JPYE", "JPYE", to18(10000))
    faucet = await deploy("Faucet", to18(1000), 1)
    await jpyc.transfer(a(faucet), to18(3000))
    await jpyd.transfer(a(faucet), to18(3000))
    await jpye.transfer(a(faucet), to18(3000))
    dex = await deploy("DEX", 1000) // 10% fee
    jpyx = new Contract(await dex.token(), _jpyx.abi, p1)
    return
  })

  describe("Faucet", function () {
    it("should give out 1000 token", async () => {
      await faucet.connect(p2).get(a(jpyc))
      expect((await b(jpyc, p2)) * 1).to.equal(1000)
    })
  })
  describe("DEX", function () {
    beforeEach(async () => {
      await faucet.connect(p2).get(a(jpyc))
      await faucet.connect(p2).get(a(jpyd))
      await faucet.connect(p2).get(a(jpye))
      await jpyc.connect(p2).approve(a(dex), UINT_MAX)
      await jpyd.connect(p2).approve(a(dex), UINT_MAX)
      await jpye.connect(p2).approve(a(dex), UINT_MAX)
      await jpyx.connect(p2).approve(a(dex), UINT_MAX)
      await dex.addToken(a(jpyc), 7000)
      await dex.addToken(a(jpyd), 7000)
      await dex.addToken(a(jpye), 7000)
      await dex
        .connect(p2)
        .addLiquidity(
          [a(jpyc), a(jpyd), a(jpye)],
          [to18(100), to18(100), to18(100)]
        )
      return
    })
    it("should return JPYX for liquidity", async () => {
      expect((await b(jpyx, p2)) * 1).to.equal(300)
      return
    })

    it("should burn JPYX when removing liquidity", async () => {
      await dex
        .connect(p2)
        .removeLiquidity([a(jpyc), a(jpyd)], [to18(50), to18(50)])
      expect((await b(jpyx, p2)) * 1).to.equal(200)
    })

    it("should charge fees for unbalanced swaps", async () => {
      await dex.connect(p2).swap(a(jpyc), a(jpyd), to18(50))
      expect((await b(jpyc, p2)) * 1).to.equal(850)
      expect((await b(jpyd, p2)) * 1).to.equal(945)
    })

    it("should pay out dividend", async () => {
      await dex.connect(p2).swap(a(jpyc), a(jpyd), to18(50))
      expect(from18(await dex.getMintable(a(p2))) * 1).to.equal(5)
      await dex.connect(p2).withdrawInterests()
      expect((await b(jpyx, p2)) * 1).to.equal(305)
    })
  })
})
