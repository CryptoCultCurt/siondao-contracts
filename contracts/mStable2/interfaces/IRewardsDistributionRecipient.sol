// SPDX-License-Identifier: AGPL-3.0-or-later
// Internal
// Libs

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";


interface IRewardsDistributionRecipient {
    function notifyRewardAmount(uint256 reward) external;

    function getRewardToken() external view returns (IERC20Upgradeable);
}

interface IRewardsRecipientWithPlatformToken {
    function notifyRewardAmount(uint256 reward) external;

    function getRewardToken() external view returns (IERC20Upgradeable);

    function getPlatformToken() external view returns (IERC20Upgradeable);
}