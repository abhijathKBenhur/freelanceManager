// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

contract Utilities {
    function _isEmpty(string memory input) internal pure returns (bool){
        return bytes(input).length == 0;
    }
}