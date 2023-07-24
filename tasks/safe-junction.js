task('deploy:Governance').setAction(async () => {
  const Governance = await ethers.getContractFactory('Governance')
  console.log('Deploying Governance ...')
  const governance = await Governance.deploy()
  console.log('Governance deployed at:', governance.address)
})

task('deploy:SJDispatcher')
  .addParam('yaho', 'Yaho address')
  .addParam('governance', 'Governance address')
  .setAction(async (_args) => {
    const SJDispatcher = await ethers.getContractFactory('SJDispatcher')
    console.log('Deploying SJDispatcher ...')
    const sjDispatcher = await SJDispatcher.deploy(_args.yaho, _args.governance)
    console.log('SJDispatcher deployed at:', sjDispatcher.address)
  })

task('deploy:SJFactory')
  .addParam('sjDispatcher', 'SJDispatcher address')
  .setAction(async (_args) => {
    const SJFactory = await ethers.getContractFactory('SJFactory')
    console.log('Deploying SJFactory ...')
    const sjFactory = await SJFactory.deploy(_args.sjDispatcher)
    console.log('SJFactory deployed at:', sjFactory.address)
  })

task('deploy:SJReceiver')
  .addParam('yaru', 'Yaru address')
  .addParam('sjFactory', 'SJFactory address')
  .setAction(async (_args) => {
    const SJReceiver = await ethers.getContractFactory('SJReceiver')
    console.log('Deploying SJReceiver ...')
    const sjReceiver = await SJReceiver.deploy(_args.yaru, _args.sjFactory)
    console.log('SJReceiver deployed at:', sjReceiver.address)
  })

task('deploy:FinalizeMissingVariables')
  .addParam('sjFactory', 'SJFactory address')
  .addParam('sjreceiver', 'SJReceiver address')
  .setAction(async (_args) => {
    const SJFactory = await ethers.getContractFactory('SJFactory')
    const sjFactory = await SJFactory.attach(_args.sjFactory)

    console.log('Setting SJReceiver ...')
    await sjFactory.setSJReceiver(_args.sjreceiver)
    console.log('Renouncing ownership ...')
    await sjFactory.renounceOwnership()
  })

task('deploy:SJToken')
  .addParam('sjFactory', 'SJFactory address')
  .addParam('underlyingTokenAddress', 'Underlying token address')
  .addParam('underlyingTokenName', 'Underlying token name')
  .addParam('underlyingTokenSymbol', 'Underlying token symbol')
  .addParam('underlyingTokenDecimals', 'Underlying token decimals')
  .addParam('underlyingTokenChainid', 'Underlying token chain id')
  .setAction(async (_args) => {
    const SJToken = await ethers.getContractFactory('SJToken')
    const SJFactory = await ethers.getContractFactory('SJFactory')

    const sjFactory = await SJFactory.attach(_args.sjFactory)
    const transaction = await sjFactory.deploy(
      _args.underlyingTokenAddress,
      _args.underlyingTokenName,
      _args.underlyingTokenSymbol,
      _args.underlyingTokenDecimals,
      _args.underlyingTokenChainid
    )
    const receipt = await transaction.wait()
    const event = receipt.events.find(({ event }) => event === 'SJTokenDeployed')
    const { sjTokenAddress } = event.args
    return await SJToken.attach(sjTokenAddress)
  })
