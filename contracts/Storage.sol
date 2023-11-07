// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Creation.sol";
import "./Authorization.sol";
import "./utils/Governance.sol";

contract Storage {
    Governance internal governance;

    Creation internal creation;

    Authorization internal authorization;
}
