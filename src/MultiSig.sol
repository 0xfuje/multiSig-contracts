// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MultiSig {
    event Submit(uint indexed txId);
    event ApproveFrom(address indexed sender, uint indexed txId);
    event RevokeFrom(address indexed sender, uint indexed txId);
    event Approve(uint indexed txId);
    event Revoke(uint indexed txId);
    event Execute(uint indexed txId);
    event DepositFrom(address indexed sender, uint value);

    enum Status {
        Submitted,
        Approved,
        Executed
    }

    struct Transaction {
        address to;
        uint value;
        bytes data;
        Status status;
    }

    address[] public owners;
    mapping (address => bool) public isOwner;
    uint8 public threshold;
    
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public txApprovalVote;
    uint public nextTxId;

    constructor(
        address[] memory _owners,
        uint8 _threshold
    ) {
        require(_owners.length > 1, "owners requried");
        require(_threshold > 0 && _threshold <= _owners.length, "invalid threshold");

        threshold = _threshold;
        
        for (uint8 i; i < _owners.length; i++) {
            address owner = _owners[i];
            require(_owners[i] != address(0), "0 address can't be owner");
            require(!isOwner[owner], "owner isn't unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        threshold = _threshold;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "msg.sender is not owner");
        _;
    }

    modifier txExists(uint _txId) {
        require(_txId <= nextTxId, "transaction doesn't exist");
        _;
    }

    modifier notApproved(uint _txId) {
        require(
            transactions[_txId].status != Status.Approved,
            "transaction is already approved"
        );
        _;
    }

    modifier notExecuted(uint _txId) {
        require(
            transactions[_txId].status != Status.Executed,
            "transaction is already executed"
        );
        _;
    }

    modifier moreThanZero() {
        require(msg.value > 0, "can't send 0 balance");
        _;
    }

    receive() external moreThanZero payable {
        emit DepositFrom(msg.sender, msg.value);
    }
    fallback() external moreThanZero payable {
        emit DepositFrom(msg.sender, msg.value);
    }

    function submit(address _to, uint _value, bytes calldata _data)
        external onlyOwner
    {
        transactions[nextTxId] = Transaction({
            to: _to,
            value: _value,
            data: _data,
            status: Status.Submitted
        });

        emit Submit(nextTxId);

        nextTxId++;
    }

    function approve(uint _txId) external
        onlyOwner txExists(_txId) notExecuted(_txId) notApproved(_txId)
    {
        txApprovalVote[_txId][msg.sender] = true;
        emit ApproveFrom(msg.sender, _txId);

        uint8 approvalCount = _getApprovalCount(_txId);
        if (approvalCount >= threshold) {
            transactions[_txId].status = Status.Approved;
            emit Approve(_txId);
        }
    }

    function execute(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) 
    {
        require(
            transactions[_txId].status == Status.Approved,
            "only approved transactions can get executed"
        );
        Transaction storage transaction = transactions[_txId];
        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "failed to send transaction");
        transactions[_txId].status = Status.Executed;

        emit Execute(_txId);
    }

    function revoke(uint _txId) external txExists(_txId) notExecuted(_txId) {
        require(
            transactions[_txId].status == Status.Approved,
            "only approved transactions can be revoked"
        );
        require(
            txApprovalVote[_txId][msg.sender],
            "only approved vote can be revoked"
        );

        txApprovalVote[_txId][msg.sender] = false;
        emit RevokeFrom(msg.sender, _txId);

        uint8 approvalCount = _getApprovalCount(_txId);
        if (approvalCount < threshold) {
            transactions[_txId].status = Status.Submitted;
            emit Revoke(_txId);
        }
    }

    function getTxInfo(uint _txId) external view returns (
        address to,
        uint value,
        bytes memory data,
        Status status
    ) {
        Transaction memory trx = transactions[_txId];
        return (trx.to, trx.value, trx.data, trx.status);
    }

    function _getApprovalCount(uint _txId) internal view
    returns (uint8 appovalCount) {
        uint8 approvalCount;
        for (uint8 i; i < owners.length; i++) {
            if (txApprovalVote[_txId][owners[i]]) {
                approvalCount++;
            }
        }
        return approvalCount;
    }
    
}
