import "@nomicfoundation/hardhat-toolbox";

import { HardhatUserConfig } from "hardhat/config";

require("dotenv").config();

const SIGNER_1 = process.env.SIGNER_1 || "";
const SIGNER_2 = process.env.SIGNER_2 || "";

const config: HardhatUserConfig = {
	paths: {
		artifacts: "artifacts",
		cache: "cache",
		sources: "contracts",
	},
	solidity: "0.8.24",
	networks: {
		selendra: {
			url: "https://rpc0.selendra.org",
			chainId: 1961,
			accounts: [SIGNER_1, SIGNER_2],
		},
		testnet: {
			url: "https://rpc0-testnet.selendra.org",
			chainId: 1953,
			accounts: [SIGNER_1, SIGNER_2],
		},
	},
};

export default config;
