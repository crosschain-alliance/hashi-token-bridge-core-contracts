const { expect } = require('chai')
const { ethers } = require('hardhat')

const { getHashiMessageFromTransaction, getFakeMessages } = require('./utils')

const DESTINATION_CHAIN_ID = 2

let owner,
  xERC20Factory,
  token,
  xToken,
  xERC20Lockbox,
  nativeSjRouter,
  hostSjRouter,
  yahoNative,
  yaruNative,
  yahoHost,
  yaruHost

const deployXToken = async (_name, _symbol, { xERC20Factory }) => {
  const XERC20 = await ethers.getContractFactory('XERC20')
  const xTokenAddress = await xERC20Factory.callStatic.deployXERC20(_name, _symbol, [], [], [])
  await xERC20Factory.deployXERC20(_name, _symbol, [], [], [])
  return await XERC20.attach(xTokenAddress)
}

const deployXERC20Lockbox = async (_xTokenAddress, _baseTokenAddress, { xERC20Factory }) => {
  const XERC20Lockbox = await ethers.getContractFactory('XERC20Lockbox')
  const lockboxAddress = await xERC20Factory.callStatic.deployLockbox(_xTokenAddress, _baseTokenAddress, false)
  await xERC20Factory.deployLockbox(_xTokenAddress, _baseTokenAddress, false)
  return await XERC20Lockbox.attach(lockboxAddress)
}

const getSJMessageFromTransaction = async (_transaction) => {
  const receipt = await (await _transaction).wait()
  const event = receipt.events.find(
    ({ topics }) => topics[0] === '0x875408b8f2284121fa02d156a1c27bb49a7f6a924bd8c2a729024e4094445dfa'
  )
  const [sjMessage] = ethers.utils.defaultAbiCoder.decode(
    ['(bytes32,uint256,uint256,uint256,uint256,address,address,address,string,string)'],
    event.data
  )
  return sjMessage
}

describe('SafeJunction-XERC20', () => {
  beforeEach(async () => {
    const signers = await ethers.getSigners()
    owner = signers[0]

    const XERC20Factory = await ethers.getContractFactory('XERC20Factory')
    const Token = await ethers.getContractFactory('Token')
    const SJRouter = await ethers.getContractFactory('SJRouter')
    const Yaho = await ethers.getContractFactory('MockYaho')
    const Yaru = await ethers.getContractFactory('MockYaru')

    xERC20Factory = await XERC20Factory.deploy()

    yahoNative = await Yaho.deploy()
    yaruNative = await Yaru.deploy()
    yahoHost = await Yaho.deploy()
    yaruHost = await Yaru.deploy()

    nativeSjRouter = await SJRouter.deploy(yahoNative.address, yaruNative.address, xERC20Factory.address)
    hostSjRouter = await SJRouter.deploy(yahoHost.address, yaruHost.address, xERC20Factory.address)

    await nativeSjRouter.setOppositeSjRouter(hostSjRouter.address)
    await hostSjRouter.setOppositeSjRouter(nativeSjRouter.address)
    await nativeSjRouter.renounceOwnership()
    await hostSjRouter.renounceOwnership()

    const amount = ethers.utils.parseEther('2000000000')
    token = await Token.deploy('Token', 'TKN', amount)
    xToken = await deployXToken('xToken', 'XTKN', { xERC20Factory })
    xERC20Lockbox = await deployXERC20Lockbox(xToken.address, token.address, { xERC20Factory })

    await token.approve(xERC20Lockbox.address, amount)
    await xERC20Lockbox.deposit(amount)
    await xToken.setLimits(nativeSjRouter.address, amount, amount)
    await xToken.setLimits(hostSjRouter.address, amount, amount)
  })

  it('should be able to mint an xERC20 token', async () => {
    const amount = ethers.utils.parseEther('10')
    await xToken.approve(nativeSjRouter.address, amount)
    const tx = nativeSjRouter.xTransfer(
      DESTINATION_CHAIN_ID,
      owner.address,
      amount,
      0,
      owner.address,
      await xToken.name(),
      await xToken.symbol()
    )
    await expect(tx)
      .to.emit(nativeSjRouter, 'MessageDispatched')
      .and.to.emit(xToken, 'Transfer')
      .withArgs(owner.address, '0x0000000000000000000000000000000000000000', amount)

    const sjMessage = await getSJMessageFromTransaction(tx)
    const hashiMessage = await getHashiMessageFromTransaction(tx)
    // trick to enable mint since both xTokens are deployed on the same chain
    const { fakeHashiMessage, fakeSJMessage } = getFakeMessages(hashiMessage, sjMessage, DESTINATION_CHAIN_ID)

    await expect(yaruHost.executeMessage(fakeHashiMessage, nativeSjRouter.address))
      .to.emit(hostSjRouter, 'MessageProcessed')
      .withArgs(fakeSJMessage)
      .and.to.emit(xToken, 'Transfer')
      .withArgs('0x0000000000000000000000000000000000000000', owner.address, amount)
  })
})
