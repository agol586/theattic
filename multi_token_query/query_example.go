package contracts

import (
	"context"
	"fmt"
	"log"
	"math/big"
	"strings"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

// TokenInfo 表示单个token的信息
type TokenInfo struct {
	TokenAddress common.Address
	Symbol       string
	Decimals     uint8
	Balance      *big.Int
}

// QueryResult 表示查询结果
type QueryResult struct {
	QueryAddress common.Address
	Tokens       []TokenInfo
	Timestamp    *big.Int
	BlockNumber  *big.Int
}

// MultiTokenQueryClient 多token查询客户端
type MultiTokenQueryClient struct {
	client          *ethclient.Client
	contractAddress common.Address
	contract        *bind.BoundContract
}

// NewMultiTokenQueryClient 创建新的查询客户端
func NewMultiTokenQueryClient(rpcURL string, contractAddress common.Address) (*MultiTokenQueryClient, error) {
	client, err := ethclient.Dial(rpcURL)
	if err != nil {
		return nil, fmt.Errorf("连接以太坊节点失败: %v", err)
	}

	// 这里需要替换为实际的合约ABI
	contractABI := `[{"inputs":[{"internalType":"address","name":"user","type":"address"},{"internalType":"address[]","name":"tokenAddresses","type":"address[]"}],"name":"queryMultipleTokens","outputs":[{"components":[{"internalType":"address","name":"queryAddress","type":"address"},{"components":[{"internalType":"address","name":"tokenAddress","type":"address"},{"internalType":"string","name":"symbol","type":"string"},{"internalType":"uint8","name":"decimals","type":"uint8"},{"internalType":"uint256","name":"balance","type":"uint256"}],"internalType":"struct MultiTokenQuery.TokenInfo[]","name":"tokens","type":"tuple[]"},{"internalType":"uint256","name":"timestamp","type":"uint256"},{"internalType":"uint256","name":"blockNumber","type":"uint256"}],"internalType":"struct MultiTokenQuery.QueryResult","name":"result","type":"tuple"}],"stateMutability":"view","type":"function"}]`

	parsedABI, err := abi.JSON(strings.NewReader(contractABI))
	if err != nil {
		return nil, fmt.Errorf("解析合约ABI失败: %v", err)
	}

	contract := bind.NewBoundContract(contractAddress, parsedABI, client, client, client)

	return &MultiTokenQueryClient{
		client:          client,
		contractAddress: contractAddress,
		contract:        contract,
	}, nil
}

// QueryMultipleTokens 查询多个token的信息
func (c *MultiTokenQueryClient) QueryMultipleTokens(ctx context.Context, userAddress common.Address, tokenAddresses []common.Address) (*QueryResult, error) {
	var result []interface{}
	err := c.contract.Call(&bind.CallOpts{Context: ctx}, &result, "queryMultipleTokens", userAddress, tokenAddresses)
	if err != nil {
		return nil, fmt.Errorf("调用合约失败: %v", err)
	}

	// 解析返回结果
	if len(result) == 0 {
		return nil, fmt.Errorf("合约返回结果为空")
	}

	// 这里需要根据实际的ABI结构来解析结果
	// 简化示例，实际使用时需要正确解析struct
	return &QueryResult{
		QueryAddress: userAddress,
		// ... 其他字段需要从result中解析
	}, nil
}

// QueryBalances 简化版本：只查询余额
func (c *MultiTokenQueryClient) QueryBalances(ctx context.Context, userAddress common.Address, tokenAddresses []common.Address) ([]*big.Int, *big.Int, *big.Int, error) {
	var result []interface{}
	err := c.contract.Call(&bind.CallOpts{Context: ctx}, &result, "queryBalances", userAddress, tokenAddresses)
	if err != nil {
		return nil, nil, nil, fmt.Errorf("调用合约失败: %v", err)
	}

	// 解析返回的余额数组、时间戳和区块号
	balances := result[0].([]*big.Int)
	timestamp := result[1].(*big.Int)
	blockNumber := result[2].(*big.Int)

	return balances, timestamp, blockNumber, nil
}

// 使用示例
func ExampleUsage() {
	// 连接到以太坊主网或测试网
	rpcURL := "https://mainnet.infura.io/v3/YOUR_PROJECT_ID"
	contractAddress := common.HexToAddress("0x...") // 替换为实际部署的合约地址

	client, err := NewMultiTokenQueryClient(rpcURL, contractAddress)
	if err != nil {
		log.Fatalf("创建客户端失败: %v", err)
	}

	// 要查询的用户地址
	userAddress := common.HexToAddress("0x742d35Cc6634C0532925a3b8D4C9db96c4b4d8b6")

	// 要查询的token地址列表
	tokenAddresses := []common.Address{
		common.HexToAddress("0xA0b86a33E6441b8C0b8b8C0b8b8C0b8b8C0b8b8C"), // USDC
		common.HexToAddress("0xdAC17F958D2ee523a2206206994597C13D831ec7"), // USDT
		common.HexToAddress("0x6B175474E89094C44Da98b954EedeAC495271d0F"), // DAI
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// 查询余额
	balances, timestamp, blockNumber, err := client.QueryBalances(ctx, userAddress, tokenAddresses)
	if err != nil {
		log.Fatalf("查询失败: %v", err)
	}

	fmt.Printf("查询结果:\n")
	fmt.Printf("用户地址: %s\n", userAddress.Hex())
	fmt.Printf("时间戳: %s\n", timestamp.String())
	fmt.Printf("区块号: %s\n", blockNumber.String())
	fmt.Printf("查询时间: %s\n", time.Unix(timestamp.Int64(), 0).Format("2006-01-02 15:04:05"))

	for i, balance := range balances {
		fmt.Printf("Token %d (%s): %s\n", i+1, tokenAddresses[i].Hex(), balance.String())
	}
}

// 集成到现有服务中的示例函数
// 注意：这需要根据实际的服务结构进行调整
func QueryTokenBalancesForService(rpcURL string, contractAddress common.Address, userAddress string, tokenAddresses []string) (*QueryResult, error) {
	// 这里可以集成到现有的服务中
	// 使用项目中已有的以太坊客户端连接

	user := common.HexToAddress(userAddress)
	tokens := make([]common.Address, len(tokenAddresses))
	for i, addr := range tokenAddresses {
		tokens[i] = common.HexToAddress(addr)
	}

	// 使用合约查询
	client, err := NewMultiTokenQueryClient(rpcURL, contractAddress)
	if err != nil {
		return nil, err
	}

	return client.QueryMultipleTokens(context.Background(), user, tokens)
}
