# on-chain liquidity provider
on-chain liquidity provider for aggregator

## contract address 
* Settlement mainnet: 0x5F5207dF64B0F7Ed56BF0b61733d3BE8795f4e5A
* Onebit Router mainnet: 0x8949218FDBd449128861e04cAF59224bc563477f

## Settlement interface function
```
interface ISettlement {
    function getListedTokens() external view returns (ERC20[] memory tokens);
    function quote(ERC20 srcToken, ERC20 destToken, uint256 srcAmount, uint256 blockNumber) external view returns (uint destAmount); 
    function swapTokensWithTrust(ERC20 srcToken, ERC20 destToken, uint srcAmount, uint destAmountMin, address to) external returns (uint destAmount);
    function swapTokenForETHWithTrust(ERC20 srcToken, uint srcAmount, uint destAmountMin, address to) external returns (uint destAmount);
    function swapETHForToken(ERC20 destToken, uint destAmountMin, address to) external returns (uint destAmount);  
    function swapTokenForETH(ERC20 srcToken, uint srcAmount, uint destAmountMin, address to) external  returns (uint destAmount);
    function swapTokens(ERC20 srcToken, ERC20 destToken, uint srcAmount, uint destAmountMin, address to) external returns (uint destAmount);

}
```

---


## getListedTokens
Get all the support tokens list

```
function getListedTokens() external view returns (ERC20[] memory tokens)
```

**Parameters**

none

**Returns**

`tokens`  the supported tokes arraylist

---


## quote
Quote the destination token amount with the src token amount

```
function quote(ERC20 srcToken, ERC20 destToken, uint256 srcAmount, uint256 blockNumber) external view returns (uint destAmount)
```

**Parameters**

`srcToken` Src token 

`destToken` Destination token  

`srcAmount` Amount of src token 

`blockNumber` current blockNumber 

**Returns**

`destAmount`  Amount of Destination token  


---


## swapTokens
Execute a ERC20 token -> ERC20 token trade, on condition the caller must transfer amount of the src token to Settlement contract before call it, and require the balance difference value between after call and before call, please refer to sample for detail

```
function swapTokens(ERC20 srcToken, ERC20 destToken, uint srcAmount, uint destAmountMin, address to) external returns (uint destAmount)
```

**Parameters**

`srcToken` Src token 

`destToken` Destination token  

`srcAmount` Amount of src token 

`destAmountMin` required min Amount of Destination token 

`to` swap token to the Destination address

**Returns**

`destAmount`   Amount of actual destination tokens 

**Sample:**
```
function test_swapTokens(ERC20 srcToken, ERC20 destToken, uint srcAmount, uint destAmountMin, address to) 
    external returns (uint destAmount) {
        
    // quote the destAmont 
    uint quoteAmountOut = settlement.quote(srcToken,destToken,srcAmount,block.number);

    // require the quote destAmount is bigger than or equal to destAmountMin
    require(quoteAmountOut >= destAmountMin, "quote amount out is not enough");
    
    // record the destToken balance of of to address before swapTokens
    uint balanceBeforeSwap = srcToken.balanceOf(to);
    TransferHelper.safeTransferFrom(address(srcToken), msg.sender, address(settlement), srcAmount);
    
    uint swapAmountOut = settlement.swapTokens(srcToken,destToken,srcAmount,to);

    // query the destToken balance of to address and substract balance before swapTokens, 
    uint balanceAfterSwap = srcToken.balanceOf(to);
    uint actualAmountOut = balanceAfterSwap - balanceBeforeSwap;

    // require the balance difference value is bigger than or equal to destAmountMin.
    require(actualAmountOut >= destAmountMin, "actual amout out is not enough");
    
    return actualAmountOut;
}
```


---

## swapTokenForETH
Execute a ERC20 token -> ETH trade, on condition the caller must transfer amount of the src token to Settlement contract before call it, and require the balance difference value between after call and before call

```
function swapTokenForETH(ERC20 srcToken, uint srcAmount, uint destAmountMin, address to) external  returns (uint destAmount);
```

**Parameters**

`srcToken` Src token 

`srcAmount` Amount of src token 

`destAmountMin` required min Amount of Destination token 

`to` swap token to the Destination address

**Returns**

`destAmount`   Amount of actual destination tokens 


---

## swapETHForToken
Execute a ETH -> ERC20 token trade, on condition the caller must transfer amount of the ETH to Settlement contract before call it, and require the balance difference value between after call and before call

```
function swapETHForToken(ERC20 destToken, uint destAmountMin, address to) external  returns (uint destAmount);
```

**Parameters**

`destToken` dest token 

`destAmountMin` required min Amount of Destination token 

`to` swap token to the Destination address

**Returns**

`destAmount`   Amount of actual destination tokens 


---

## swapTokensWithTrust
Execute a ERC20 token -> ERC20 token trade, on condition the caller must approve Settlement

```
function swapTokensWithTrust(ERC20 srcToken, ERC20 destToken, uint srcAmount, uint destAmountMin, address to) external returns (uint destAmount)
```

**Parameters**

`srcToken` Src token 

`destToken` Destination token  

`srcAmount` Amount of src token 

`destAmountMin` required min Amount of Destination token 

`to` swap token to the Destination address

**Returns**

`destAmount`  Amount of actual destination tokens 

**Sample:**
```
    function test_swapTokensWithTrust(ERC20 srcToken, ERC20 destToken, uint srcAmount, uint destAmountMin, address to) 
    external returns (uint destAmount){

    if(srcToken.allowance(address(this), address(settlement)) < srcAmount) {
        TransferHelper.safeApprove(address(srcToken), address(settlement), MAX_UINT);
    } 
    uint swapAmountOut = settlement.swapTokensWithTrust(srcToken, destToken, srcAmount, destAmountMin, to);
    return swapAmountOut;
}
```


---

## swapTokenForETHWithTrust
Execute a ERC20 token -> ETH trade, on condition the caller must approve Settlement

```
function swapTokenForETHWithTrust(ERC20 srcToken, uint srcAmount, uint destAmountMin, address to) external returns (uint destAmount);
```

**Parameters**

`srcToken` Src token 

`srcAmount` Amount of src token 

`destAmountMin` required min Amount of Destination token 

`to` swap token to the Destination address

**Returns**

`destAmount`  Amount of actual destination tokens 


---


## How to aggregate settlement

1. Contact us to add your caller contract into whitelist of Settlement contract
2. Get all the support tokens by function **getListedTokens**
3. Quote destination token amount by function **quote**  
4. Trade:
    - swap tokens by function **swapTokens/swapETHForToken/swapTokenForETH** if you do not trust the Settlement contract
    - swap tokens by function **swapTokensWithTrust/swapTokenForETHWithTrust** if you trust the Settlement contract


