pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

interface ERC20 {
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
    function transfer(address _to, uint _value) external returns (bool);
    function decimals() external view returns (uint);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint);
}

interface ISettlement {
    function getListedTokens() external view returns (ERC20[] memory tokens);
    function quote(ERC20 srcToken, ERC20 destToken, uint256 srcAmount, uint256 blockNumber) external view returns (uint destAmount); 
    function getQuota(ERC20 tradeToken, bool isDestToken) external view returns (uint quota);
    function tradeFeeBps() external view returns(unit feeBps);
    function swapTokensWithTrust(ERC20 srcToken, ERC20 destToken, uint srcAmount, uint destAmountMin, address to) external returns (uint destAmount);
    function swapTokenForETHWithTrust(ERC20 srcToken, uint srcAmount, uint destAmountMin, address to) external returns (uint destAmount);
    function swapETHForToken(ERC20 destToken, uint destAmountMin, address to) external returns (uint destAmount);  
    function swapTokenForETH(ERC20 srcToken, uint srcAmount, uint destAmountMin, address to) external  returns (uint destAmount);
    function swapTokens(ERC20 srcToken, ERC20 destToken, uint srcAmount, uint destAmountMin, address to) external returns (uint destAmount);
}

contract LibRates {
        // bps - basic rate steps. one step is 1 / 10000 of the rate.
    struct StepFunction {
        int[] x; // quantity for each step. Quantity of each step includes previous steps.
        int[] y; // rate change per quantity step  in bps.
    }
}

interface IOneSwap {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint amountOut);
    
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract PermissionGroups{
    
    address public admin;
    address public pendingAdmin;
    
    constructor() public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin,"onlyAdmin");
        _;
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        pendingAdmin = newAdmin;
    }

    function claimAdmin() external {
        require(pendingAdmin == msg.sender,"pendingAdmin != msg.sender");
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

}

contract OneSwap is PermissionGroups{

    uint256 internal constant MAX_UINT = 2**256 - 1;  
    ISettlement public settlement;
        
    function setSettlement(ISettlement _settlement) external onlyAdmin {
        settlement = _settlement;
    }
    
    // if you do not trust settlement contract, you have no need to approve 
    function test_swapTokens(ERC20 srcToken, ERC20 destToken, uint srcAmount, uint destAmountMin, address to) 
    external returns (uint destAmount) {
        
    // quote the destAmont 
    uint quoteAmountOut = settlement.quote(srcToken,destToken,srcAmount,block.number);

    // require the quote destAmount is bigger than or equal to destAmountMin
    require(quoteAmountOut >= destAmountMin, "quote amount out is not enough");
    
    // record the destToken balance of of to address before swapTokens
    uint balanceBeforeSwap = srcToken.balanceOf(to);
    TransferHelper.safeTransferFrom(address(srcToken), msg.sender, address(settlement), srcAmount);
    
    uint swapAmountOut = settlement.swapTokens(srcToken,destToken,srcAmount,destAmountMin,to);

    // query the destToken balance of to address and substract balance before swapTokens, 
    uint balanceAfterSwap = srcToken.balanceOf(to);
    uint actualAmountOut = balanceAfterSwap - balanceBeforeSwap;

    // require the balance difference value is bigger than or equal to destAmountMin.
    require(actualAmountOut >= destAmountMin, "actual amout out is not enough");
    
    return actualAmountOut;
}

    // if you trust Settlemnt contract, you have to approve Settlemnt Contract 
    function test_swapTokensWithTrust(ERC20 srcToken, ERC20 destToken, uint srcAmount, uint destAmountMin, address to) 
        external returns (uint destAmount){

        if(srcToken.allowance(address(this), address(settlement)) < srcAmount) {
            TransferHelper.safeApprove(address(srcToken), address(settlement), MAX_UINT);
        } 
        uint swapAmountOut = settlement.swapTokensWithTrust(srcToken, destToken, srcAmount, destAmountMin, to);
        return swapAmountOut;
    }
    
     function quote(ERC20 srcToken, ERC20 destToken, uint256 srcAmount, uint256 blockNumber) 
        public view returns (uint destAmount) {
         return settlement.quote(srcToken, destToken, srcAmount, blockNumber);
     }
    
    
}