const { expect } = require('chai')
const { ethers } = require('hardhat')

let yahoNative,
  yaruNative,
  token,
  currentChainId,
  owner,
  user1,
  yahoHost,
  yaruHost,
  sjTokenHost,
  sjTokenNative,
  sjLzEndpointNative,
  sjLzEndpointHost

const DESTINATION_CHAIN_ID = 2

const getHashiMessageFromTransaction = async (_transaction) => {
  const receipt = await (await _transaction).wait()
  const event = receipt.events.find(
    ({ topics }) => topics[0] === '0xd322231cb78b8ca0ff617b695a9c8b51945673de909fa143c9bb240989bbad21'
  ) // event DispatchedMessage(Message message); just for testing
  const [hashiMessage] = ethers.utils.defaultAbiCoder.decode(['(address,uint256,bytes)'], event.data)
  return hashiMessage
}

const getFakeHashiMessage = (_hashiMessage, _chainId) => {
  const fakeHashiMessageData =
    _hashiMessage[2].slice(0, 10 + 60) +
    `00${ethers.utils.hexlify(_chainId).slice(2)}0` +
    _hashiMessage[2].slice(0 + 10 + 65, _hashiMessage[2].length)
  const fakeHashiMessage = _hashiMessage.slice()
  fakeHashiMessage[2] = fakeHashiMessageData
  return fakeHashiMessage
}

describe('SafeJunction', () => {
  beforeEach(async () => {
    currentChainId = (await ethers.provider.getNetwork()).chainId

    const MockYaho = await ethers.getContractFactory('MockYaho')
    const MockYaru = await ethers.getContractFactory('MockYaru')
    const Token = await ethers.getContractFactory('Token')
    const SJToken = await ethers.getContractFactory('SJToken')
    const SJLZEndpoint = await ethers.getContractFactory('SJLZEndpoint')

    const signers = await ethers.getSigners()
    owner = signers[0]
    user1 = signers[1]

    /// N A T I V E
    yahoNative = await MockYaho.deploy()
    yaruNative = await MockYaru.deploy()
    sjLzEndpointNative = await SJLZEndpoint.deploy(yahoNative.address, yaruNative.address, DESTINATION_CHAIN_ID)

    // H O S T
    yahoHost = await MockYaho.deploy()
    yaruHost = await MockYaru.deploy()
    sjLzEndpointHost = await SJLZEndpoint.deploy(yahoHost.address, yaruHost.address, currentChainId)

    token = await Token.deploy('Token', 'TKN', ethers.utils.parseEther('2000000000'))
    sjTokenNative = await SJToken.deploy(
      token.address,
      true,
      await token.name(),
      await token.symbol(),
      10,
      sjLzEndpointNative.address
    )
    sjTokenHost = await SJToken.deploy(
      token.address,
      false,
      await token.name(),
      await token.symbol(),
      10,
      sjLzEndpointHost.address
    )

    await sjTokenNative.setTrustedRemoteAddress(DESTINATION_CHAIN_ID, sjTokenHost.address)
    await sjTokenHost.setTrustedRemoteAddress(currentChainId, sjTokenNative.address)

    await sjTokenNative.setMinDstGas(DESTINATION_CHAIN_ID, 0, 100000)
    await sjTokenHost.setMinDstGas(currentChainId, 0, 100000)
    await sjTokenNative.setMinDstGas(DESTINATION_CHAIN_ID, 1, 100000)
    await sjTokenHost.setMinDstGas(currentChainId, 1, 100000)

    await sjLzEndpointNative.setOppositeLzEndpoint(sjLzEndpointHost.address)
    await sjLzEndpointHost.setOppositeLzEndpoint(sjLzEndpointNative.address)
  })

  it('should be able to mint and burn a SJ token', async () => {
    const amount = ethers.utils.parseEther('100')
    await token.approve(sjTokenNative.address, amount)
    let tx = await sjTokenNative.xTransfer(DESTINATION_CHAIN_ID, user1.address, amount)
    expect(tx)
      .to.emit(sjTokenNative, 'Transfer')
      .withArgs('0x0000000000000000000000000000000000000000', owner.address, amount)
      .and.to.emit(sjTokenNative, 'Transfer')
      .withArgs(owner.address, '0x0000000000000000000000000000000000000000', amount)

    let hashiMessage = await getHashiMessageFromTransaction(tx)
    await expect(yaruHost.executeMessage(hashiMessage, sjLzEndpointNative.address))
      .to.emit(sjTokenHost, 'Transfer')
      .withArgs('0x0000000000000000000000000000000000000000', user1.address, amount)

    tx = await sjTokenHost.connect(user1).xTransfer(currentChainId, owner.address, amount)
    await expect(tx)
      .to.emit(sjTokenHost, 'Transfer')
      .withArgs(user1.address, '0x0000000000000000000000000000000000000000', amount)

    hashiMessage = await getHashiMessageFromTransaction(tx)
    const fakeHashiMessage = getFakeHashiMessage(hashiMessage, DESTINATION_CHAIN_ID)
    await expect(yaruNative.executeMessage(fakeHashiMessage, sjLzEndpointHost.address))
      .to.emit(sjTokenNative, 'Transfer')
      .withArgs('0x0000000000000000000000000000000000000000', owner.address, amount)
  })
})
