// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IASTRewards {
    function getRewardsCalc(uint256 _id) external view returns (uint256);

   function updateData(
        uint256 _tokenId,
        uint256 _rewards,
        address _from
    ) external;
}