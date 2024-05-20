import { ethers } from "hardhat";
import { writeFile } from "node:fs/promises";

async function main() {
	const [owner1, owner2] = await ethers.getSigners();

	const MultiSig = await ethers.getContractFactory("MultiSig", owner1);
	const multi_sig = await MultiSig.deploy(
		[
			"0x83eB628F0Cc5a70F42076958671789a4e2809734",
			"0xcD0658505203e4719d49934a8267c158e53B51B1",
			"0xF1E7dac1Ee50aee492DE3D3DD4500FA805dF7646",
		],
		3
	);
	const multi_sig_address = await multi_sig.getAddress();

	const USD = await ethers.getContractFactory("Fiat", owner1);
	const usd = await USD.deploy(multi_sig_address, "USD", "USD");
	const usd_address = await usd.getAddress();

	const KHR = await ethers.getContractFactory("Fiat", owner1);
	const khr = await KHR.deploy(multi_sig_address, "KHR", "KHR");
	const khr_address = await khr.getAddress();

	const data = {
		MultiSig: multi_sig_address,
		USD: usd_address,
		KHR: khr_address,
		superAdmins: [
			"0x83eB628F0Cc5a70F42076958671789a4e2809734",
			"0xcD0658505203e4719d49934a8267c158e53B51B1",
			"0xF1E7dac1Ee50aee492DE3D3DD4500FA805dF7646",
		],
	};
	await writeFile("./scripts/config.json", JSON.stringify(data, null, 4));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
