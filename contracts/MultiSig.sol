// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./Wallet.sol";
import "./Fiat.sol";

contract MultiSig is NativeWallet {
    event Submit(string txId, Operation opr);
    event Approve(address owner, string txId, Operation opr);
    event Revoke(address owner, string txId, Operation opr);
    event Execute(string txId, Operation opr);

    enum Operation {
        mint,
        burn,
        transferOwnership,
        addContract,
        removeContract,
        addMember,
        removeMember
    }

    struct Transaction {
        Operation op;
        address to;
        uint amount;
        string token;
        bool executed;
        bool revoked;
    }

    string public SuperAdmin = "0";
    string public Submitter = "1";
    string public Approver = "2";
    string public Executer = "3";
    string public Burner = "4";
    string public Revoker = "5";

    uint public required;

    mapping(address => string) public roles;
    mapping(address => bool) public isOwner;
    mapping(string => address) tokens;
    mapping(address => bool) isTokenExisted;
    mapping(string => Transaction) transactions;
    mapping(string => address[]) public approved;

    function compareString(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "invalid owner");
        _;
    }

    modifier tokenExist(string calldata token) {
        require(tokens[token] != address(0), "Token not found");
        _;
    }

    modifier tokenNotExist(address tokenId, string calldata symbol) {
        require(!isTokenExisted[tokenId], "Token address already exist");
        require(tokens[symbol] == address(0), "Token symbol already exist");
        _;
    }

    modifier txExists(string calldata _txId) {
        require(transactions[_txId].to != address(0), "tx does not exist");
        _;
    }

    modifier txNotExists(string calldata _txId) {
        require(transactions[_txId].to == address(0), "tx already exist");
        _;
    }

    modifier notApproved(string calldata _txId) {
        for (uint i; i < approved[_txId].length; ++i) {
            require(
                msg.sender != approved[_txId][i],
                "tx was approved by owner"
            );
        }
        _;
    }

    modifier notExecuted(string calldata _txId) {
        require(!transactions[_txId].executed, "tx was already executed");
        _;
    }

    modifier notRevoked(string calldata _txId) {
        require(!transactions[_txId].revoked, "tx was revoked");
        _;
    }

    modifier isSuperAdmin() {
        require(
            compareString(roles[msg.sender], SuperAdmin),
            "Must be a SuperAdmin"
        );
        _;
    }

    modifier isMinter() {
        require(
            compareString(roles[msg.sender], Submitter),
            "Must be a Submitter"
        );
        _;
    }

    modifier isApprover() {
        require(
            compareString(roles[msg.sender], SuperAdmin) ||
                compareString(roles[msg.sender], Approver),
            "Must be a Approver"
        );
        _;
    }

    modifier isExecuter() {
        require(
            compareString(roles[msg.sender], SuperAdmin) ||
                compareString(roles[msg.sender], Executer),
            "Must be a Executer"
        );
        _;
    }
    modifier isBurner() {
        require(
            compareString(roles[msg.sender], SuperAdmin) ||
                compareString(roles[msg.sender], Burner),
            "Must be a Burner"
        );
        _;
    }
    modifier isRevoker() {
        require(
            compareString(roles[msg.sender], SuperAdmin) ||
                compareString(roles[msg.sender], Revoker),
            "Must be a Revoker"
        );
        _;
    }

    modifier isValidRole(string calldata role) {
        require(
            compareString(role, SuperAdmin) ||
                compareString(role, Submitter) ||
                compareString(role, Approver) ||
                compareString(role, Executer) ||
                compareString(role, Burner) ||
                compareString(role, Revoker),
            "Invalid roles"
        );
        _;
    }

    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "owner(s) required");
        require(
            _required > 0 && _required <= _owners.length,
            "invalid required number of owners"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner is not unique");

            isOwner[owner] = true;
            roles[owner] = SuperAdmin;
        }
        required = _required;
    }

    function submit(
        string calldata txId,
        Operation _op,
        address _to,
        uint amount,
        string calldata token
    ) internal txNotExists(txId) onlyOwner {
        transactions[txId] = Transaction({
            op: _op,
            to: _to,
            amount: amount,
            token: token,
            executed: false,
            revoked: false
        });

        emit Submit(txId, _op);
    }

    function mint(
        string calldata txId,
        address to,
        uint amount,
        string calldata tokenId
    ) public tokenExist(tokenId) isMinter {
        submit(txId, Operation.mint, to, amount, tokenId);
    }

    function burn(
        string calldata txId,
        uint amount,
        string calldata tokenId
    ) public tokenExist(tokenId) isBurner {
        submit(txId, Operation.burn, address(this), amount, tokenId);
    }

    function addContract(
        string calldata txId,
        address contractAddress,
        string calldata tokenId
    ) public tokenNotExist(contractAddress, tokenId) isSuperAdmin {
        submit(txId, Operation.addContract, contractAddress, 0, tokenId);
    }

    function removeContract(
        string calldata txId,
        string calldata tokenId
    ) public tokenExist(tokenId) isSuperAdmin {
        submit(txId, Operation.removeContract, tokens[tokenId], 0, tokenId);
    }

    function addMember(
        string calldata txId,
        address account,
        uint newRequired,
        string calldata role
    ) public isValidRole(role) isSuperAdmin {
        submit(txId, Operation.addMember, account, newRequired, role);
    }

    function removeMember(
        string calldata txId,
        address account,
        uint newRequired,
        string calldata empty
    ) public isSuperAdmin {
        submit(txId, Operation.removeMember, account, newRequired, empty);
    }

    function transferOwnership(
        string calldata txId,
        string calldata tokenId,
        address newOwner
    ) public tokenExist(tokenId) isSuperAdmin {
        submit(txId, Operation.transferOwnership, newOwner, 0, tokenId);
    }

    function approve(
        string calldata _txId
    )
        external
        isApprover
        txExists(_txId)
        notApproved(_txId)
        notExecuted(_txId)
        notRevoked(_txId)
    {
        approved[_txId].push(msg.sender);
        emit Approve(msg.sender, _txId, transactions[_txId].op);
    }

    function _getApprovalCount(
        string calldata _txId
    ) private view returns (uint count) {
        return approved[_txId].length;
    }

    function execute(
        string calldata _txId
    ) external isExecuter txExists(_txId) notExecuted(_txId) notRevoked(_txId) {
        require(
            _getApprovalCount(_txId) >= required,
            "approvals is less than required"
        );

        Transaction storage txn = transactions[_txId];

        if (txn.op == Operation.mint) {
            Fiat _contract = Fiat(tokens[txn.token]);
            _contract.mint(txn.to, txn.amount);
        }

        if (txn.op == Operation.burn) {
            Fiat _contract = Fiat(tokens[txn.token]);
            _contract.burn(txn.amount);
        }

        if (txn.op == Operation.transferOwnership) {
            Fiat _contract = Fiat(tokens[txn.token]);
            _contract.transferOwnership(txn.to);
        }

        if (txn.op == Operation.addContract) {
            tokens[txn.token] = txn.to;
        }

        if (txn.op == Operation.removeContract) {
            delete tokens[txn.token];
        }

        if (txn.op == Operation.addMember) {
            isOwner[txn.to] = true;
            required = txn.amount;
            roles[txn.to] = txn.token;
        }

        if (txn.op == Operation.removeMember) {
            delete isOwner[txn.to];
            required = txn.amount;
        }

        txn.executed = true;
        emit Execute(_txId, transactions[_txId].op);
    }

    function revoke(
        string calldata _txId
    ) external isRevoker txExists(_txId) notExecuted(_txId) {
        transactions[_txId].revoked = true;
        emit Revoke(msg.sender, _txId, transactions[_txId].op);
    }
}
