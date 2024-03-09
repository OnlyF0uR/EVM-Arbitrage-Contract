// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {Arbitrage} from "../src/Arbitrage.sol";
// import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";

address constant WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
address constant ROUTER = 0x86f1d8390222A3691C28938eC7404A1661E618e0;

address constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

contract ArbitrageTest is Test {
    IWETH private constant weth = IWETH(WETH);
    Arbitrage private arbit = new Arbitrage(BALANCER_VAULT);

    function setUp() public {
      // Give the arbit contract some weth
      deal({
        token: address(weth),
        to: address(arbit),
        give: 100e18
      });

      console2.log("WETH balance", weth.balanceOf(address(arbit)));
    }

    function testV3Swap() public {
      uint256 result = arbit.swapV3(ROUTER, address(weth), WMATIC, 500, 2e18);
      console2.log("V3 Result", result);

      assertEq(result, 0, "resulting tokens == 0");
    }

    function testV2Swap() public {
      // uint256 result = arbit.swapV2(ROUTER, WETH, WMATIC, 1e18 * 2);
      // console2.log("V2 Result", result);

      // assertEq(result, 0, "resulting tokens == 0");
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}