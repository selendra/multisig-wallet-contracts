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
    }

    string public SuperAdmin = "0";
    string public Submitter = "1";
    string public Approver = "2";
    string public Executer = "3";
    string public Burner = "4";
    string public Revoker = "5";

    uint public required;
    address[] public owners;

    mapping(address => string) public roles;
    mapping(address => bool) public isOwner;
    mapping(string => address) tokens;
    mapping(address => bool) isTokenExisted;
    mapping(string => Transaction) transactions;
    mapping(string => mapping(address => bool)) public approved;

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
        require(!approved[_txId][msg.sender], "tx was approved by owner");
        _;
    }

    modifier notExecuted(string calldata _txId) {
        require(!transactions[_txId].executed, "tx was already executed");
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
            owners.push(owner);
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
            executed: false
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
        txExists(_txId)
        notApproved(_txId)
        notExecuted(_txId)
        isApprover
    {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId, transactions[_txId].op);
    }

    function _getApprovalCount(
        string calldata _txId
    ) private view returns (uint count) {
        for (uint i; i < owners.length; i++) {
            if (approved[_txId][owners[i]]) {
                count += 1;
            }
        }
    }

    function _removeOwner(address owner) internal {
        for (uint i; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }
    }

    function execute(
        string calldata _txId
    ) external txExists(_txId) notExecuted(_txId) isExecuter {
        require(
            _getApprovalCount(_txId) >= required,
            "approvals is less than required"
        );

        Transaction storage transaction = transactions[_txId];

        if (transaction.op == Operation.mint) {
            Fiat _contract = Fiat(tokens[transaction.token]);
            _contract.mint(transaction.to, transaction.amount);
        }

        if (transaction.op == Operation.burn) {
            Fiat _contract = Fiat(tokens[transaction.token]);
            _contract.burn(transaction.amount);
        }

        if (transaction.op == Operation.transferOwnership) {
            Fiat _contract = Fiat(tokens[transaction.token]);
            _contract.transferOwnership(transaction.to);
        }

        if (transaction.op == Operation.addContract) {
            tokens[transaction.token] = transaction.to;
        }

        if (transaction.op == Operation.removeContract) {
            delete tokens[transaction.token];
        }

        if (transaction.op == Operation.addMember) {
            isOwner[transaction.to] = true;
            owners.push(transaction.to);
            required = transaction.amount;
            roles[transaction.to] = transaction.token;
        }

        if (transaction.op == Operation.removeMember) {
            delete isOwner[transaction.to];
            _removeOwner(transaction.to);
            required = transaction.amount;
        }

        transaction.executed = true;
        emit Execute(_txId, transactions[_txId].op);
    }

    function revoke(
        string calldata _txId
    ) external onlyOwner txExists(_txId) notExecuted(_txId) {
        require(approved[_txId][msg.sender], "tx not approved");
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId, transactions[_txId].op);
    }
}
