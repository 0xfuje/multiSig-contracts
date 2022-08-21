// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { MultiSig } from "./MultiSig.sol";

contract MultiSigFactory {
    event Deploy(
        address indexed initiator,
        address contractAddress
    );

    mapping(address => address[]) public contracts;

    function deploy(address[] memory _owners, uint8 _threshold) public 
        returns (address contractAddress) 
    {
        MultiSig multiSig = new MultiSig(_owners, _threshold);
        contractAddress = address(multiSig);

        contracts[msg.sender].push(contractAddress);
        emit Deploy(msg.sender, contractAddress);
    }
}