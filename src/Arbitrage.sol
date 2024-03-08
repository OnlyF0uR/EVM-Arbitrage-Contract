// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IFlashLoanRecipient.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";

import "./interfaces/ISwapRouter.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./libraries/TransferHelper.sol";

contract Arbitrage is IFlashLoanRecipient  {
  IVault private immutable vault;
  address private immutable minter;

  struct SwapInfo {
    address poolAddress;
    address tokenIn;
    uint24 poolFee;
    bool isLegacy;
  }
  struct ArbitInfo {
    SwapInfo buy;
    SwapInfo sell;
  }

  constructor(address _flashAddrProvider) {
    minter = msg.sender;
    vault = IVault(_flashAddrProvider);
  }

  modifier minterOnly {
    require(msg.sender == minter, "MO"); // Minter Only
    _;
  }

  function execute(ArbitInfo memory _meta, uint256 _amount) external {
    IERC20[] memory tokens = new IERC20[](1);
    tokens[0] = IERC20(_meta.buy.tokenIn);
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = _amount;

    bytes memory userData = abi.encode(_meta);
    vault.flashLoan(this, tokens, amounts, userData);
  }

  function collect(address _token, address _receiver) external minterOnly {
    uint256 bal = IERC20(_token).balanceOf(address(this));
    require(bal > 0, "CO: NEF"); // Not enough funds

    TransferHelper.safeTransfer(_token, _receiver, bal);
  }

  function receiveFlashLoan(IERC20[] memory tokens, uint256[] memory amounts, uint256[] memory feeAmounts, bytes memory userData) external override {
    require(msg.sender == address(vault), "MC");

    ArbitInfo memory meta = abi.decode(userData, (ArbitInfo));
    require(address(tokens[0]) == meta.buy.tokenIn, "TNE");
    
    uint256 sellAmount;
    if (meta.buy.isLegacy) {
      sellAmount = swapV2(meta.buy.poolAddress, meta.buy.tokenIn, meta.sell.tokenIn, amounts[0]);
    } else {
      sellAmount = swapV3(meta.buy.poolAddress, meta.buy.tokenIn, meta.sell.tokenIn, meta.buy.poolFee, amounts[0]);
    }

    if (meta.sell.isLegacy) {
      swapV3(meta.sell.poolAddress, meta.sell.tokenIn, meta.buy.tokenIn, meta.sell.poolFee, sellAmount);
    } else {
      swapV3(meta.sell.poolAddress, meta.sell.tokenIn, meta.buy.tokenIn, meta.sell.poolFee, sellAmount);
    }

    uint256 totalDebt = amounts[0] + feeAmounts[0];
    IERC20(meta.buy.tokenIn).transfer(address(vault), totalDebt);
  }

  function swapV3(address _router, address _in, address _out, uint24 _fee, uint256 _amount) private returns (uint256) {
        require(_amount > 0, "V3: NA");
        require(IERC20(_in).balanceOf(address(this)) >= _amount, "V3: NEF"); // Not enough funds
        
        TransferHelper.safeApprove(_in, address(_router), _amount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: _in,
            tokenOut: _out,
            fee: _fee,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: _amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        uint256 output = ISwapRouter(_router).exactInputSingle(params);
        return output;
    }

    function swapV2(address _router, address _in, address _out, uint256 _amount) private returns (uint256) {
        require(_amount > 0, "V2: NA");
        require(IERC20(_in).balanceOf(address(this)) >= _amount, "V2: NEF");

        TransferHelper.safeApprove(_in, address(_router), _amount);

        address[] memory path = new address[](2);
        path[0] = _in;
        path[1] = _out;

        require(IERC20(_in).approve(_router, _amount), "V2: AF"); // Approval failed
        uint[] memory output = IUniswapV2Router02(_router).swapExactTokensForTokens(_amount, 0, path, msg.sender, block.timestamp);
        return output[0];
    }
}
