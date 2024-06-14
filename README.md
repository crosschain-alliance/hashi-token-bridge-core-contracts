# Hashi Token Bridge Core Contracts

[![GitHub license](https://img.shields.io/badge/license-TODO.svg)](https://github.com/safe-junction/hashi-token-bridge-core-contracts/blob/main/LICENSE)

## Overview

Hashi Token Bridge changes the perspective of bridges by positioning itself on a higher level, aiming to provide a universal cross-chain experience by using multiple oracles for compounded security and being faster than others thanks to its Fast Lane feature.

Unlike traditional bridging solutions, Hashi Token Bridge leverages the functionality of existing bridges, using them as oracles to authenticate, verify and execute cross-chain operations as instructed by users on different blockchains. By using several bridges as oracles, Hashi Token Bridge achieves cross-chain asset transfer validations in a redundant, universal and safer way. It is designed to be chain agnostic and simple to audit. Yet, it achieves speed, thanks to a built-in optional feature called the Fast Lane.

Today the bridging ecosystem suffers from excessive fragmentation. Hashi Token Bridge powers *Tokens (“Star Tokens”) to tackle this very problem. These tokens inherit the properties described above to provide a superior cross-chain experience.

In the worst case, the system's speed is equivalent to that of the slowest oracle in the network. However, when the Fast Lane functionality gets used, it overcomes this drawback and enables much higher speed: market makers can process cross-chain transfers in advance, providing their liquidity in response to a user request, and then securely reclaim the liquidity (plus a service fee) once all oracles have processed the cross-chain request at their standard speed.

It is important to understand how Hashi Token Bridge differs from existing cross-chain solutions (bridges, aggregators, etc.) in terms of security (which is additive), speed (via Fast Lane MM intervention) and compatibility (as it aims to be 100% agnostic, and not just EVM compatible).

&nbsp;

***

&nbsp;

## Installation and Usage

### Prerequisites

Ensure you have [Node.js](https://nodejs.org/) and [npm](https://www.npmjs.com/) installed.

### Clone the Repository

```bash
git clone https://github.com/safe-junction/hashi-token-bridge-core-contracts.git
cd hashi-token-bridge-core-contracts
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

For any inquiries, issues, or feedback, please [raise an issue on GitHub](https://github.com/safe-junction/hashi-token-bridge-core-contracts/issues) or contact the team through our [official website](#).

&nbsp;

***

&nbsp;

## ⚠️ Security and Development Disclaimer

All contracts in this repository are still under active development. Although Hashi Token Bridge endeavors to ensure the highest level of security and reliability, the evolving nature of software development means that these contracts may contain unforeseen issues or vulnerabilities.

While we strive to provide a secure and robust platform through the integration of multiple oracles and other advanced features, it's crucial for users, developers, and integrators to understand the inherent risks associated with smart contracts and blockchain protocols.

All contracts have undergone thorough testing and reviews, but this doesn't guarantee they are free from errors or security vulnerabilities. Use them at your own risk.