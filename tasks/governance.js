task(
  'governance:addSourceAdapterByChainid',
  'Add a sourceAdapter to be used when a certain chainIs is used as destination chain id'
)
  .addParam('governance', 'Governance address')
  .addParam('sourceAdapter', 'Source Adapter address')
  .addParam('chainId', 'Destination chain id')
  .setAction(async (_args) => {
    const Governance = await ethers.getContractFactory('Governance')
    const governance = await Governance.attach(_args.governance)
    console.log('Adding source adapter ...')
    await governance.addSourceAdapterByChainid(_args.chainId, _args.sourceAdapter)
  })

task(
  'governance:addDestinationAdapterByChainid',
  'Add a destinationAdapter to be used when a certain chainIs is used as destination chain id'
)
  .addParam('governance', 'Governance address')
  .addParam('destinationAdapter', 'Destination Adapter address')
  .addParam('chainId', 'Destination chain id')
  .setAction(async (_args) => {
    const Governance = await ethers.getContractFactory('Governance')
    const governance = await Governance.attach(_args.governance)
    console.log('Adding destination adapter ...')
    await governance.addDestinationAdapterByChainid(_args.chainId, _args.destinationAdapter)
  })

task('governance:setSJDispatcherByChainId')
  .addParam('governance', 'Governance address')
  .addParam('sjDispatcher', 'SJDispatcher address corresponding on the specified chain id')
  .addParam('chainId', 'chain id')
  .setAction(async (_args) => {
    const Governance = await ethers.getContractFactory('Governance')
    const governance = await Governance.attach(_args.governance)
    console.log('Setting SJDispatcher ...')
    await governance.setSJDispatcherByChainId(_args.chainId, _args.sjDispatcher)
  })

task('governance:setSJReceiverByChainId')
  .addParam('governance', 'Governance address')
  .addParam('sjReceiver', 'SJReceiver address corresponding on the specified chain id')
  .addParam('chainId', 'chain id')
  .setAction(async (_args) => {
    const Governance = await ethers.getContractFactory('Governance')
    const governance = await Governance.attach(_args.governance)
    console.log('Setting JSReceiver ...')
    await governance.setSJReceiverByChainId(_args.chainId, _args.sjReceiver)
  })
