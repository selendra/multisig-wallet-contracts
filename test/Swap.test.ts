import { SelSwap } from "../typechain-types";
import { ethers } from "hardhat";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";

describe("Swap Contract", function () {
	let contract: SelSwap;

	let owner: any, smartAddr: any, brownAddr: any, user: any, nonOwner: any;

	beforeEach(async () => {
		const Swap = await ethers.getContractFactory("SelSwap");
		contract = await Swap.deploy();

		[owner, smartAddr, brownAddr, user, nonOwner] = await ethers.getSigners();
	});

	describe("register_business", function () {
		it("should register a new business", async function () {
			await expect(
				contract.connect(owner).register_business("Smart", owner.address)
			)
				.to.emit(contract, "BusinessRegistered")
				.withArgs(1, "Smart", owner.address);

			expect(await contract.businesses(1)).to.equal("Smart");
			expect(await contract.business_owners(1)).to.equal(owner.address);
		});

		it("should revert if not called by owner", async function () {
			await expect(
				contract
					.connect(smartAddr)
					.register_business("Business 2", smartAddr.address)
			).to.be.revertedWith("Only owner can register business");
		});

		it("should revert if business name is empty", async function () {
			await expect(
				contract.connect(owner).register_business("", owner.address)
			).to.be.revertedWith("Business name cannot be empty");
		});
	});

	describe("mint", function () {
		it("should allow business owner to mint tokens", async function () {
			const tokenId = 1;
			const amount = 100;

			await contract.register_business("Smart", smartAddr.address);
			await contract.business_owners(tokenId);

			await expect(
				contract.connect(smartAddr).mint(user.address, tokenId, amount)
			)
				.to.emit(contract, "Transfer")
				.withArgs(user.address, tokenId, amount);
		});

		it("should revert if caller is not business owner", async function () {
			const tokenId = 1;
			const amount = 100;

			await contract.register_business("Smart", owner.address);

			await expect(
				contract.connect(nonOwner).mint(user.address, tokenId, amount)
			).to.be.revertedWith("Only business owner can mint");
		});
	});

	describe("Swap", function () {
		it("should swap tokens between businesses", async function () {
			const fromToken = 1;
			const toToken = 2;
			const amount = 100;

			await contract.register_business("Smart", smartAddr.address);
			await contract.register_business("Brown", brownAddr.address);

			await expect(
				contract.connect(smartAddr).mint(user.address, fromToken, amount)
			)
				.to.emit(contract, "Transfer")
				.withArgs(user.address, fromToken, amount);

			const contractBenefit = (amount / 100) * 4;
			const businessBenefit = (amount / 100) * 3;
			const businessBAmount = amount - contractBenefit - businessBenefit;
			const receiverAmount =
				amount - contractBenefit - businessBenefit - businessBenefit;

			await contract
				.connect(user)
				.safeTransferFrom(
					user.address,
					owner.address,
					fromToken,
					contractBenefit,
					"0x"
				);

			const ownerBalance = await contract.balanceOf(
				contract.owner(),
				fromToken
			);
			expect(ownerBalance).to.equal(contractBenefit);

			await contract
				.connect(user)
				.safeTransferFrom(
					user.address,
					brownAddr,
					fromToken,
					businessBAmount,
					"0x"
				);

			const toBusinessBalance = await contract.balanceOf(
				brownAddr.address,
				fromToken
			);
			expect(toBusinessBalance).to.equal(businessBAmount);

			await contract
				.connect(user)
				.safeTransferFrom(
					user.address,
					smartAddr,
					fromToken,
					businessBenefit,
					"0x"
				);

			const fromBusinessBalance = await contract.balanceOf(
				smartAddr.address,
				fromToken
			);
			expect(fromBusinessBalance)
				.to.equal(businessBenefit)
				.revertedWith("Amount must be 3");

			await expect(
				contract.connect(brownAddr).mint(user.address, toToken, receiverAmount)
			)
				.to.emit(contract, "Transfer")
				.withArgs(user.address, toToken, receiverAmount);

			const swapperBalance = await contract.balanceOf(user, toToken);
			expect(swapperBalance).to.equal(receiverAmount * 100);
		});

		it("should revert if amount is not multiple of 100", async function () {
			const fromToken = 1;
			const toToken = 2;
			const amount = 250;

			await expect(
				contract.connect(user).swap(user, fromToken, toToken, amount)
			).to.be.revertedWith("Amount must be multiple of 100");
		});

		it("should revert if swapping same token", async function () {
			const token = 1;
			const amount = 300;

			await expect(
				contract.connect(user).swap(user, token, token, amount)
			).to.be.revertedWith("Cannot swap same token");
		});

		it("should revert if to token business not registered", async function () {
			const fromToken = 1;
			const toToken = 2;
			const amount = 300;

			await expect(
				contract.connect(user).swap(user, fromToken, toToken, amount)
			).to.be.revertedWith("Business not registered");
		});
	});
});
