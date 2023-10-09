// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// imported contracts and libraries

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";


// interfaces
import "./interface/ILiquidityDex.sol";
import "./interface/pearl/IRouter.sol";

// libraries
import "./library/Addresses.sol";

// constants and types
import {PearlDexStorage} from "./storage/PearlDex.sol";

import "hardhat/console.sol";

contract PearlDex is     
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ILiquidityDex, 
    PearlDexStorage 
    {
    using SafeERC20Upgradeable for IERC20Upgradeable;

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

    function doSwap(
        uint256 _sellAmount,
        uint256 _minBuyAmount,
        address _receiver,
        address[] memory _path
    ) external override returns (uint256) {
        address sellToken = _path[0];
        console.log('setting allowance of token ', sellToken, ' to pearlRouter');
        console.log('sellAmount: ', _sellAmount);
        console.log('Pearl Router: ', Addresses.pearlRouter);
        IERC20Upgradeable(sellToken).safeIncreaseAllowance(Addresses.pearlRouter, _sellAmount);
        console.log('doswap increased allowance ofr sellToken: ', sellToken);

        IRouter.Route[] memory routes = new IRouter.Route[](_path.length-1);
        for (uint256 idx = 0; idx < _path.length-1; idx++) {
            routes[idx].from = _path[idx];
            routes[idx].to = _path[idx+1];
            routes[idx].stable = stable(_path[idx], _path[idx+1]);
        }
        for (uint i=0;i<routes.length;i++) {
            console.log(routes[i].from, routes[i].to, routes[i].stable);
        }
        console.log(_sellAmount, _minBuyAmount, _receiver);
        console.log(Addresses.pearlRouter);
        //console.log(routes);
        uint256[] memory returned = IRouter(Addresses.pearlRouter)
            .swapExactTokensForTokens(
                _sellAmount,
                _minBuyAmount,
                routes,
                _receiver,
                block.timestamp
            );

        return returned[returned.length - 1];
    }

    function pairSetup(
        address _token0,
        address _token1,
        bool _stable
    ) external onlyAdmin {
        _pairStable[_token0][_token1] = _stable;
        _pairStable[_token1][_token0] = _stable;
    }

    function stable(
        address _token0,
        address _token1
    ) public view returns (bool) {
        return _pairStable[_token0][_token1];
    }

    receive() external payable {}
}