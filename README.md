# Safe Junction Core Contracts (OFT)


[![GitHub license](https://img.shields.io/badge/license-TODO.svg)](https://github.com/safe-junction/sj-core-contracts/blob/main/LICENSE)

![alt text](./resources/diagram.png)

## Overview

Safe Junction changes the perspective of bridges by positioning itself on a higher level, aiming to provide a universal cross-chain experience by using multiple oracles for compounded security and being faster than others thanks to its Fast Lane feature.

Unlike traditional bridging solutions, Safe Junction leverages the functionality of existing bridges, using them as oracles to authenticate, verify and execute cross-chain operations as instructed by users on different blockchains. By using several bridges as oracles, Safe Junction achieves cross-chain asset transfer validations in a redundant, universal and safer way. It is designed to be chain agnostic and simple to audit. Yet, it achieves speed, thanks to a built-in optional feature called the Fast Lane.

Today the bridging ecosystem suffers from excessive fragmentation. Safe Junction powers *Tokens (“Star Tokens”) to tackle this very problem. These tokens inherit the properties described above to provide a superior cross-chain experience.

In the worst case, the system's speed is equivalent to that of the slowest oracle in the network. However, when the Fast Lane functionality gets used, it overcomes this drawback and enables much higher speed: market makers can process cross-chain transfers in advance, providing their liquidity in response to a user request, and then securely reclaim the liquidity (plus a service fee) once all oracles have processed the cross-chain request at their standard speed.

It is important to understand how Safe Junction differs from existing cross-chain solutions (bridges, aggregators, etc.) in terms of security (which is additive), speed (via Fast Lane MM intervention) and compatibility (as it aims to be 100% agnostic, and not just EVM compatible).

&nbsp;

***

&nbsp;

## How it works

1. Deploy two `SJLZEndpoints`, one on each of the source and destination chains. SJLZEndpoint acts as a Layer Zero compatible endpoint, utilizing Hashi for cross-chain message propagation.

2. Deploy two `SJToken` contracts, following the `OFT` (Omnichain Fungible Token) standard. One contract on the source chain and the other on the destination chain. Reference the [OFT documentation](https://layerzero.gitbook.io/docs/evm-guides/layerzero-omnichain-contracts/oft/oftv2) for guidance.

3. Execute `xTransfer` on the SJToken to start a cross-chain minting or burning process. Ensure you approve the required token amount for wrapping if you are on the native chain.

4. The `xTransfer` function internally calls `_send`, a function defined in the OFT standard. This function, in turn, invokes the `send` function on `SJLZEndpoint` with a specific payload.

5. The `SJLZEndpoint` employs `Yah` to relay the message across chains using the Hashi Message Relays.

6. Each involved bridge processes the message and stores the hash of the message in its adapter.

7. After all bridges have processed the message, Hashi executes it.

8. Upon execution, `Yaru` calls `SJLZEndpoint.receivePayload`, which then calls `lzReceive` on the host SJToken. The `lzReceive` implemented within the OFT contract, mints the corresponding amount of tokens.


&nbsp;

***

&nbsp;

## Installation and Usage

### Prerequisites

Ensure you have [Node.js](https://nodejs.org/) and [npm](https://www.npmjs.com/) installed.

### Clone the Repository

```bash
git clone https://github.com/safe-junction/sj-core-contracts.git
cd sj-core-contracts
```

### Install Dependencies

```bash
npm install
```

### Compile Contracts

```bash
npm run compile
```

&nbsp;

***

&nbsp;

## Testing

Before running the tests, make sure you've set up the required environment variables.

```bash
npm run test
```

&nbsp;

***

&nbsp;

## Contribution

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

&nbsp;

***

&nbsp;

## License

This project is licensed under the TODO License - see the [LICENSE](LICENSE) file for details.


&nbsp;

***

&nbsp;
## Contact

For any inquiries, issues, or feedback, please [raise an issue on GitHub](https://github.com/safe-junction/sj-core-contracts/issues) or contact the team through our [official website](#).

&nbsp;

***

&nbsp;

## ⚠️ Security and Development Disclaimer

All contracts in this repository are still under active development. Although Safe Junction endeavors to ensure the highest level of security and reliability, the evolving nature of software development means that these contracts may contain unforeseen issues or vulnerabilities.

While we strive to provide a secure and robust platform through the integration of multiple oracles and other advanced features, it's crucial for users, developers, and integrators to understand the inherent risks associated with smart contracts and blockchain protocols.

All contracts have undergone thorough testing and reviews, but this doesn't guarantee they are free from errors or security vulnerabilities. Use them at your own risk.