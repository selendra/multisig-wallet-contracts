require("dotenv").config();
const FIAT = require("../artifacts/contracts/Fiat.sol/Fiat.json");
const MULTISIG = require("../artifacts/contracts/MultiSig.sol/MultiSig.json");
const { ethers } = require("ethers");

const provider = new ethers.JsonRpcProvider(process.env.JSON_RPC_PROVIDER);

const getContract = (seed, address, abi) => {
	const signer = new ethers.Wallet(seed || "", provider);
	const contract = new ethers.Contract(address, abi, signer);
	return contract;
};

const SIGNER_1 = process.env.SIGNER_1;
const SIGNER_2 = process.env.SIGNER_2;

const CONTRACT_MULTI_SIG = process.env.CONTRACT_MULTI_SIG;
const CONTRACT_USD = process.env.CONTRACT_USD;
const CONTRACT_KHR = process.env.CONTRACT_KHR;

const worker_1 = getContract(SIGNER_1, CONTRACT_MULTI_SIG, MULTISIG.abi);
const worker_2 = getContract(SIGNER_2, CONTRACT_MULTI_SIG, MULTISIG.abi);

const receiver_usd = getContract(SIGNER_1, CONTRACT_USD, FIAT.abi);
const receiver_khr = getContract(SIGNER_1, CONTRACT_KHR, FIAT.abi);

async function main() {
	const receiver = "0x447ab136f191AF8d47B1D1533a04FCdCfD3f5d6B";

	const id1 = crypto.randomUUID();
	const id2 = crypto.randomUUID();

	// const worker_1_is_owner = await worker_1.isOwner(
	// 	"0xa5915AAAF9ABCE06764eBa224A3A3F208fCD91f5"
	// );
	// const worker_2_is_owner = await worker_1.isOwner(
	// 	"0xfdc0EeA69aFE61d29086af928022587A82385a86"
	// );

	// console.log("worker_1_is_owner", worker_1_is_owner);
	// console.log("worker_2_is_owner", worker_2_is_owner);

	console.log(1);
	await (
		await worker_2.addContract(id1, CONTRACT_USD, "USD", {
			gasLimit: 300000,
		})
	).wait();
	console.log(2);
	await (
		await worker_1.approve(id1, {
			gasLimit: 300000,
		})
	).wait();
	console.log(3);
	await (
		await worker_2.approve(id1, {
			gasLimit: 300000,
		})
	).wait();
	console.log(4);
	await (
		await worker_2.execute(id1, {
			gasLimit: 300000,
		})
	).wait();

	console.log(5);
	await (
		await worker_1.addContract(id2, CONTRACT_KHR, "KHR", {
			gasLimit: 300000,
		})
	).wait();
	console.log(6);
	await (
		await worker_1.approve(id2, {
			gasLimit: 300000,
		})
	).wait();
	console.log(7);
	await (
		await worker_2.approve(id2, {
			gasLimit: 300000,
		})
	).wait();
	console.log(8);
	await (
		await worker_2.execute(id2, {
			gasLimit: 300000,
		})
	).wait();
	console.log(9);

	// console.log("USD before mint:", await receiver_usd.balanceOf(receiver));

	// await (
	// 	await worker_1.mint("003", receiver, "1000000000000000000", "USD")
	// ).wait();
	// await (await worker_1.approve("003")).wait();
	// await (await worker_2.approve("003")).wait();
	// await (await worker_1.execute("003")).wait();

	// console.log("USD after mint:", await receiver_usd.balanceOf(receiver));

	// console.log("KHR before mint:", await receiver_khr.balanceOf(receiver));
	// let id = crypto.randomUUID();
	// await (
	// 	await worker_1.mint(id, receiver, "1000000000000000000", "KHR")
	// ).wait();
	// await (await worker_1.approve(id)).wait();
	// await (await worker_2.approve(id)).wait();
	// await (await worker_1.execute(id)).wait();

	// console.log("KHR after mint:", await receiver_khr.balanceOf(receiver));
}

main();
