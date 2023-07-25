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
  .addParam('sjReceiver', 'SJReceiver address')
  .setAction(async (_args) => {
    const SJFactory = await ethers.getContractFactory('SJFactory')
    const sjFactory = await SJFactory.attach(_args.sjFactory)

    console.log('Setting SJReceiver ...')
    const tx = await sjFactory.setSJReceiver(_args.sjReceiver)
    await tx.wait(1)
    console.log('Renouncing ownership ...')
    await sjFactory.renounceOwnership()
  })

task('deploy:SafeJunction')
  .addParam('yaho', 'Yaho address')
  .addParam('yaru', 'Yaru address')
  .setAction(async (_args) => {
    const Governance = await ethers.getContractFactory('Governance')
    const SJDispatcher = await ethers.getContractFactory('SJDispatcher')
    const SJFactory = await ethers.getContractFactory('SJFactory')
    const SJReceiver = await ethers.getContractFactory('SJReceiver')

    console.log('Deploying Governance ...')
    const governance = await Governance.deploy()
    await governance.deployTransaction.wait(1)
    console.log('Deploying SJDispatcher ...')
    const sjDispatcher = await SJDispatcher.deploy(_args.yaho, governance.address)
    await sjDispatcher.deployTransaction.wait(1)
    console.log('Deploying SJFactory ...')
    const sjFactory = await SJFactory.deploy(sjDispatcher.address)
    await sjFactory.deployTransaction.wait(1)
    console.log('Deploying SJReceiver ...')
    const sjReceiver = await SJReceiver.deploy(_args.yaru, sjFactory.address)
    await sjReceiver.deployTransaction.wait(1)
    console.log('Setting SJReceiver ...')
    const tx = await sjFactory.setSJReceiver(sjReceiver.address)
    await tx.wait(1)
    console.log('Renouncing ownership ...')
    await sjFactory.renounceOwnership()

    console.log(
      JSON.stringify({
        governance: governance.address,
        sjDispatcher: sjDispatcher.address,
        sjFactory: sjFactory.address,
        sjReceiver: sjReceiver.address
      })
    )
  })

task('deploy:SJToken')
  .addParam('sjFactory', 'SJFactory address')
  .addParam('underlyingTokenAddress', 'Underlying token address')
  .addParam('underlyingTokenName', 'Underlying token name')
  .addParam('underlyingTokenSymbol', 'Underlying token symbol')
  .addParam('underlyingTokenDecimals', 'Underlying token decimals')
  .addParam('underlyingTokenChainId', 'Underlying token chain id')
  .setAction(async (_args) => {
    const SJFactory = await ethers.getContractFactory('SJFactory')

    const sjFactory = await SJFactory.attach(_args.sjFactory)
    const transaction = await sjFactory.deploy(
      _args.underlyingTokenAddress,
      _args.underlyingTokenName,
      _args.underlyingTokenSymbol,
      _args.underlyingTokenDecimals,
      _args.underlyingTokenChainId
    )
    const receipt = await transaction.wait()
    const event = receipt.events.find(({ event }) => event === 'SJTokenDeployed')
    const { sjTokenAddress } = event.args
    console.log(
      JSON.stringify({
        sjTokenAddress,
        underlyingTokenAddress: _args.underlyingTokenAddress,
        underlyingTokenName: _args.underlyingTokenName,
        underlyingTokenSymbol: _args.underlyingTokenSymbol,
        underlyingTokenDecimals: _args.underlyingTokenDecimals,
        underlyingTokenChainId: _args.underlyingTokenChainId
      })
    )
  })
