// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

//import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { IERC20Upgradeable }  from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { AbstractVault } from "../../inheritance/AbstractVault.sol";
import "../../interface/IRewardsVault.sol";
import "../../interface/IVaultManager.sol";
import "../../interface/IMark2Market.sol";

import "hardhat/console.sol";

contract CaviarVault is AbstractVault {
    using MathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    IERC20Upgradeable private _asset;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        string calldata _nameArg,
        string calldata _symbolArg,
        address _assetArg
    ) external initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __ERC20_init(_nameArg, _symbolArg);
        _asset = IERC20Upgradeable(_assetArg);
        AbstractVault._initialize(IERC20Upgradeable(_assetArg));
    }
}
