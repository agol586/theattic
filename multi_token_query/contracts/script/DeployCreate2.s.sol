// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../src/MultiTokenQuery.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";
import "forge-std/StdConstants.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract DeployCreate2Script is Script {
    MultiTokenQuery public multiTokenQuery;
    
    // Salt for CREATE2 deployment (change this to get different addresses)
    bytes32 constant SALT = keccak256("MultiTokenQuery.v1.0.0");
    
    function run() external {
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");
        
        console.log("Using deployer from private key");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer address:", deployer);
        console.log("CREATE2 factory address:", CREATE2_FACTORY);
        console.log("Salt:", vm.toString(SALT));
        
        // Start broadcasting transactions
        vm.startBroadcast(deployer);
        
        // Prepare bytecode for MultiTokenQuery
        bytes memory bytecode = abi.encodePacked(type(MultiTokenQuery).creationCode);
        bytes32 bytecodeHash = keccak256(bytecode);
        
        // Compute predicted address
        address expectAddr = Create2.computeAddress(SALT, bytecodeHash, CREATE2_FACTORY);
        console.log("Predicted contract address:", expectAddr);
        
        // Deploy MultiTokenQuery using our CREATE2 factory
        address multiTokenQueryAddr = Create2.deploy(0, SALT, bytecode);
        multiTokenQuery = MultiTokenQuery(multiTokenQueryAddr);
        
        console.log("Deployed address:", multiTokenQueryAddr);
        console.log("Expected address:", expectAddr);
        console.log("Block number:", block.number);
        console.log("Gas price:", tx.gasprice);
        console.log("CREATE2 deployment: SUCCESS");
        
        // Verify addresses match
        require(multiTokenQueryAddr == expectAddr, "Address mismatch");
        console.log("Address verification: SUCCESS");
        // Stop broadcasting transactions
        vm.stopBroadcast();
        
        
        console.log("Deployment verification: SUCCESS");
    }
    
}