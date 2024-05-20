import { ethers } from "ethers";

const wallet = () => ethers.Wallet.createRandom();

const owners = [...Array(3)].map((_) => {
	const w = wallet();
	return {
		seeds: w.mnemonic?.phrase,
		privateKey: w.privateKey,
		publicKey: w.address,
	};
});

const submitters = [...Array(10)].map((_) => {
	const w = wallet();
	return {
		seeds: w.mnemonic?.phrase,
		privateKey: w.privateKey,
		publicKey: w.address,
	};
});

const approvers = [...Array(30)].map((_) => {
	const w = wallet();
	return {
		seeds: w.mnemonic?.phrase,
		privateKey: w.privateKey,
		publicKey: w.address,
	};
});

const executors = [...Array(10)].map((_) => {
	const w = wallet();
	return {
		seeds: w.mnemonic?.phrase,
		privateKey: w.privateKey,
		publicKey: w.address,
	};
});

const burners = [...Array(10)].map((_) => {
	const w = wallet();
	return {
		seeds: w.mnemonic?.phrase,
		privateKey: w.privateKey,
		publicKey: w.address,
	};
});

const revokers = [...Array(10)].map((_) => {
	const w = wallet();
	return {
		seeds: w.mnemonic?.phrase,
		privateKey: w.privateKey,
		publicKey: w.address,
	};
});

console.log(
	JSON.stringify(
		{
			owners,
			submitters,
			approvers,
			executors,
			burners,
			revokers,
		},
		null,
		4
	)
);
