# Settlement
A open swap for aggregator

## Settlement interface
```
interface ISettlement {
    function swapTokens(ERC20 srcToken, ERC20 destToken, uint srcAmount, address to) external returns (uint destAmount);
    function quote(ERC20 srcToken, ERC20 destToken, uint256 srcAmount, uint256 blockNumber) external view returns (uint destAmount); 
    function getListedTokens() external view returns (ERC20[] memory tokens);
}
```

## 1, contact us to let your caller contract be added into whitelist of Settlement contract

## 2, get all the support tokens by function getTokenList: 
    function getListedTokens() external view returns (ERC20[] memory tokens);

## 3, quote: quote destToken amount  
### param: blockNumber should be current blockNumber      
    function quote(ERC20 srcToken, ERC20 destToken, uint256 srcAmount, uint256 blockNumber) external 


## 4, swapTokens: you have no need to approve settlement contract
    function swapTokens(ERC20 srcToken, ERC20 destToken, uint srcAmount, address to) external returns (uint destAmount);

    before swapTokens : 
    quote the destAmont and require the quote destAmount is bigger than or equal to destAmountMin;
    transfer the token into the settlement contract;
    check the destToken balance of to address; 
    
    execute swapTokens
    
    after swapTokens: 
    you should check the destToken balance of to address and substract balance before swapTokens, 
    require the balance difference value is bigger than or equal to destAmountMin.

    sample:
    ```
    function test_swapTokens(ERC20 srcToken, ERC20 destToken, uint srcAmount, uint destAmountMin, address to) 
        external returns (uint destAmount) {
            
        uint quoteAmountOut = settlement.quote(srcToken,destToken,srcAmount,block.number);
        require(quoteAmountOut >= destAmountMin, "quote amount out is not enough");
        
        uint balanceBeforeSwap = srcToken.balanceOf(to);
        TransferHelper.safeTransferFrom(address(srcToken), msg.sender, address(settlement), srcAmount);
        
        uint swapAmountOut = settlement.swapTokens(srcToken,destToken,srcAmount,to);
        uint balanceAfterSwap = srcToken.balanceOf(to);
        uint actualAmountOut = balanceAfterSwap - balanceBeforeSwap;
        require(actualAmountOut >= destAmountMin, "actual amout out is not enough");
        
        return actualAmountOut;
    }
    ```

## 5, swapTokensWithTrust: you must approve settlement contract
    function swapTokensWithTrust(ERC20 srcToken, ERC20 destToken, uint srcAmount, uint destAmountMin, address to) external returns (uint destAmount); 
    
    sample:
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