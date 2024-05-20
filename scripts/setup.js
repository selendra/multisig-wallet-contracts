const dotenv = require("dotenv");
const { ethers } = require("ethers");
const wallets = require("../../wallets.json");
const MULTISIG = require("../artifacts/contracts/MultiSig.sol/MultiSig.json");
const config = require("./config.json");
dotenv.config();

function getContract(pk) {
	const network = new ethers.JsonRpcProvider(
		"https://rpc0-testnet.selendra.org"
	);

	const wallet = new ethers.Wallet(pk, network);
	const contract = new ethers.Contract(config.MultiSig, MULTISIG.abi, wallet);
	return contract;
}

async function addMember(
	retries = 0,
	owner1,
	owner2,
	owner3,
	account,
	role,
	gasConfig
) {
	try {
		const txId = crypto.randomUUID();
		console.log("1");
		await (
			await owner1.addMember(txId, account.publicKey, 3, role, gasConfig)
		).wait();
		console.log("2");

		await (await owner1.approve(txId, gasConfig)).wait();
		console.log("3");
		await (await owner2.approve(txId, gasConfig)).wait();
		console.log("4");
		await (await owner3.approve(txId, gasConfig)).wait();
		console.log("5");
		await (await owner3.execute(txId, gasConfig)).wait();
		console.log("6");

		console.log("Added ", role, account.publicKey);
	} catch (error) {
		console.log(error);
		const next = retries + 1;
		if (next < 10) {
			console.log("Retrying to add member");
			return await addMember(
				next,
				owner1,
				owner2,
				owner3,
				account,
				role,
				gasConfig
			);
		} else {
			console.log("Max retries reach");
			console.log("Operation addMember with role", role);
			console.log("Account, ", account.publicKey);
			console.log(error);
		}
	}
}

async function main() {
	const { owners, approvers, burners, executors, submitters, revokers } =
		wallets;

	const accounts = [
		...owners,
		...approvers,
		...burners,
		...executors,
		...submitters,
		...revokers,
	];

	console.log("SENDING SELS");
	for (const account of accounts) {
		const network = new ethers.JsonRpcProvider(
			"https://rpc0-testnet.selendra.org"
		);

		const wallet = new ethers.Wallet(process.env.SIGNER_1, network);

		const tx = await wallet.sendTransaction({
			to: account.publicKey,
			value: ethers.parseEther("10"),
		});

		const res = await tx.wait();
		console.log("AMOUNT: 10 SEL");
		console.log("ACCOUNT: ", res.to);
		console.log("");
	}

	const owner1 = getContract(owners[0].privateKey);
	const owner2 = getContract(owners[1].privateKey);
	const owner3 = getContract(owners[2].privateKey);

	// const SuperAdmin = "0";
	const Submitter = "1";
	const Approver = "2";
	const Executer = "3";
	const Burner = "4";
	const Revoker = "5";

	const gasConfig = {
		gasLimit: 300000,
	};

	console.log("SETTING UP ACCOUNTS");
	for (const account of submitters) {
		await addMember(0, owner1, owner2, owner3, account, Submitter, gasConfig);
	}

	for (const account of approvers) {
		await addMember(0, owner1, owner2, owner3, account, Approver, gasConfig);
	}

	for (const account of executors) {
		await addMember(0, owner1, owner2, owner3, account, Executer, gasConfig);
	}

	for (const account of burners) {
		await addMember(0, owner1, owner2, owner3, account, Burner, gasConfig);
	}

	for (const account of revokers) {
		await addMember(0, owner1, owner2, owner3, account, Revoker, gasConfig);
	}
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
