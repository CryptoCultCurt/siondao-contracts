// SPDX-License-Identifier: AGPL-3.0-or-later
// Internal
// Libs
/**
 * @title  StakingRewardsWithPlatformToken
 * @author Stability Labs Pty. Ltd.
 * @notice Rewards stakers of a given LP token (a.k.a StakingToken) with RewardsToken, on a pro-rata basis
 * additionally, distributes the Platform token airdropped by the platform
 * @dev    Derives from ./StakingRewards.sol and implements a secondary token into the core logic
 * @dev StakingRewardsWithPlatformToken is a StakingTokenWrapper and InitializableRewardsDistributionRecipient
 */

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./StakingTokenWrapper.sol";
import "../veSion/library/Stablemath.sol";
import "./libraries/MassetHelpers.sol";

contract PlatformTokenVendor {
    IERC20Upgradeable public immutable platformToken;
    address public immutable parentStakingContract;

    /** @dev Simple constructor that stores the parent address */
    constructor(IERC20Upgradeable _platformToken) {
        parentStakingContract = msg.sender;
        platformToken = _platformToken;
        MassetHelpers.safeInfiniteApprove(address(_platformToken), msg.sender);
    }

    /**
     * @dev Re-approves the StakingReward contract to spend the platform token.
     * Just incase for some reason approval has been reset.
     */
    function reApproveOwner() external {
        MassetHelpers.safeInfiniteApprove(address(platformToken), parentStakingContract);
    }
}