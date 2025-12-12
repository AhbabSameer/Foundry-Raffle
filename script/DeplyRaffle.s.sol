// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Raffle} from "../src/Raffle.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscriptions, FundSubscription, AddConsumer} from "script/Interactions.s.sol";

contract DeployRaffle is Script {
    function run() public {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        //local -> deploy mocks , get local config
        //sepolia -> get sepolia config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            CreateSubscriptions subscriptionCreator = new CreateSubscriptions();

            (uint256 subId, address coordinator) =
                subscriptionCreator.createSubscription(config.vrfCoordinator, config.account);

            config.subscriptionId = subId;
            config.vrfCoordinator = coordinator;

            //fund
            FundSubscription funder = new FundSubscription();
            funder.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link, config.account);
        }

        helperConfig.setLocalConfig(config);

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer consumerAddress = new AddConsumer();
        consumerAddress.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId, config.account);
        return (raffle, helperConfig);
    }
}
