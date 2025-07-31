// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
}

contract MultiTokenQuery {
    struct TokenInfo {
        address tokenAddress;
        string symbol;
        uint8 decimals;
        uint256 balance;
    }
    
    struct QueryResult {
        address queryAddress;
        TokenInfo[] tokens;
        uint256 timestamp;
        uint256 blockNumber;
    }
    
    /**
     * @dev 批量查询指定地址的多个token信息
     * @param user 要查询的用户地址
     * @param tokenAddresses token合约地址数组
     * @return result 查询结果，包含所有token信息、时间戳和区块号
     */
    function queryMultipleTokens(
        address user,
        address[] calldata tokenAddresses
    ) external view returns (QueryResult memory result) {
        result.queryAddress = user;
        result.timestamp = block.timestamp;
        result.blockNumber = block.number;
        
        TokenInfo[] memory tokens = new TokenInfo[](tokenAddresses.length);
        
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            address tokenAddr = tokenAddresses[i];
            
            tokens[i].balance = IToken(tokenAddr).balanceOf(user);
            tokens[i].symbol = IToken(tokenAddr).symbol();
            tokens[i].decimals = IToken(tokenAddr).decimals();
            tokens[i].tokenAddress = tokenAddr;
        }
        
        result.tokens = tokens;
        return result;
    }
    
    /**
     * @dev 简化版本：只返回余额数组
     * @param user 要查询的用户地址
     * @param tokenAddresses token合约地址数组
     * @return balances 余额数组
     * @return timestamp 当前时间戳
     * @return blockNumber 当前区块号
     */
    function queryBalances(
        address user,
        address[] calldata tokenAddresses
    ) external view returns (
        uint256[] memory balances,
        uint256 timestamp,
        uint256 blockNumber
    ) {
        balances = new uint256[](tokenAddresses.length);
        
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            balances[i] = IToken(tokenAddresses[i]).balanceOf(user);
        }
        
        return (balances, block.timestamp, block.number);
    }
    
    /**
     * @dev 查询单个token的完整信息
     * @param user 要查询的用户地址
     * @param tokenAddress token合约地址
     * @return tokenInfo token信息
     * @return timestamp 当前时间戳
     * @return blockNumber 当前区块号
     */
    function querySingleToken(
        address user,
        address tokenAddress
    ) external view returns (
        TokenInfo memory tokenInfo,
        uint256 timestamp,
        uint256 blockNumber
    ) {
        tokenInfo.tokenAddress = tokenAddress;
        tokenInfo.balance = IToken(tokenAddress).balanceOf(user);
        tokenInfo.symbol = IToken(tokenAddress).symbol();
        tokenInfo.decimals = IToken(tokenAddress).decimals();
        
        return (tokenInfo, block.timestamp, block.number);
    }
    
    /**
     * @dev 批量查询多个地址的单个token余额
     * @param users 要查询的用户地址数组
     * @param tokenAddress token合约地址
     * @return balances 余额数组
     * @return timestamp 当前时间戳
     * @return blockNumber 当前区块号
     */
    function queryMultipleUsers(
        address[] calldata users,
        address tokenAddress
    ) external view returns (
        uint256[] memory balances,
        uint256 timestamp,
        uint256 blockNumber
    ) {
        balances = new uint256[](users.length);
        
        for (uint256 i = 0; i < users.length; i++) {
            balances[i] = IToken(tokenAddress).balanceOf(users[i]);
        }
        
        return (balances, block.timestamp, block.number);
    }
}