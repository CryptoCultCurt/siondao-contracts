// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {IPancakePair, IPancakeRouter02} from "./connectors/PancakeV2.sol";
import {IWETH} from "./interfaces/IWETH.sol";

import "hardhat/console.sol";

//import  "./libraries/Babylonian.sol";

/*
 * @author Inspiration from the work of Zapper and Beefy.
 * Implemented and modified by PancakeSwap teams.
 * Then modified for Thena by @CryptoCultCurt
 */

contract ThenaZap is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    // Interface for Wrapped BNB (WBNB)
    IWETH public WBNB;

    // PancakeRouter interface
    IPancakeRouter02 public pancakeRouter;

    // Maximum integer (used for managing allowance)
    uint256 public constant MAX_INT = 2 ** 256 - 1;

    // Minimum amount for a swap (derived from PancakeSwap)
    uint256 public constant MINIMUM_AMOUNT = 1000;

    // Maximum reverse zap ratio (100 --> 1%, 1000 --> 0.1%)
    uint256 public maxZapReverseRatio;

    // Address PancakeRouter
    address private pancakeRouterAddress;

    // Address Wrapped BNB (WBNB)
    address private WBNBAddress;

    // Owner recovers token
    event AdminTokenRecovery(
        address indexed tokenAddress,
        uint256 amountTokens
    );

    // Owner changes the maxZapReverseRatio
    event NewMaxZapReverseRatio(uint256 maxZapReverseRatio);

    // tokenToZap = 0x00 address if BNB
    event ZapIn(
        address indexed tokenToZap,
        address indexed lpToken,
        uint256 tokenAmountIn,
        uint256 lpTokenAmountReceived,
        address indexed user
    );

    // token0ToZap = 0x00 address if BNB
    event ZapInRebalancing(
        address indexed token0ToZap,
        address indexed token1ToZap,
        address lpToken,
        uint256 token0AmountIn,
        uint256 token1AmountIn,
        uint256 lpTokenAmountReceived,
        address indexed user
    );

    // tokenToReceive = 0x00 address if BNB
    event ZapOut(
        address indexed lpToken,
        address indexed tokenToReceive,
        uint256 lpTokenAmount,
        uint256 tokenAmountReceived,
        address indexed user
    );

    /*
     * @notice Fallback for WBNB
     */
    receive() external payable {
        assert(msg.sender == WBNBAddress);
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Restricted to admins"
        );
        _;
    }

    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(DEFAULT_ADMIN_ROLE)
    override
    {}

    function setWBNBAddress(address _WBNBAddress) external onlyAdmin {
        require(_WBNBAddress != address(0), "Zero address not allowed");
        WBNBAddress = _WBNBAddress;
        WBNB = IWETH(_WBNBAddress);
    }

    function setMaxZapReverseRatio(
        uint256 _maxZapReverseRatio
    ) external onlyAdmin {
        require(_maxZapReverseRatio != 0, "Zero not allowed");
        maxZapReverseRatio = _maxZapReverseRatio;
    }

    function setRouterAddress(address _router) external onlyAdmin {
        require(_router != address(0), "Zero address not allowed");
        pancakeRouterAddress = _router;
        pancakeRouter = IPancakeRouter02(_router);
    }

    /*
     * @notice Zap BNB in a WBNB pool (e.g. WBNB/token)
     * @param _lpToken: LP token address (e.g. CAKE/BNB)
     * @param _tokenAmountOutMin: minimum token amount (e.g. CAKE) to receive in the intermediary swap (e.g. BNB --> CAKE)
     */
    function zapInBNB(
        address _lpToken,
        uint256 _tokenAmountOutMin
    ) external payable {
        WBNB.deposit{value: msg.value}();

        // Call zap function
        uint256 lpTokenAmountTransferred = _zapIn(
            WBNBAddress,
            msg.value,
            _lpToken,
            _tokenAmountOutMin
        );

        // Emit event
        emit ZapIn(
            address(0x0000000000000000000000000000000000000000),
            _lpToken,
            msg.value,
            lpTokenAmountTransferred,
            msg.sender
        );
    }

    /*
     * @notice Zap a token in (e.g. token/other token)
     * @param _tokenToZap: token to zap
     * @param _tokenAmountIn: amount of token to swap
     * @param _lpToken: LP token address (e.g. CAKE/BUSD)
     * @param _tokenAmountOutMin: minimum token to receive (e.g. CAKE) in the intermediary swap (e.g. BUSD --> CAKE)
     */
    function zapInToken(
        address _tokenToZap,
        uint256 _tokenAmountIn,
        address _lpToken,
        uint256 _tokenAmountOutMin
    ) external {
        // Transfer tokens to this contract
        IERC20(_tokenToZap).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenAmountIn
        );

        // Call zap function
        uint256 lpTokenAmountTransferred = _zapIn(
            _tokenToZap,
            _tokenAmountIn,
            _lpToken,
            _tokenAmountOutMin
        );

        // Emit event
        emit ZapIn(
            _tokenToZap,
            _lpToken,
            _tokenAmountIn,
            lpTokenAmountTransferred,
            msg.sender
        );
    }

    /*
     * @notice Zap two tokens in, rebalance them to 50-50, before adding them to LP
     * @param _token0ToZap: address of token0 to zap
     * @param _token1ToZap: address of token1 to zap
     * @param _token0AmountIn: amount of token0 to zap
     * @param _token1AmountIn: amount of token1 to zap
     * @param _lpToken: LP token address (token0/token1)
     * @param _tokenAmountInMax: maximum token amount to sell (in token to sell in the intermediary swap)
     * @param _tokenAmountOutMin: minimum token to receive in the intermediary swap
     * @param _isToken0Sold: whether token0 is expected to be sold (if false, sell token1)
     */
    function zapInTokenRebalancing(
        address _token0ToZap,
        address _token1ToZap,
        uint256 _token0AmountIn,
        uint256 _token1AmountIn,
        address _lpToken,
        uint256 _tokenAmountInMax,
        uint256 _tokenAmountOutMin,
        bool _isToken0Sold
    ) external {
        // Transfer tokens to this contract
        IERC20(_token0ToZap).safeTransferFrom(
            msg.sender,
            address(this),
            _token0AmountIn
        );
        IERC20(_token1ToZap).safeTransferFrom(
            msg.sender,
            address(this),
            _token1AmountIn
        );

        // Call zapIn function
        uint256 lpTokenAmountTransferred = _zapInRebalancing(
            _token0ToZap,
            _token1ToZap,
            _token0AmountIn,
            _token1AmountIn,
            _lpToken,
            _tokenAmountInMax,
            _tokenAmountOutMin,
            _isToken0Sold
        );

        // Emit event
        emit ZapInRebalancing(
            _token0ToZap,
            _token1ToZap,
            _lpToken,
            _token0AmountIn,
            _token1AmountIn,
            lpTokenAmountTransferred,
            msg.sender
        );
    }

    /*
     * @notice Zap 1 token and BNB, rebalance them to 50-50, before adding them to LP
     * @param _token1ToZap: address of token1 to zap
     * @param _token1AmountIn: amount of token1 to zap
     * @param _lpToken: LP token address
     * @param _tokenAmountInMax: maximum token amount to sell (in token to sell in the intermediary swap)
     * @param _tokenAmountOutMin: minimum token to receive in the intermediary swap
     * @param _isToken0Sold: whether token0 is expected to be sold (if false, sell token1)
     */
    function zapInBNBRebalancing(
        address _token1ToZap,
        uint256 _token1AmountIn,
        address _lpToken,
        uint256 _tokenAmountInMax,
        uint256 _tokenAmountOutMin,
        bool _isToken0Sold
    ) external payable {
        WBNB.deposit{value: msg.value}();

        IERC20(_token1ToZap).safeTransferFrom(
            msg.sender,
            address(this),
            _token1AmountIn
        );

        // Call zapIn function
        uint256 lpTokenAmountTransferred = _zapInRebalancing(
            WBNBAddress,
            _token1ToZap,
            msg.value,
            _token1AmountIn,
            _lpToken,
            _tokenAmountInMax,
            _tokenAmountOutMin,
            _isToken0Sold
        );

        // Emit event
        emit ZapInRebalancing(
            address(0x0000000000000000000000000000000000000000),
            _token1ToZap,
            _lpToken,
            msg.value,
            _token1AmountIn,
            lpTokenAmountTransferred,
            msg.sender
        );
    }

    /*
     * @notice Zap a LP token out to receive BNB
     * @param _lpToken: LP token address (e.g. CAKE/WBNB)
     * @param _lpTokenAmount: amount of LP tokens to zap out
     * @param _tokenAmountOutMin: minimum amount to receive (in BNB/WBNB) in the intermediary swap (e.g. CAKE --> BNB)
     */
    function zapOutBNB(
        address _lpToken,
        uint256 _lpTokenAmount,
        uint256 _tokenAmountOutMin,
        uint256 _totalTokenAmountOutMin
    ) external {
        // Transfer LP token to this address
        IERC20(_lpToken).safeTransferFrom(
            msg.sender,
            address(_lpToken),
            _lpTokenAmount
        );

        // Call zapOut
        uint256 tokenAmountToTransfer = _zapOut(
            _lpToken,
            WBNBAddress,
            _tokenAmountOutMin,
            _totalTokenAmountOutMin
        );

        // Unwrap BNB
        WBNB.withdraw(tokenAmountToTransfer);

        // Transfer BNB to the msg.sender
        (bool success, ) = msg.sender.call{value: tokenAmountToTransfer}(
            new bytes(0)
        );
        require(success, "BNB: transfer fail");

        // Emit event
        emit ZapOut(
            _lpToken,
            address(0x0000000000000000000000000000000000000000),
            _lpTokenAmount,
            tokenAmountToTransfer,
            msg.sender
        );
    }

    /*
     * @notice Zap a LP token out (to receive a token)
     * @param _lpToken: LP token address (e.g. CAKE/BUSD)
     * @param _tokenToReceive: one of the 2 tokens from the LP (e.g. CAKE or BUSD)
     * @param _lpTokenAmount: amount of LP tokens to zap out
     * @param _tokenAmountOutMin: minimum token to receive (e.g. CAKE) in the intermediary swap (e.g. BUSD --> CAKE)
     */
    function zapOutToken(
        address _lpToken,
        address _tokenToReceive,
        uint256 _lpTokenAmount,
        uint256 _tokenAmountOutMin,
        uint256 _totalTokenAmountOutMin
    ) external {
        // Transfer LP token to this address
        IERC20(_lpToken).safeTransferFrom(
            msg.sender,
            address(_lpToken),
            _lpTokenAmount
        );

        uint256 tokenAmountToTransfer = _zapOut(
            _lpToken,
            _tokenToReceive,
            _tokenAmountOutMin,
            _totalTokenAmountOutMin
        );

        IERC20(_tokenToReceive).safeTransfer(msg.sender, tokenAmountToTransfer);

        emit ZapOut(
            _lpToken,
            _tokenToReceive,
            _lpTokenAmount,
            tokenAmountToTransfer,
            msg.sender
        );
    }

    /**
     * @notice It allows the owner to change the risk parameter for quantities
     * @param _maxZapInverseRatio: new inverse ratio
     * @dev This function is only callable by owner.
     */
    function updateMaxZapInverseRatio(
        uint256 _maxZapInverseRatio
    ) external onlyAdmin {
        maxZapReverseRatio = _maxZapInverseRatio;
        emit NewMaxZapReverseRatio(_maxZapInverseRatio);
    }

    /**
     * @notice It allows the owner to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw (18 decimals)
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev This function is only callable by owner.
     */
    function recoverWrongTokens(
        address _tokenAddress,
        uint256 _tokenAmount
    ) external onlyAdmin {
        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /*
     * @notice View the details for single zap
     * @dev Use WBNB for _tokenToZap (if BNB is the input)
     * @param _tokenToZap: address of the token to zap
     * @param _tokenAmountIn: amount of token to zap inputed
     * @param _lpToken: address of the LP token
     * @return swapAmountIn: amount that is expected to get swapped in intermediary swap
     * @return swapAmountOut: amount that is expected to get received in intermediary swap
     * @return swapTokenOut: token address of the token that is used in the intermediary swap
     */
    function estimateZapInSwap(
        address _tokenToZap,
        uint256 _tokenAmountIn,
        address _lpToken
    )
        external
        view
        returns (
            uint256 swapAmountIn,
            uint256 swapAmountOut,
            address swapTokenOut
        )
    {
        console.log('estimatezapinswap');
        address token0 = IPancakePair(_lpToken).token0();
        address token1 = IPancakePair(_lpToken).token1();
        console.log(token0);
        console.log(token1);



        require(
            _tokenToZap == token0 || _tokenToZap == token1,
            "Zap: Wrong tokens"
        );

        // Convert to uint256 (from uint112)
        (uint256 reserveA, uint256 reserveB, ) = IPancakePair(_lpToken)
            .getReserves();

        console.log('reserves');
        console.log(reserveA);
        console.log(reserveB);
        console.log('token to zap');
        console.log(_tokenToZap);

        if (token0 == _tokenToZap) {
            swapTokenOut = token1;
            swapAmountIn = _calculateAmountToSwap(
                _tokenAmountIn,
                reserveA,
                reserveB
            );
            console.log(swapAmountIn);
            swapAmountOut = pancakeRouter.getAmountOut(
                swapAmountIn,
                reserveA,
                reserveB
            );
            console.log(swapAmountOut);
        } else {
            swapTokenOut = token0;
            swapAmountIn = _calculateAmountToSwap(
                _tokenAmountIn,
                reserveB,
                reserveA
            );
            console.log(swapAmountIn);
            swapAmountOut = pancakeRouter.getAmountOut(
                swapAmountIn,
                reserveB,
                reserveA
            );
             console.log(swapAmountOut);
        }

        return (swapAmountIn, swapAmountOut, swapTokenOut);
    }

    /*
     * @notice View the details for a rebalancing zap
     * @dev Use WBNB for _token0ToZap (if BNB is the input)
     * @param _token0ToZap: address of the token0 to zap
     * @param _token1ToZap: address of the token0 to zap
     * @param _token0AmountIn: amount for token0 to zap
     * @param _token1AmountIn: amount for token1 to zap
     * @param _lpToken: address of the LP token
     * @return swapAmountIn: amount that is expected to get swapped in intermediary swap
     * @return swapAmountOut: amount that is expected to get received in intermediary swap
     * @return isToken0Sold: whether the token0 is sold (false --> token1 is sold in the intermediary swap)
     */
    function estimateZapInRebalancingSwap(
        address _token0ToZap,
        address _token1ToZap,
        uint256 _token0AmountIn,
        uint256 _token1AmountIn,
        address _lpToken
    )
        external
        view
        returns (uint256 swapAmountIn, uint256 swapAmountOut, bool sellToken0)
    {
        require(
            _token0ToZap == IPancakePair(_lpToken).token0() ||
                _token0ToZap == IPancakePair(_lpToken).token1(),
            "Zap: Wrong token0"
        );
        require(
            _token1ToZap == IPancakePair(_lpToken).token0() ||
                _token1ToZap == IPancakePair(_lpToken).token1(),
            "Zap: Wrong token1"
        );

        require(_token0ToZap != _token1ToZap, "Zap: Same tokens");

        // Convert to uint256 (from uint112)
        (uint256 reserveA, uint256 reserveB, ) = IPancakePair(_lpToken)
            .getReserves();

        if (_token0ToZap == IPancakePair(_lpToken).token0()) {
            sellToken0 = (_token0AmountIn * reserveB >
                _token1AmountIn * reserveA)
                ? true
                : false;

            // Calculate the amount that is expected to be swapped
            swapAmountIn = _calculateAmountToSwapForRebalancing(
                _token0AmountIn,
                _token1AmountIn,
                reserveA,
                reserveB,
                sellToken0
            );

            // Calculate the amount expected to be received in the intermediary swap
            if (sellToken0) {
                swapAmountOut = pancakeRouter.getAmountOut(
                    swapAmountIn,
                    reserveA,
                    reserveB
                );
            } else {
                swapAmountOut = pancakeRouter.getAmountOut(
                    swapAmountIn,
                    reserveB,
                    reserveA
                );
            }
        } else {
            sellToken0 = (_token0AmountIn * reserveA >
                _token1AmountIn * reserveB)
                ? true
                : false;
            // Calculate the amount that is expected to be swapped
            swapAmountIn = _calculateAmountToSwapForRebalancing(
                _token0AmountIn,
                _token1AmountIn,
                reserveB,
                reserveA,
                sellToken0
            );

            // Calculate the amount expected to be received in the intermediary swap
            if (sellToken0) {
                swapAmountOut = pancakeRouter.getAmountOut(
                    swapAmountIn,
                    reserveB,
                    reserveA
                );
            } else {
                swapAmountOut = pancakeRouter.getAmountOut(
                    swapAmountIn,
                    reserveA,
                    reserveB
                );
            }
        }

        return (swapAmountIn, swapAmountOut, sellToken0);
    }

    /*
     * @notice View the details for single zap
     * @dev Use WBNB for _tokenToReceive (if BNB is the asset to be received)
     * @param _lpToken: address of the LP token to zap out
     * @param _lpTokenAmount: amount of LP token to zap out
     * @param _tokenToReceive: token address to receive
     * @return swapAmountIn: amount that is expected to get swapped for intermediary swap
     * @return swapAmountOut: amount that is expected to get received for intermediary swap
     * @return swapTokenOut: address of the token that is sold in the intermediary swap
     */
    function estimateZapOutSwap(
        address _lpToken,
        uint256 _lpTokenAmount,
        address _tokenToReceive
    )
        external
        view
        returns (
            uint256 swapAmountIn,
            uint256 swapAmountOut,
            address swapTokenOut
        )
    {
        address token0 = IPancakePair(_lpToken).token0();
        address token1 = IPancakePair(_lpToken).token1();

        require(
            _tokenToReceive == token0 || _tokenToReceive == token1,
            "Zap: Token not in LP"
        );

        // Convert to uint256 (from uint112)
        (uint256 reserveA, uint256 reserveB, ) = IPancakePair(_lpToken)
            .getReserves();

        if (token1 == _tokenToReceive) {
            // sell token0
            uint256 tokenAmountIn = (_lpTokenAmount * reserveA) /
                IPancakePair(_lpToken).totalSupply();

            swapAmountIn = tokenAmountIn;
            swapAmountOut = pancakeRouter.getAmountOut(
                swapAmountIn,
                reserveA,
                reserveB
            );

            swapTokenOut = token0;
        } else {
            // sell token1
            uint256 tokenAmountIn = (_lpTokenAmount * reserveB) /
                IPancakePair(_lpToken).totalSupply();

            swapAmountIn = tokenAmountIn;
            swapAmountOut = pancakeRouter.getAmountOut(
                swapAmountIn,
                reserveB,
                reserveA
            );

            swapTokenOut = token1;
        }

        return (swapAmountIn, swapAmountOut, swapTokenOut);
    }

    /*
     * @notice Zap a token in (e.g. token/other token)
     * @param _tokenToZap: token to zap
     * @param _tokenAmountIn: amount of token to swap
     * @param _lpToken: LP token address
     * @param _tokenAmountOutMin: minimum token to receive in the intermediary swap
     */
    function _zapIn(
        address _tokenToZap,
        uint256 _tokenAmountIn,
        address _lpToken,
        uint256 _tokenAmountOutMin
    ) internal returns (uint256 lpTokenReceived) {
        require(_tokenAmountIn >= MINIMUM_AMOUNT, "Zap: Amount too low");

        address token0 = IPancakePair(_lpToken).token0();
        address token1 = IPancakePair(_lpToken).token1();

        require(
            _tokenToZap == token0 || _tokenToZap == token1,
            "Zap: Wrong tokens"
        );

        // Retrieve the path
        address[] memory path = new address[](2);
        path[0] = _tokenToZap;

        // Initiates an estimation to swap
        uint256 swapAmountIn;

        {
            // Convert to uint256 (from uint112)
            (uint256 reserveA, uint256 reserveB, ) = IPancakePair(_lpToken)
                .getReserves();

            require(
                (reserveA >= MINIMUM_AMOUNT) && (reserveB >= MINIMUM_AMOUNT),
                "Zap: Reserves too low"
            );

            if (token0 == _tokenToZap) {
                swapAmountIn = _calculateAmountToSwap(
                    _tokenAmountIn,
                    reserveA,
                    reserveB
                );
                path[1] = token1;
                require(
                    reserveA / swapAmountIn >= maxZapReverseRatio,
                    "Zap: Quantity higher than limit"
                );
            } else {
                swapAmountIn = _calculateAmountToSwap(
                    _tokenAmountIn,
                    reserveB,
                    reserveA
                );
                path[1] = token0;
                require(
                    reserveB / swapAmountIn >= maxZapReverseRatio,
                    "Zap: Quantity higher than limit"
                );
            }
        }

        // Approve token to zap if necessary
        _approveTokenIfNeeded(_tokenToZap, swapAmountIn);

        uint256[] memory swapedAmounts = pancakeRouter.swapExactTokensForTokens(
            swapAmountIn,
            _tokenAmountOutMin,
            path,
            address(this),
            block.timestamp
        );

        // Approve other token if necessary
        if (token0 == _tokenToZap) {
            _approveTokenIfNeeded(token1, swapAmountIn);
        } else {
            _approveTokenIfNeeded(token0, swapAmountIn);
        }

        // Add liquidity and retrieve the amount of LP received by the sender
        (, , lpTokenReceived) = pancakeRouter.addLiquidity(
            path[0],
            path[1],
            _tokenAmountIn - swapedAmounts[0],
            swapedAmounts[1],
            1,
            1,
            msg.sender,
            block.timestamp
        );

        return lpTokenReceived;
    }

    /*
     * @notice Zap two tokens in, rebalance them to 50-50, before adding them to LP
     * @param _token0ToZap: address of token0 to zap
     * @param _token1ToZap: address of token1 to zap
     * @param _token0AmountIn: amount of token0 to zap
     * @param _token1AmountIn: amount of token1 to zap
     * @param _lpToken: LP token address
     * @param _tokenAmountInMax: maximum token amount to sell (in token to sell in the intermediary swap)
     * @param _tokenAmountOutMin: minimum token to receive in the intermediary swap
     * @param _isToken0Sold: whether token0 is expected to be sold (if false, sell token1)
     */
    function _zapInRebalancing(
        address _token0ToZap,
        address _token1ToZap,
        uint256 _token0AmountIn,
        uint256 _token1AmountIn,
        address _lpToken,
        uint256 _tokenAmountInMax,
        uint256 _tokenAmountOutMin,
        bool _isToken0Sold
    ) internal returns (uint256 lpTokenReceived) {
        require(
            _token0ToZap == IPancakePair(_lpToken).token0() ||
                _token0ToZap == IPancakePair(_lpToken).token1(),
            "Zap: Wrong token0"
        );
        require(
            _token1ToZap == IPancakePair(_lpToken).token0() ||
                _token1ToZap == IPancakePair(_lpToken).token1(),
            "Zap: Wrong token1"
        );

        require(_token0ToZap != _token1ToZap, "Zap: Same tokens");

        // Initiates an estimation to swap
        uint256 swapAmountIn;

        {
            // Convert to uint256 (from uint112)
            (uint256 reserveA, uint256 reserveB, ) = IPancakePair(_lpToken)
                .getReserves();

            require(
                (reserveA >= MINIMUM_AMOUNT) && (reserveB >= MINIMUM_AMOUNT),
                "Zap: Reserves too low"
            );

            if (_token0ToZap == IPancakePair(_lpToken).token0()) {
                swapAmountIn = _calculateAmountToSwapForRebalancing(
                    _token0AmountIn,
                    _token1AmountIn,
                    reserveA,
                    reserveB,
                    _isToken0Sold
                );
                require(
                    reserveA / swapAmountIn >= maxZapReverseRatio,
                    "Zap: Quantity higher than limit"
                );
            } else {
                swapAmountIn = _calculateAmountToSwapForRebalancing(
                    _token0AmountIn,
                    _token1AmountIn,
                    reserveB,
                    reserveA,
                    _isToken0Sold
                );

                require(
                    reserveB / swapAmountIn >= maxZapReverseRatio,
                    "Zap: Quantity higher than limit"
                );
            }
        }

        require(
            swapAmountIn <= _tokenAmountInMax,
            "Zap: Amount to swap too high"
        );

        address[] memory path = new address[](2);

        // Define path for swapping and check whether to approve token to sell in intermediary swap
        if (_isToken0Sold) {
            path[0] = _token0ToZap;
            path[1] = _token1ToZap;
            _approveTokenIfNeeded(_token0ToZap, swapAmountIn);
        } else {
            path[0] = _token1ToZap;
            path[1] = _token0ToZap;
            _approveTokenIfNeeded(_token1ToZap, swapAmountIn);
        }

        // Execute the swap and retrieve quantity received
        uint256[] memory swapedAmounts = pancakeRouter.swapExactTokensForTokens(
            swapAmountIn,
            _tokenAmountOutMin,
            path,
            address(this),
            block.timestamp
        );

        // Check whether to approve other token and add liquidity to LP
        if (_isToken0Sold) {
            _approveTokenIfNeeded(_token1ToZap, swapAmountIn);

            (, , lpTokenReceived) = pancakeRouter.addLiquidity(
                path[0],
                path[1],
                (_token0AmountIn - swapedAmounts[0]),
                (_token1AmountIn + swapedAmounts[1]),
                1,
                1,
                msg.sender,
                block.timestamp
            );
        } else {
            _approveTokenIfNeeded(_token0ToZap, swapAmountIn);
            (, , lpTokenReceived) = pancakeRouter.addLiquidity(
                path[0],
                path[1],
                (_token1AmountIn - swapedAmounts[0]),
                (_token0AmountIn + swapedAmounts[1]),
                1,
                1,
                msg.sender,
                block.timestamp
            );
        }

        return lpTokenReceived;
    }

    /*
     * @notice Zap a LP token out to a token (e.g. token/other token)
     * @param _lpToken: LP token address
     * @param _tokenToReceive: token address
     * @param _tokenAmountOutMin: minimum token to receive in the intermediary swap
     */
    function _zapOut(
        address _lpToken,
        address _tokenToReceive,
        uint256 _tokenAmountOutMin,
        uint256 _totalTokenAmountOutMin
    ) internal returns (uint256) {
        address token0 = IPancakePair(_lpToken).token0();
        address token1 = IPancakePair(_lpToken).token1();

        require(
            _tokenToReceive == token0 || _tokenToReceive == token1,
            "Zap: Token not in LP"
        );

        // Burn all LP tokens to receive the two tokens to this address
        (uint256 amount0, uint256 amount1) = IPancakePair(_lpToken).burn(
            address(this)
        );

        require(
            amount0 >= MINIMUM_AMOUNT,
            "PancakeRouter: INSUFFICIENT_A_AMOUNT"
        );
        require(
            amount1 >= MINIMUM_AMOUNT,
            "PancakeRouter: INSUFFICIENT_B_AMOUNT"
        );

        address[] memory path = new address[](2);
        path[1] = _tokenToReceive;

        uint256 swapAmountIn;

        if (token0 == _tokenToReceive) {
            path[0] = token1;
            swapAmountIn = IERC20(token1).balanceOf(address(this));

            // Approve token to sell if necessary
            _approveTokenIfNeeded(token1, swapAmountIn);
        } else {
            path[0] = token0;
            swapAmountIn = IERC20(token0).balanceOf(address(this));

            // Approve token to sell if necessary
            _approveTokenIfNeeded(token0, swapAmountIn);
        }

        // Swap tokens
        pancakeRouter.swapExactTokensForTokens(
            swapAmountIn,
            _tokenAmountOutMin,
            path,
            address(this),
            block.timestamp
        );

        // Return full balance for the token to receive by the sender
        require(
            _totalTokenAmountOutMin <
                IERC20(_tokenToReceive).balanceOf(address(this)),
            "amount is not enough"
        );
        return IERC20(_tokenToReceive).balanceOf(address(this));
    }

    /*
     * @notice Allows to zap a token in (e.g. token/other token)
     * @param _token: token address
     */
    function _approveTokenIfNeeded(
        address _token,
        uint256 _swapAmountIn
    ) private {
        if (
            IERC20(_token).allowance(address(this), pancakeRouterAddress) <
            _swapAmountIn
        ) {
            // Reset to 0
            IERC20(_token).safeApprove(pancakeRouterAddress, 0);
            // Re-approve
            IERC20(_token).safeApprove(pancakeRouterAddress, MAX_INT);
        }
    }

    /*
     * @notice Calculate the swap amount to get the price at 50/50 split
     * @param _token0AmountIn: amount of token 0
     * @param _reserve0: amount in reserve for token0
     * @param _reserve1: amount in reserve for token1
     * @return amountToSwap: swapped amount (in token0)
     */
    function _calculateAmountToSwap(
        uint256 _token0AmountIn,
        uint256 _reserve0,
        uint256 _reserve1
    ) private view returns (uint256 amountToSwap) {
        console.log('_calculateAmountToSwap');
        uint256 halfToken0Amount = _token0AmountIn / 2;
        console.log('halfTokenAmount');
        console.log(halfToken0Amount);
        uint256 nominator = pancakeRouter.getAmountOut(
            halfToken0Amount,
            _reserve0,
            _reserve1
        );
        console.log('nominator');
        console.log(nominator);
        uint256 denominator = pancakeRouter.quote(
            halfToken0Amount,
            _reserve0 + halfToken0Amount,
            _reserve1 - nominator
        );

        // Adjustment for price impact
        amountToSwap =
            _token0AmountIn -
            Babylonian.sqrt(
                (halfToken0Amount * halfToken0Amount * nominator) / denominator
            );

        return amountToSwap;
    }

    /*
     * @notice Calculate the amount to swap to get the tokens at a 50/50 split
     * @param _token0AmountIn: amount of token 0
     * @param _token1AmountIn: amount of token 1
     * @param _reserve0: amount in reserve for token0
     * @param _reserve1: amount in reserve for token1
     * @param _isToken0Sold: whether token0 is expected to be sold (if false, sell token1)
     * @return amountToSwap: swapped amount in token0 (if _isToken0Sold is true) or token1 (if _isToken0Sold is false)
     */
    function _calculateAmountToSwapForRebalancing(
        uint256 _token0AmountIn,
        uint256 _token1AmountIn,
        uint256 _reserve0,
        uint256 _reserve1,
        bool _isToken0Sold
    ) private view returns (uint256 amountToSwap) {
        bool sellToken0 = (_token0AmountIn * _reserve1 >
            _token1AmountIn * _reserve0)
            ? true
            : false;

        require(sellToken0 == _isToken0Sold, "Zap: Wrong trade direction");

        if (sellToken0) {
            uint256 token0AmountToSell = (_token0AmountIn -
                (_token1AmountIn * _reserve0) /
                _reserve1) / 2;
            uint256 nominator = pancakeRouter.getAmountOut(
                token0AmountToSell,
                _reserve0,
                _reserve1
            );
            uint256 denominator = pancakeRouter.quote(
                token0AmountToSell,
                _reserve0 + token0AmountToSell,
                _reserve1 - nominator
            );

            // Calculate the amount to sell (in token0)
            token0AmountToSell =
                (_token0AmountIn -
                    (_token1AmountIn * (_reserve0 + token0AmountToSell)) /
                    (_reserve1 - nominator)) /
                2;

            // Adjustment for price impact
            amountToSwap =
                2 *
                token0AmountToSell -
                Babylonian.sqrt(
                    (token0AmountToSell * token0AmountToSell * nominator) /
                        denominator
                );
        } else {
            uint256 token1AmountToSell = (_token1AmountIn -
                (_token0AmountIn * _reserve1) /
                _reserve0) / 2;
            uint256 nominator = pancakeRouter.getAmountOut(
                token1AmountToSell,
                _reserve1,
                _reserve0
            );

            uint256 denominator = pancakeRouter.quote(
                token1AmountToSell,
                _reserve1 + token1AmountToSell,
                _reserve0 - nominator
            );

            // Calculate the amount to sell (in token1)
            token1AmountToSell =
                (_token1AmountIn -
                    ((_token0AmountIn * (_reserve1 + token1AmountToSell)) /
                        (_reserve0 - nominator))) /
                2;

            // Adjustment for price impact
            amountToSwap =
                2 *
                token1AmountToSell -
                Babylonian.sqrt(
                    (token1AmountToSell * token1AmountToSell * nominator) /
                        denominator
                );
        }

        return amountToSwap;
    }
}

library Babylonian {
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;

        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;

        uint256 r1 = x / r;

        return (r < r1 ? r : r1);
    }
}
