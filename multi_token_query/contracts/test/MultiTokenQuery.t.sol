// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../src/MultiTokenQuery.sol";

// 简化的测试断言库
library TestAssert {
    function assertEq(uint256 a, uint256 b, string memory message) internal pure {
        require(a == b, string(abi.encodePacked("Assertion failed: ", message)));
    }
    
    function assertEq(uint8 a, uint8 b, string memory message) internal pure {
        require(a == b, string(abi.encodePacked("Assertion failed: ", message)));
    }
    
    function assertEq(address a, address b, string memory message) internal pure {
        require(a == b, string(abi.encodePacked("Assertion failed: ", message)));
    }
    
    function assertEq(string memory a, string memory b, string memory message) internal pure {
        require(keccak256(bytes(a)) == keccak256(bytes(b)), string(abi.encodePacked("Assertion failed: ", message)));
    }
    
    function assertGt(uint256 a, uint256 b, string memory message) internal pure {
        require(a > b, string(abi.encodePacked("Assertion failed: ", message)));
    }
}

// Mock ERC20 token for testing
contract MockERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract MultiTokenQueryTest {
    
    MultiTokenQuery public multiTokenQuery;
    MockERC20 public token1;
    MockERC20 public token2;
    MockERC20 public token3;
    
    address public user = address(0x123);
    
    constructor() {
        setUp();
    }
    
    function setUp() internal {
        multiTokenQuery = new MultiTokenQuery();
        
        // 创建测试代币
        token1 = new MockERC20("USD Coin", "USDC", 6, 1000000 * 10**6);
        token2 = new MockERC20("Tether USD", "USDT", 6, 1000000 * 10**6);
        token3 = new MockERC20("Dai Stablecoin", "DAI", 18, 1000000 * 10**18);
        
        // 给测试用户一些代币
        token1.transfer(user, 1000 * 10**6);  // 1000 USDC
        token2.transfer(user, 2000 * 10**6);  // 2000 USDT
        token3.transfer(user, 3000 * 10**18); // 3000 DAI
    }
    
    function testQueryMultipleTokens() public view {
        address[] memory tokenAddresses = new address[](3);
        tokenAddresses[0] = address(token1);
        tokenAddresses[1] = address(token2);
        tokenAddresses[2] = address(token3);
        
        MultiTokenQuery.QueryResult memory result = multiTokenQuery.queryMultipleTokens(user, tokenAddresses);
        
        // 验证查询地址
        TestAssert.assertEq(result.queryAddress, user, "Query address mismatch");
        
        // 验证代币数量
        TestAssert.assertEq(result.tokens.length, 3, "Token count mismatch");
        
        // 验证第一个代币 (USDC)
        TestAssert.assertEq(result.tokens[0].tokenAddress, address(token1), "Token1 address mismatch");
        TestAssert.assertEq(result.tokens[0].symbol, "USDC", "Token1 symbol mismatch");
        TestAssert.assertEq(uint256(result.tokens[0].decimals), 6, "Token1 decimals mismatch");
        TestAssert.assertEq(result.tokens[0].balance, 1000 * 10**6, "Token1 balance mismatch");
        
        // 验证第二个代币 (USDT)
        TestAssert.assertEq(result.tokens[1].tokenAddress, address(token2), "Token2 address mismatch");
        TestAssert.assertEq(result.tokens[1].symbol, "USDT", "Token2 symbol mismatch");
        TestAssert.assertEq(uint256(result.tokens[1].decimals), 6, "Token2 decimals mismatch");
        TestAssert.assertEq(result.tokens[1].balance, 2000 * 10**6, "Token2 balance mismatch");
        
        // 验证第三个代币 (DAI)
        TestAssert.assertEq(result.tokens[2].tokenAddress, address(token3), "Token3 address mismatch");
        TestAssert.assertEq(result.tokens[2].symbol, "DAI", "Token3 symbol mismatch");
        TestAssert.assertEq(uint256(result.tokens[2].decimals), 18, "Token3 decimals mismatch");
        TestAssert.assertEq(result.tokens[2].balance, 3000 * 10**18, "Token3 balance mismatch");
        
        // 验证时间戳和区块号
        TestAssert.assertGt(result.timestamp, 0, "Timestamp should be greater than 0");
        TestAssert.assertGt(result.blockNumber, 0, "Block number should be greater than 0");
    }
    
    function testQueryBalances() public view {
        address[] memory tokenAddresses = new address[](2);
        tokenAddresses[0] = address(token1);
        tokenAddresses[1] = address(token2);
        
        (uint256[] memory balances, uint256 timestamp, uint256 blockNumber) = 
            multiTokenQuery.queryBalances(user, tokenAddresses);
        
        // 验证余额
        TestAssert.assertEq(balances.length, 2, "Balance array length mismatch");
        TestAssert.assertEq(balances[0], 1000 * 10**6, "USDC balance mismatch");
        TestAssert.assertEq(balances[1], 2000 * 10**6, "USDT balance mismatch");
        
        // 验证时间戳和区块号
        TestAssert.assertGt(timestamp, 0, "Timestamp should be greater than 0");
        TestAssert.assertGt(blockNumber, 0, "Block number should be greater than 0");
    }
    
    function testQuerySingleToken() public view {
        (MultiTokenQuery.TokenInfo memory tokenInfo, uint256 timestamp, uint256 blockNumber) = multiTokenQuery.querySingleToken(user, address(token1));
        
        TestAssert.assertEq(tokenInfo.tokenAddress, address(token1), "Single token address mismatch");
        TestAssert.assertEq(tokenInfo.symbol, "USDC", "Single token symbol mismatch");
        TestAssert.assertEq(uint256(tokenInfo.decimals), 6, "Single token decimals mismatch");
        TestAssert.assertEq(tokenInfo.balance, 1000 * 10**6, "Single token balance mismatch");
    }
    
    function runAllTests() external view {
        testQueryMultipleTokens();
        testQueryBalances();
        testQuerySingleToken();
    }
}