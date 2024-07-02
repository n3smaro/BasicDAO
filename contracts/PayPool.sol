// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

// Imports
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract PayPool is ReentrancyGuard {

    // Data
    uint public totalBalance;
    address public owner;
    address[] public depositAddresses;
    mapping(address => uint256) public allowances;

    // Deposit record struct
    struct DepositRecord {
        address depositor;
        uint256 amount;
        uint256 timestamp;
        DepositStatus status;
    }

    // Deposit status enum
    enum DepositStatus {
        Pending,
        Approved,
        Rejected
    }

    DepositRecord[] public depositHistory;

    // Events
    event Deposit(address indexed depositor, uint256 amount);
    event AddressAdded(address indexed depositor);
    event AddressRemoved(address indexed depositor);
    event AllowanceGranted(address indexed user, uint amount);
    event AllowanceRemoved(address indexed user);
    event FundsRetrieved(address indexed recipient, uint amount);
    event DepositApproved(uint256 index);
    event DepositRejected(uint256 index);

    // Modifiers
    modifier isOwner() {
        require(msg.sender == owner, "Not owner!");
        _;
    }

    modifier gotAllowance(address user) {
        require(hasAllowance(user), "This address has no allowance");
        _;
    }

    modifier canDepositTokens(address depositor) {
        require(canDeposit(depositor), "This address is not allowed to deposit tokens");
        _;
    }

    constructor() payable {
        totalBalance = msg.value;
        owner = msg.sender;
    }

    // Internal functions
    function hasAllowance(address user) internal view returns(bool) {
        return allowances[user] > 0;
    }

    function canDeposit(address depositor) internal view returns(bool) {
        for (uint i = 0; i < depositAddresses.length; i++) {
            if (depositAddresses[i] == depositor) {
                return true;
            }
        }
        return false;
    }

    // Execute Functions
    function addDepositAddress(address depositor) external isOwner {
        depositAddresses.push(depositor);
        emit AddressAdded(depositor);
    }

    function removeDepositAddress(uint index) external isOwner canDepositTokens(depositAddresses[index]) {
        depositAddresses[index] = address(0);
        emit AddressRemoved(depositAddresses[index]);
    }

    function deposit() external canDepositTokens(msg.sender) payable {
        totalBalance += msg.value;
        depositHistory.push(DepositRecord({
            depositor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            status: DepositStatus.Pending
        }));
        emit Deposit(msg.sender, msg.value);
    }

    function retrieveBalance() external isOwner nonReentrant {
        uint balance = totalBalance;
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
        totalBalance = 0;
        emit FundsRetrieved(owner, balance);
    }

    function giveAllowance(uint amount, address user) external isOwner {
        require(totalBalance >= amount, "Not enough tokens inside the pool to give allowance");
        allowances[user] = amount;
        unchecked {
            totalBalance -= amount;
        }
        emit AllowanceGranted(user, amount);
    }

    function removeAllowance(address user) external isOwner gotAllowance(user) {
        allowances[user] = 0;
        emit AllowanceRemoved(user);
    }

    function allowRetrieval() external gotAllowance(msg.sender) nonReentrant {
        uint amount = allowances[msg.sender];
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Retrieval failed");
        allowances[msg.sender] = 0;
        emit FundsRetrieved(msg.sender, amount);
    }

    // Owner-only functions for deposit management
    function approveDeposit(uint256 index) external isOwner {
        require(index < depositHistory.length, "Invalid index");
        require(depositHistory[index].status == DepositStatus.Pending, "Deposit already processed");
        depositHistory[index].status = DepositStatus.Approved;
        emit DepositApproved(index);
    }

    function rejectDeposit(uint256 index) external isOwner {
        require(index < depositHistory.length, "Invalid index");
        require(depositHistory[index].status == DepositStatus.Pending, "Deposit already processed");
        depositHistory[index].status = DepositStatus.Rejected;
        emit DepositRejected(index);
    }

    function getDepositHistory() public view returns (DepositRecord[] memory) {
        return depositHistory;
    }
}
