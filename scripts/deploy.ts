import { ethers } from "hardhat";

async function main() {
	const [owner1, owner2] = await ethers.getSigners();

	console.log(owner1.address);
	console.log(owner2.address);

	const MultiSig = await ethers.getContractFactory("MultiSig", owner1);
	const multi_sig = await MultiSig.deploy([owner1, owner2], 2);
	const multi_sig_address = await multi_sig.getAddress();

	const USD = await ethers.getContractFactory("Fiat", owner1);
	const usd = await USD.deploy(multi_sig_address, "USD", "USD");
	const usd_address = await usd.getAddress();

	const KHR = await ethers.getContractFactory("Fiat", owner1);
	const khr = await KHR.deploy(multi_sig_address, "KHR", "KHR");
	const khr_address = await khr.getAddress();

	console.table({
		MultiSig: multi_sig_address,
		USD: usd_address,
		KHR: khr_address,
	});
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
