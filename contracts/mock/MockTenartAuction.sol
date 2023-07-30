// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../TenartAuction.sol";

contract MockTenartAuction is TenartAuction {
    uint256 public time;

    function setTime(uint256 t) public {
        time = t;
    }

    function increaseTime(uint256 t) public {
        time += t;
    }

    function _getNow() internal view override returns (uint256) {
        return time;
    }
}
