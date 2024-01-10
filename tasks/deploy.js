task('deploy:SJLZEndpoint')
  .addParam('yaho', 'Yaho address')
  .addParam('yaru', 'Yaru address')
  .addParam('sourceChainId', 'Yaru address')
  .setAction(async (_args) => {
    const SJLZEndpoint = await ethers.getContractFactory('SJLZEndpoint')
    console.log('Deploying SJLZEndpoint ...')
    const sjLzEndpoint = await SJLZEndpoint.deploy(_args.yaho, _args.yaru, _args.sourceChainId)
    console.log('SJLZEndpoint deployed at:', sjLzEndpoint.address)
  })

task('deploy:SJToken')
  .addParam('underlyingTokenAddress', 'Underlying token address')
  .addParam(
    'isNative',
    'boolean to indicate if the chain where is deployed is the same chain of underlyingTokenAddress'
  )
  .addParam('name', 'Name')
  .addParam('symbol', 'Symbol')
  .addParam('sharedDecimals', 'Shared decimals')
  .addParam('lzEndpoint', 'Layer Zero endpoint')
  .setAction(async (_args) => {
    const SJToken = await ethers.getContractFactory('SJToken')
    console.log('Deploying SJToken ...')
    const sjToken = await SJToken.deploy(
      _args.underlyingTokenAddress,
      _args.isNative,
      _args.name,
      _args.symbol,
      _args.sharedDecimals,
      _args.lzEndpoint
    )
    console.log('SJToken deployed at:', sjToken.address)
  })
