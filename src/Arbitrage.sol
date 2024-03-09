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

  function swapV3(address _pool, address _in, address _out, uint24 _fee, uint256 _amount, uint160 _sqrtPriceLimitX96) public returns (uint256) {
    require(_amount > 0, "V3: NA");
    require(IERC20(_in).balanceOf(address(this)) >= _amount, "V3: NEF"); // Not enough funds
    IERC20(_in).approve(address(_router), _amount);

    IUniswapV3Pool pool = IUniswapV3Pool(_pool);
    pool.swap(
      address(this),
      // The direction of the swap, true for token0 to token1, false for token1 to token0
      _amount > 0,
      // The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
      _amount > 0 ? _amount : -_amount,
      // The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
      // value after the swap. If one for zero, the price cannot be greater than this value after the swap
      _sqrtPriceLimitX96,
      // Any data to be passed through to the callback
      ""
    );
  }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes data) external {}

    function swapV2(address _router, address _in, address _out, uint256 _amount) public returns (uint256) {
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
