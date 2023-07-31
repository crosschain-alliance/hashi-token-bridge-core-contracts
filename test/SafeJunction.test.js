const { expect } = require('chai')
const { ethers } = require('hardhat')

let governanceNative,
  yahoNative,
  yaruNative,
  sjDispatcherNative,
  sjFactoryNative,
  token,
  sjTokenNative,
  currentChainId,
  owner,
  user1,
  governanceHost,
  yahoHost,
  yaruHost,
  sjDispatcherHost,
  sjFactoryHost,
  sjReceiverNative,
  sjReceiverHost,
  sjTokenHost

const DESTINATION_CHAIN_ID = 2

const deploySJToken = async (
  _underlyingTokenAddress,
  _underlyingTokenName,
  _underlyingTokenSymbol,
  _underlyingTokenDecimals,
  _underlyingTokenChainId,
  { sjFactory }
) => {
  const SJToken = await ethers.getContractFactory('SJToken')
  const transaction = await sjFactory.deploy(
    _underlyingTokenAddress,
    _underlyingTokenName,
    _underlyingTokenSymbol,
    _underlyingTokenDecimals,
    _underlyingTokenChainId
  )
  const receipt = await transaction.wait()
  const event = receipt.events.find(({ event }) => event === 'SJTokenDeployed')
  const { sjTokenAddress } = event.args
  return await SJToken.attach(sjTokenAddress)
}

const getHashiMessageFromTransaction = async (_transaction) => {
  const receipt = await (await _transaction).wait()
  const event = receipt.events.find(
    ({ topics }) => topics[0] === '0xd322231cb78b8ca0ff617b695a9c8b51945673de909fa143c9bb240989bbad21'
  ) // event DispatchedMessage(Message message); just for testing
  const [hashiMessage] = ethers.utils.defaultAbiCoder.decode(['(address,uint256,bytes)'], event.data)
  return hashiMessage
}

const getSJMessageFromTransaction = async (_transaction) => {
  const receipt = await (await _transaction).wait()
  const event = receipt.events.find(
    ({ topics }) => topics[0] === '0x1865bfcee18bcdac6c84bf3dc444b4b79b552decae460b3a41279268bcf9632f'
  )
  const [sjMessage] = ethers.utils.defaultAbiCoder.decode(
    ['(bytes32,uint256,uint256,uint256,uint256,address,address,address,uint8,string,string)'],
    event.data
  )
  return sjMessage
}

const getFakeMessages = (_hashiMessage, _sjMessage, _destinationChainId = DESTINATION_CHAIN_ID) => {
  const fakeSJMessage = _sjMessage.slice()
  fakeSJMessage[2] = _destinationChainId
  const fakeHashiMessageData =
    _hashiMessage[2].slice(0, 262) + `000${_destinationChainId}` + _hashiMessage[2].slice(266, _hashiMessage[2].length)
  const fakeHashiMessage = _hashiMessage.slice()
  fakeHashiMessage[2] = fakeHashiMessageData

  return {
    fakeSJMessage,
    fakeHashiMessage
  }
}

describe('SafeJunction', () => {
  beforeEach(async () => {
    currentChainId = (await ethers.provider.getNetwork()).chainId

    const Governance = await ethers.getContractFactory('Governance')
    const SJDispatcher = await ethers.getContractFactory('SJDispatcher')
    const SJFactory = await ethers.getContractFactory('SJFactory')
    const SJReceiver = await ethers.getContractFactory('SJReceiver')
    const MockYaho = await ethers.getContractFactory('MockYaho')
    const MockYaru = await ethers.getContractFactory('MockYaru')
    const Token = await ethers.getContractFactory('Token')

    const signers = await ethers.getSigners()
    owner = signers[0]
    user1 = signers[1]

    /// N A T I V E
    governanceNative = await Governance.deploy()
    yahoNative = await MockYaho.deploy()
    yaruNative = await MockYaru.deploy()
    sjDispatcherNative = await SJDispatcher.deploy(yahoNative.address, governanceNative.address)
    sjFactoryNative = await SJFactory.deploy(sjDispatcherNative.address)
    sjReceiverNative = await SJReceiver.deploy(yaruNative.address, sjFactoryNative.address)

    // H O S T
    governanceHost = await Governance.deploy()
    yahoHost = await MockYaho.deploy()
    yaruHost = await MockYaru.deploy()
    sjDispatcherHost = await SJDispatcher.deploy(yahoHost.address, governanceHost.address)
    sjFactoryHost = await SJFactory.deploy(sjDispatcherHost.address)
    sjReceiverHost = await SJReceiver.deploy(yaruHost.address, sjFactoryHost.address)

    await sjFactoryNative.setSJReceiver(sjReceiverNative.address)
    await sjFactoryHost.setSJReceiver(sjReceiverHost.address)
    await sjFactoryNative.renounceOwnership()
    await sjFactoryHost.renounceOwnership()

    await governanceHost.setSJReceiverByChainId(currentChainId, sjReceiverNative.address)
    await governanceNative.setSJReceiverByChainId(DESTINATION_CHAIN_ID, sjReceiverHost.address)

    token = await Token.deploy('Token', 'TKN', ethers.utils.parseEther('2000000000'))

    sjTokenNative = await deploySJToken(
      token.address,
      await token.name(),
      await token.symbol(),
      await token.decimals(),
      currentChainId,
      {
        sjFactory: sjFactoryNative
      }
    )

    sjTokenHost = await deploySJToken(
      token.address,
      await token.name(),
      await token.symbol(),
      await token.decimals(),
      DESTINATION_CHAIN_ID,
      {
        sjFactory: sjFactoryHost
      }
    )
  })

  it('should be able to pegin a *Token', async () => {
    const amount = ethers.utils.parseEther('100')
    const balancePre = await token.balanceOf(owner.address)
    await token.approve(sjTokenNative.address, amount)

    const tx = sjTokenNative.xTransfer(2, user1.address, amount, 0)
    await expect(tx).to.emit(sjDispatcherNative, 'MessageDispatched')

    const balancePost = await token.balanceOf(owner.address)
    expect(balancePost).to.be.eq(balancePre.sub(amount))

    const sjMessage = await getSJMessageFromTransaction(tx)
    const hashiMessage = await getHashiMessageFromTransaction(tx)
    // trick to enable xMint since both sjTokens are deployed on the same chain
    const { fakeHashiMessage, fakeSJMessage } = getFakeMessages(hashiMessage, sjMessage)

    await expect(yaruHost.executeMessage(fakeHashiMessage))
      .to.emit(sjReceiverHost, 'MessageProcessed')
      .withArgs(fakeSJMessage)
    expect(await sjTokenHost.balanceOf(user1.address)).to.be.eq(amount)
  })
})
