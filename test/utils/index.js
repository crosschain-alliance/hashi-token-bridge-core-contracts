module.exports.getFakeMessages = (_hashiMessage, _sjMessage, _destinationChainId) => {
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

module.exports.getHashiMessageFromTransaction = async (_transaction) => {
  const receipt = await (await _transaction).wait()
  const event = receipt.events.find(
    ({ topics }) => topics[0] === '0xd322231cb78b8ca0ff617b695a9c8b51945673de909fa143c9bb240989bbad21'
  ) // event DispatchedMessage(Message message); just for testing
  const [hashiMessage] = ethers.utils.defaultAbiCoder.decode(['(address,uint256,bytes)'], event.data)
  return hashiMessage
}
