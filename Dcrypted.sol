// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract Dcrypted {
    using SafeMath for uint256;
    using ECDSA for bytes32; 

    address payable public admin;
    uint256 public adminFee = 3 ether;
    
    mapping(bytes32 => bool) public nonces;

    event BoughtCourse(
        bytes32 courseId,
        uint256 price,
        address studentAddr
    );

    constructor() {
        admin = payable(msg.sender);
    }

    function buyCourse(
            address expectedOwner, 
            bytes32 courseId,
            uint256 price,
            uint256 expiry,
            bytes32 nonce,
            address expectedBuyer,
            address expectedContract,
            bytes memory signature
        ) external payable {

        require(msg.value >= price, "Dcrypted: Insufficient funds");

        require(
            !nonces[nonce], 
            "Dcrypted: Nonce already used, make new buy request"
        );
        
        require(
            block.timestamp < expiry, 
            "Dcrypted: Signature expired, make new buy request"
        );
        
        require(
            expectedBuyer == msg.sender, 
            "Dcrypted: Only approved buyer can perfom this action"
        );

        require(
            expectedContract == address(this), 
            "Dcrypted: Invalid contract address"
        );

        nonces[nonce] = true;

        bytes32 message = keccak256(abi.encodePacked(
                    expectedOwner,
                    courseId,
                    price,
                    expiry,
                    nonce,
                    expectedBuyer,
                    expectedContract
                )
            );

        address _signer = message.recover(signature);

        require(
            admin == _signer, 
            "Dcrypted: Invalid signature, make new buy request"
        );

        require(
            payable(address(expectedOwner))
            .send(
                price.sub(
                  price.mul(adminFee).div(10**20)
                )
            )
            &&
            admin
            .send(
                price.mul(adminFee).div(10**20)
            ),
            "Dcrypted: Transaction failed"
        );

        emit BoughtCourse(courseId, price, msg.sender);
    }

    receive () external payable {

    }
}
