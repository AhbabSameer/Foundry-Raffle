// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeplyRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;

    address public player = makeAddr("player");
    uint256 public constant STARTING_BALANCE = 10 ether;

    event raffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;

        vm.deal(player, STARTING_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assertEq(
            uint256(raffle.getRaffleState()),
            uint256(Raffle.RaffleState.OPEN)
        );
    }

    // enter Raffle test //
    function testRaffleRevertsWhenYouDontPayEnough() public {
        vm.prank(player);

        vm.expectRevert(Raffle.Raffle__sendMoreToEnterRaffle.selector);

        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();

        address recordPlayer = raffle.getPlayer(0);
        assertEq(recordPlayer, player);
    }

    function testEnterRaffleEmitsEvent() public {
        vm.prank(player);

        vm.expectEmit(true, false, false, false, address(raffle));
        emit raffleEntered(player);

        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayerToEnterWhenRaffleIsCalculating() public {
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();
    }
}
