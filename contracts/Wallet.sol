pragma solidity ^0.8.9;

contract NativeWallet {
    event Deposit(address indexed sender, uint amount);

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function deposit() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(address easyReturnAddress) public {
        payable(easyReturnAddress).transfer(address(this).balance);
    }
}
