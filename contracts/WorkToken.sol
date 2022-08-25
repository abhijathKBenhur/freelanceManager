pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";
contract WorkToken is ERC20 {
    uint256 constant _initial_supply = 100000; //100 * (10**18);

    constructor() ERC20("WorkToken", "WT") {
        _mint(msg.sender, _initial_supply);
    }
}