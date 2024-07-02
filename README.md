# BasicDAO Smart Contract

## Overview

**BasicDAO** is a Decentralized Autonomous Organization (DAO) smart contract designed for the Scroll Sepolia testnet. It allows members to join by paying a membership fee, create proposals, vote on those proposals, and execute them once the voting period ends. The project illustrates essential DAO functionalities including membership management, proposal creation, and voting mechanisms.

## Features

- **Membership Management**: Users can join the DAO by paying a membership fee.
- **Proposal Creation**: Members can create proposals with a description and a deadline.
- **Voting**: Members can vote on proposals as "Yes" or "No" before the deadline.
- **Proposal Execution**: The contract owner can execute proposals that have passed the voting period and have more "Yes" votes than "No" votes.
- **Get Members**: Retrieve the list of DAO members.
- **Get Proposals**: Retrieve the list of proposals.

## Getting Started

### Prerequisites

Make sure you have the following tools and packages installed:

- [Node.js](https://nodejs.org/) (>= 18.x)
- [Hardhat](https://hardhat.org/) (>= 2.14.0)
- [dotenv](https://www.npmjs.com/package/dotenv) for environment variable management

### Installation

Clone the repository and install the necessary dependencies:

Try running some of the following tasks:

```shell
npm i
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/BasicDAO.js
```
