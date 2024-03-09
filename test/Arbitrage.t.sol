// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {Arbitrage} from "../src/Arbitrage.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";

address constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

address constant WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
address constant LINK = 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39;

contract ArbitrageTest is Test {
    Arbitrage private arbit;

    function setUp() public {
      arbit = new Arbitrage(BALANCER_VAULT);

      deal({
        token: WETH,
        to: address(arbit),
        give: 100e18
      });
    }

    function testV3Swap() public {
      console2.log("WMATIC balance before v3 swap", IERC20(WMATIC).balanceOf(address(arbit)));
      uint256 result = arbit.performV3Swap(0xE592427A0AEce92De3Edee1F18E0157C05861564, WETH, WMATIC, 500, 1e18);
      console2.log("WMATIC balance after v3 swap", result);

      assertGt(IERC20(WMATIC).balanceOf(address(arbit)), 0);
    }

    function testV2Swap() public {
      console2.log("LINK balance before v2 swap", IERC20(LINK).balanceOf(address(arbit)));
      uint256 result = arbit.performV2Swap(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff, WETH, LINK, 1e18, 1);
      console2.log("LINK balance after v2 swap", result);

      assertGt(IERC20(LINK).balanceOf(address(arbit)), 0);
    }

    function testFlashLoan() public {
      uint256 balanceBefore = IERC20(WETH).balanceOf(address(arbit));
      console2.log("WEHT balance before flash loan", balanceBefore);

      Arbitrage.Info memory _meta;
      _meta.tokenToBorrow = WETH;
      _meta.poolOneRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
      _meta.poolTwoRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

      _meta.mediatorToken = WMATIC;
      _meta.poolOneFee = 500;
      _meta.poolTwoFee = 0;

      _meta.poolOneAmountOutMin = 0;
      _meta.poolTwoAmountOutMin = 1;

      arbit.execute(_meta, 5e17);

      uint256 balanceAfter = IERC20(WETH).balanceOf(address(arbit));
      console2.log("WEHT balance after flash loan", IERC20(WETH).balanceOf(address(arbit)));

      console2.log("WETH diff (0.00)", balanceBefore - balanceAfter);

      assertNotEq(balanceBefore, balanceAfter); // Something must be lost or gained during the trades
    }
}
