// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {Arbitrage} from "../src/Arbitrage.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";

address constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

address constant WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

address constant WETH_MATIC_POOL = 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8;

contract ArbitrageTest is Test {
    Arbitrage private arbit;

    function setUp() public {
      arbit = new Arbitrage(BALANCER_VAULT);

      deal({
        token: WETH,
        to: address(arbit),
        give: 100e18
      });

      console2.log("WETH balance before swaps", IERC20(WETH).balanceOf(address(arbit)));
    }

    function testV3Swap() public {
      uint256 result = arbit.performV3Swap(WETH, WMATIC, 500, 1e18);
      console2.log("WMATIC balance after v3 swap", result);

      assertGt(IERC20(WMATIC).balanceOf(address(arbit)), 0);
    }

    function testV2Swap() public {
      uint256 before = IERC20(WMATIC).balanceOf(address(arbit));

      uint256 result = arbit.performV2Swap(WETH, WMATIC, 1e18, 1);
      console2.log("WMATIC balance after v2 swap", result);

      assertGt(IERC20(WMATIC).balanceOf(address(arbit)), before);
    }
}
