// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// imported contracts and libraries
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// interfaces

import "./interface/IUniversalLiquidator.sol";
import "./interface/IUniversalLiquidatorRegistry.sol";
import "./interface/ILiquidityDex.sol";

// libraries
import "./library/DataTypes.sol";
import "./library/Errors.sol";

contract UniversalLiquidator is     
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    IUniversalLiquidator {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public pathRegistry;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // ---  modifiers

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Restricted to admins"
        );
        _;
    }

    function swap(address _sellToken, address _buyToken, uint256 _sellAmount, uint256 _minBuyAmount, address _receiver)
        external
        override
        returns (uint256 receiveAmt)
    {
        DataTypes.SwapInfo[] memory swapInfo = IUniversalLiquidatorRegistry(pathRegistry).getPath(_sellToken, _buyToken);

        IERC20Upgradeable(_sellToken).safeTransferFrom(msg.sender, swapInfo[0].dex, _sellAmount);

        uint256 minBuyAmount;
        address receiver;
        for (uint256 idx; idx < swapInfo.length;) {
            if (idx != swapInfo.length - 1) {
                // if not last element, set receiver to next dex and set minBuyAmount to 1
                minBuyAmount = 1;
                receiver = swapInfo[idx + 1].dex;
            } else {
                // if last element, set minBuyAmount to _minBuyAmount
                minBuyAmount = _minBuyAmount;
                receiver = _receiver;
            }
            receiveAmt = _swap(
                IERC20Upgradeable(swapInfo[idx].paths[0]).balanceOf(swapInfo[idx].dex),
                minBuyAmount,
                receiver,
                swapInfo[idx].dex,
                swapInfo[idx].paths
            );
            unchecked {
                ++idx;
            }
        }
    }

    function _swap(uint256 _sellAmount, uint256 _minBuyAmount, address _receiver, address _dex, address[] memory _path)
        internal
        returns (uint256 receiveAmt)
    {
        receiveAmt = ILiquidityDex(_dex).doSwap(_sellAmount, _minBuyAmount, _receiver, _path);

        emit Swap(_path[0], _path[_path.length - 1], _receiver, msg.sender, _sellAmount, _minBuyAmount);
    }

    function setPathRegistry(address _pathRegistry) public onlyAdmin {
        if (_pathRegistry == address(0)) revert Errors.InvalidAddress();
        pathRegistry = _pathRegistry;
    }

    receive() external payable {}
}