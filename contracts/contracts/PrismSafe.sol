// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
// PrismSafe — 2-of-3 MultiSig USDC wallet
contract PrismSafe {
    address[3] public owners;
    uint256 public required = 2;
    struct Transaction { address to; uint256 value; bool executed; uint256 confirmations; }
    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmed;
    event Submitted(uint256 indexed txId, address to, uint256 value);
    event Confirmed(uint256 indexed txId, address owner);
    event Executed(uint256 indexed txId);
    event Deposited(address sender, uint256 amount);
    constructor() { owners[0] = msg.sender; owners[1] = msg.sender; owners[2] = msg.sender; }
    modifier isOwner() {
        require(msg.sender==owners[0]||msg.sender==owners[1]||msg.sender==owners[2],"Not owner"); _;
    }
    function setOwners(address o1, address o2, address o3) external {
        require(msg.sender == owners[0], "Not owner");
        owners[0]=o1; owners[1]=o2; owners[2]=o3;
    }
    function submit(address to, uint256 value) external isOwner returns (uint256) {
        transactions.push(Transaction(to, value, false, 0));
        emit Submitted(transactions.length - 1, to, value);
        return transactions.length - 1;
    }
    function confirm(uint256 txId) external isOwner {
        require(!confirmed[txId][msg.sender], "Already confirmed");
        confirmed[txId][msg.sender] = true;
        transactions[txId].confirmations++;
        emit Confirmed(txId, msg.sender);
    }
    function execute(uint256 txId) external isOwner {
        Transaction storage t = transactions[txId];
        require(t.confirmations >= required, "Need more confirmations");
        require(!t.executed, "Already executed");
        require(address(this).balance >= t.value, "Insufficient USDC");
        t.executed = true;
        payable(t.to).transfer(t.value);
        emit Executed(txId);
    }
    function deposit() external payable { emit Deposited(msg.sender, msg.value); }
    function txCount() external view returns (uint256) { return transactions.length; }
    function balance() external view returns (uint256) { return address(this).balance; }
    receive() external payable { emit Deposited(msg.sender, msg.value); }
}