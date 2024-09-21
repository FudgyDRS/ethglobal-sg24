// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";

import {BaseHook} from "./BaseHook.sol";

/**
 * @title An interface for checking whether an address has a valid kycNFT token
 */
interface IKycValidity {
    /// @dev Check whether a given address has a valid kycNFT token
    /// @param _addr Address to check for tokens
    /// @return valid Whether the address has a valid token
    function hasValidToken(address _addr) external view returns (bool valid);
}

/**
 * Execute small function calls
 */
contract CronHook is BaseHook, Ownable {
    IKycValidity public kycValidity;
    address private _preKycValidity;
    uint256 private _setKycValidityReqTimestamp;

    struct cronJob {
      address target;
      bytes4 selector;
      uint256 gasCost;
      bytes32 payload;
      uint256 timestamp;
    }

    mapping(uint256 => cronJob) cronJobs;
    uint256 nonce;
    uint256 currentJob;
    uint256 jobsLeft;
    uint256 maxJobs = 100;
    uint256 maxCronGas = 50000;

    function setCronGas(uint256 value) external onlyOwner {
      maxCronGas = value;
    }

    function setMaxJobs(uint256 value) external onlyOwner {
      maxJobs = value;
    }

    constructor(
        IPoolManager _poolManager
    ) BaseHook(_poolManager) {
    }

    modifier canPost(uint256 gas) {
        require(
            jobsLeft < maxJobs,
            "max number of cron jobs has been reached"
        );
        require(
            gas <= maxCronGas,
            "cron job exceeds gas limit"
        );
        _;
    }

    function addCronJob(address to, bytes4 selector, uint256 gasCost, bytes32 payload) canPost(gasCost) external {
      cronJobs[nonce++] = cronJob(to, selector, gasCost, payload);
      jobsLeft++;
    }

    /// Sorta timelock
    function setKycValidity(address _kycValidity) external onlyOwner {
        if (
            block.timestamp - _setKycValidityReqTimestamp >= 7 days &&
            _kycValidity == _preKycValidity
        ) {
            kycValidity = IKycValidity(_kycValidity);
        } else {
            _preKycValidity = _kycValidity;
            _setKycValidityReqTimestamp = block.timestamp;
        }
    }

    function getHooksCalls() public pure override returns (Hooks.Permissions memory) {
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeModifyPosition: true,
                afterModifyPosition: false,
                beforeSwap: false,
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false
            });
    }

    function afterSwap(
        address,
        IPoolManager.PoolKey calldata,
        IPoolManager.SwapParams calldata
    ) external view override poolManagerOnly returns (bytes4) {
      bytes memory cron = cronJobs[currentJob++];
      payable(cron.target).call{value: 0, gas: cron.gasCost}(abi.encodeWithSelector(cron.selector, cron.payload));
      jobsLeft--;
        return BaseHook.AfterSwap.selector;
    }
}