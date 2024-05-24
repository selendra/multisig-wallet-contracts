## Transaction Processor: Smart Contract Usage

This document outlines the usage flow for the smart contracts within the Transaction Processor project.

**MultiSig Contract Deployment:**

1.  Compile and deploy the `MultiSig` contract.
2.  During construction, provide an array of owner addresses to be assigned the `SuperAdmin` role.

**Adding Members and Roles:**

1.  Use a `SuperAdmin` account to call the `addMember` function on the deployed `MultiSig` contract.
2.  Specify the address of the new member and their desired role (`Submitter`, `Approver`, or `Executor`).
3.  The transaction requires approval from existing `SuperAdmin` accounts. You will need to call the `approve` function from multiple `SuperAdmin` addresses.
4.  Once sufficient approvals are gathered, call the `execute` function from any `SuperAdmin` account to finalize the member addition.

**ERC20 Contract Deployment and Linking with MultiSig:**

1.  Compile and deploy the desired ERC20 token contract.
2.  **Crucially, during ERC20 contract deployment, set the `MultiSig` contract address as the owner of the ERC20 contract.** This ensures the MultiSig contract controls minting operations.
3.  **(Optional)** If you forget to set the owner during deployment, you can use the ERC20 contract's `transferOwnership` function (assuming it exists) to transfer ownership from the deployer address to the `MultiSig` contract address. This requires a separate transaction initiated by a `SuperAdmin` account.
4.  From a `SuperAdmin` account, call the `addContract` function on the `MultiSig` contract.
5.  Provide the address of the deployed ERC20 contract and the token symbol as arguments.
6.  Similar to adding members, this action requires approval from multiple `SuperAdmin` accounts. Follow steps 3 and 4 from the "Adding Members and Roles" section.
