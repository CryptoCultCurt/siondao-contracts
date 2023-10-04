// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;


interface IRewardsVault {

    function stake(uint256) external;
    function stakeWithBeneficiary(address, uint256) external;
    function exitWithBeneficiary(address _beneficiary) external;
    function exit() external;
    function withdraw(uint256) external;
    function withdrawWithBeneficiary(address, uint256) external;
    function claim() external;
    function claimWithBeneficiary(address) external;
}