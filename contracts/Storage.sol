// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Creation.sol";
import "./Authorization.sol";
import "./tokenboundaccount/ERC6551Registry.sol";
import "./utils/Governance.sol";
import "./utils/ChainlinkVRF.sol";

contract Storage {
    Governance internal governance;

    Creation internal creation;

    Authorization internal authorization;

    ERC6551Registry internal registry;

    ChainlinkVRF internal randomGenerator;
}
