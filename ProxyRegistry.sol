pragma solidity ^0.8.2;

//stripped contract, taker from here.
//https://github.com/ProjectWyvern/wyvern-ethereum/blob/master/contracts/registry/ProxyRegistry.sol
contract ProxyRegistry {

    address public delegateProxyImplementation;

    mapping(address => address) public proxies;

    mapping(address => uint) public pending;

    mapping(address => bool) public contracts;

    uint public DELAY_PERIOD = 2 weeks;
}
