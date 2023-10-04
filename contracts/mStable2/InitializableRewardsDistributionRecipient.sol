// SPDX-License-Identifier: AGPL-3.0-or-later
// Internal
// Libs


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./StakingTokenWrapper.sol";
import "../veSion/library/Stablemath.sol";
import "./libraries/MassetHelpers.sol";
import "./interfaces/IRewardsDistributionRecipient.sol";
import "./ImmutableModule.sol";

abstract contract InitializableRewardsDistributionRecipient is
    Initializable,
    AccessControlUpgradeable,
    IRewardsDistributionRecipient,
    ImmutableModule
{
    // This address has the ability to distribute the rewards
    address public rewardsDistributor;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
       address _nexus,
       address _rewardsDistributor
    ) public initializer onlyInitializing{
        ImmutableModule.initialize(_nexus);
        rewardsDistributor = _rewardsDistributor;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) 
        internal 
        override 
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE) {}

    // ---  modifiers

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Restricted to admins"
        );
        _;
    }



    /**
     * @dev Only the rewards distributor can notify about rewards
     */
    modifier onlyRewardsDistributor() {
        require(msg.sender == rewardsDistributor, "Caller is not reward distributor");
        _;
    }

    /**
     * @dev Change the rewardsDistributor - only called by mStable governor
     * @param _rewardsDistributor   Address of the new distributor
     */
    function setRewardsDistribution(address _rewardsDistributor) external onlyGovernor {
        rewardsDistributor = _rewardsDistributor;
    }
}