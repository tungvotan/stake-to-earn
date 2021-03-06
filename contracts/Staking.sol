// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.4 <0.9.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract DuelistKingStaking {
  using SafeERC20 for ERC20;
  using Address for address;

  /**
   * numberOfLockDays is a number of days that
   * user must be stake before unstaking without penalty
   */
  struct StakingCampaign {
    uint64 startDate;
    uint64 endDate;
    uint128 returnRate;
    uint256 maxAmountOfToken;
    uint256 stakedAmountOfToken;
    uint256 limitStakingAmountForUser;
    address tokenAddress;
    uint256 maxNumberOfBoxes;
    uint256 rewardPhaseBoxId;
    uint64 numberOfLockDays;
  }

  struct UserStakingSlot {
    uint256 stakingAmountOfToken;
    uint256 stakedAmountOfBoxes;
    uint64 startStakingDate;
    uint64 lastStakingDate;
  }

  address private _owner;
  uint256 private totalCampaign;
  uint32 constant transferRate = 1000000;

  mapping(uint256 => StakingCampaign) private _campaignStorage;

  mapping(uint256 => mapping(address => UserStakingSlot))
    private _userStakingSlot;

  // New created campaign event
  event NewCampaign(
    uint64 indexed startDate,
    uint64 indexed endDate,
    uint64 numberOfLockDays,
    uint256 maxAmountOfToken,
    uint256 maxNumberOfBoxes,
    address indexed tokenAddress
  );

  // Staking event
  event Staking(
    address indexed owner,
    uint256 indexed amount,
    uint256 indexed startStakingDate
  );

  // Unstaking event
  event Unstaking(
    address indexed owner,
    uint256 indexed amount,
    uint256 indexed unStakeTime
  );

  // Issue box to user evnt
  event IssueBoxes(
    address indexed owner,
    uint256 indexed rewardPhaseBoxId,
    uint256 indexed numberOfBoxes
  );

  function createNewStakingCampaign(StakingCampaign memory _newCampaign)
    external
  {
    require(
      _newCampaign.startDate > block.timestamp &&
        _newCampaign.endDate > _newCampaign.startDate,
      "StakingContract: Invalid timeline format"
    );
    uint64 duration = (_newCampaign.endDate - _newCampaign.startDate) /
      (1 days);
    require(duration >= 1, "StakingContract: Duration must be at least 1 day");
    require(
      _newCampaign.numberOfLockDays <= duration,
      "StakingContract: Number of lock days should be less than duration event days"
    );
    require(_newCampaign.rewardPhaseBoxId >= 1, "Invalid phase id");
    require(
      _newCampaign.tokenAddress.isContract(),
      "StakingContract: Token address is not a smart contract"
    );

    _newCampaign.returnRate = uint128(
      (_newCampaign.maxNumberOfBoxes * transferRate) /
        (_newCampaign.maxAmountOfToken * duration)
    );
    _campaignStorage[totalCampaign] = _newCampaign;
    totalCampaign += 1;
    emit NewCampaign(
      _newCampaign.startDate,
      _newCampaign.endDate,
      _newCampaign.numberOfLockDays,
      _newCampaign.maxAmountOfToken,
      _newCampaign.maxNumberOfBoxes,
      _newCampaign.tokenAddress
    );
  }

  function calculatePendingBoxes(
    UserStakingSlot memory userStakingSlot,
    StakingCampaign memory campaign
  ) private view returns (uint256) {
    uint64 currentTimestamp = uint64(block.timestamp) > campaign.endDate
      ? campaign.endDate
      : uint64(block.timestamp);
    return (((userStakingSlot.stakingAmountOfToken *
      (currentTimestamp - userStakingSlot.lastStakingDate)) / (1 days)) *
      campaign.returnRate);
  }

  function getCurrentUserReward(uint256 _campaignId)
    private
    view
    returns (uint256)
  {
    StakingCampaign memory _currentCampaign = _campaignStorage[_campaignId];
    UserStakingSlot memory currentUserStakingSlot = _userStakingSlot[
      _campaignId
    ][msg.sender];
    return
      currentUserStakingSlot.stakedAmountOfBoxes +
      calculatePendingBoxes(currentUserStakingSlot, _currentCampaign);
  }

  function viewUserReward(uint256 _campaignId) public view returns (uint256) {
    return getCurrentUserReward(_campaignId) / transferRate;
  }

  function getCurrentUserStakingAmount(uint256 _campaignId)
    public
    view
    returns (uint256)
  {
    return _userStakingSlot[_campaignId][msg.sender].stakingAmountOfToken;
  }

  function staking(uint256 _campaignId, uint256 _amountOfToken)
    external
    returns (bool)
  {
    StakingCampaign memory _currentCampaign = _campaignStorage[_campaignId];
    UserStakingSlot memory currentUserStakingSlot = _userStakingSlot[
      _campaignId
    ][msg.sender];
    ERC20 currentToken = ERC20(_currentCampaign.tokenAddress);

    require(
      block.timestamp >= _currentCampaign.startDate,
      "StakingContract: This staking event has not yet starting"
    );
    require(
      block.timestamp < _currentCampaign.endDate,
      "StakingContract: This staking event has been expired"
    );
    require(
      currentUserStakingSlot.stakingAmountOfToken + _amountOfToken <=
        _currentCampaign.limitStakingAmountForUser,
      "StakingContract: Token limit per user exceeded"
    );

    if (currentUserStakingSlot.stakingAmountOfToken == 0) {
      currentUserStakingSlot.startStakingDate = uint64(block.timestamp);
      currentUserStakingSlot.lastStakingDate = uint64(block.timestamp);
    }

    require(
      currentToken.balanceOf(msg.sender) >= _amountOfToken,
      "StakingContract: Insufficient balance"
    );

    uint256 beforeBalance = currentToken.balanceOf(address(this));
    currentToken.safeTransferFrom(msg.sender, address(this), _amountOfToken);
    uint256 afterBalance = currentToken.balanceOf(address(this));
    require(
      afterBalance - beforeBalance == _amountOfToken,
      "StakingContract: Invalid token transfer"
    );

    _currentCampaign.stakedAmountOfToken += _amountOfToken;
    require(
      _currentCampaign.stakedAmountOfToken <= _currentCampaign.maxAmountOfToken,
      "StakingContract: Token limit exceeded"
    );
    _campaignStorage[_campaignId] = _currentCampaign;

    currentUserStakingSlot.stakedAmountOfBoxes += calculatePendingBoxes(
      currentUserStakingSlot,
      _currentCampaign
    );
    currentUserStakingSlot.lastStakingDate = uint64(block.timestamp);
    currentUserStakingSlot.stakingAmountOfToken += _amountOfToken;

    _userStakingSlot[_campaignId][msg.sender] = currentUserStakingSlot;
    emit Staking(msg.sender, _amountOfToken, block.timestamp);
    return true;
  }

  function issueBoxes(
    address owner,
    uint256 rewardPhaseBoxId,
    uint256 numberOfBoxes
  ) private {
    emit IssueBoxes(owner, rewardPhaseBoxId, numberOfBoxes);
  }

  function claimBoxes(uint256 _campaignId, uint256 _noBoxes)
    external
    returns (bool)
  {
    UserStakingSlot memory currentUserStakingSlot = _userStakingSlot[
      _campaignId
    ][msg.sender];
    StakingCampaign memory _currentCampaign = _campaignStorage[_campaignId];
    require(_noBoxes >= 1, "StakingContract: Minimum 1 box");
    // Validate number of boxes to be claimed
    uint256 currentReward = getCurrentUserReward(_campaignId);
    require(
      _noBoxes <= currentReward / transferRate,
      "StakingContract: Insufficient boxes"
    );

    // Validate claim duration
    require(
      block.timestamp >=
        currentUserStakingSlot.startStakingDate +
          (_currentCampaign.numberOfLockDays * (1 days)) ||
        block.timestamp >= _currentCampaign.endDate,
      "StakingContract: Unable to claim boxes before locked time"
    );

    // Issue box
    issueBoxes(msg.sender, _currentCampaign.rewardPhaseBoxId, _noBoxes);

    // Update user data
    currentUserStakingSlot.stakedAmountOfBoxes =
      currentReward -
      _noBoxes *
      transferRate;
    currentUserStakingSlot.lastStakingDate = uint64(block.timestamp);
    _userStakingSlot[_campaignId][msg.sender] = currentUserStakingSlot;
    return true;
  }

  function unStaking(uint256 _campaignId) external returns (bool) {
    UserStakingSlot memory currentUserStakingSlot = _userStakingSlot[
      _campaignId
    ][msg.sender];
    StakingCampaign memory _currentCampaign = _campaignStorage[_campaignId];
    ERC20 currentToken = ERC20(_currentCampaign.tokenAddress);

    require(
      currentUserStakingSlot.stakingAmountOfToken > 0,
      "StakingContract: No token to be unstaked"
    );

    // User unstake before lockTime and in duration event
    // will be paid for penalty fee and no reward box
    uint64 currentTimestamp = uint64(block.timestamp) > _currentCampaign.endDate
      ? _currentCampaign.endDate
      : uint64(block.timestamp);
    uint64 stakingDuration = (currentTimestamp -
      currentUserStakingSlot.startStakingDate) / (1 days);
    // TODO: refactor the logic here, should follow the clean orders
    if (
      stakingDuration < _currentCampaign.numberOfLockDays &&
      block.timestamp <= _currentCampaign.endDate
    ) {
      uint256 penaltyAmount = (currentUserStakingSlot.stakingAmountOfToken *
        2) / 100;
      currentToken.safeTransfer(
        msg.sender,
        currentUserStakingSlot.stakingAmountOfToken - penaltyAmount
      );
      // remove user staking amount from the pool
      _currentCampaign.stakedAmountOfToken -= currentUserStakingSlot
        .stakingAmountOfToken;
      currentUserStakingSlot.stakedAmountOfBoxes = 0;
      currentUserStakingSlot.stakingAmountOfToken = 0;
      _userStakingSlot[_campaignId][msg.sender] = currentUserStakingSlot;
      emit Unstaking(
        msg.sender,
        currentUserStakingSlot.stakingAmountOfToken,
        block.timestamp
      );
      return true;
    }

    currentUserStakingSlot.stakedAmountOfBoxes += calculatePendingBoxes(
      currentUserStakingSlot,
      _currentCampaign
    );
    currentToken.safeTransfer(
      msg.sender,
      currentUserStakingSlot.stakingAmountOfToken
    );

    // remove user staking amount from the pool
    _currentCampaign.stakedAmountOfToken -= currentUserStakingSlot
      .stakingAmountOfToken;
    currentUserStakingSlot.stakingAmountOfToken = 0;
    _userStakingSlot[_campaignId][msg.sender] = currentUserStakingSlot;
    emit Unstaking(
      msg.sender,
      currentUserStakingSlot.stakingAmountOfToken,
      block.timestamp
    );
    return true;
  }

  function getBlockTime() public view returns (uint256) {
    return block.timestamp;
  }

  function getTotalPenaltyAmount(uint256 campaignId)
    public
    view
    returns (uint256)
  {
    StakingCampaign memory _currentCampaign = _campaignStorage[campaignId];
    ERC20 currentToken = ERC20(_currentCampaign.tokenAddress);
    return
      currentToken.balanceOf(address(this)) -
      _currentCampaign.stakedAmountOfToken;
  }

  function withdrawPenaltyPot(uint256 campaignId, address beneficiary)
    external
    returns (bool)
  {
    // TODO: check beneficiary is one of address in registry
    StakingCampaign memory _currentCampaign = _campaignStorage[campaignId];
    ERC20 currentToken = ERC20(_currentCampaign.tokenAddress);
    uint256 withdrawingAmount = currentToken.balanceOf(address(this)) -
      _currentCampaign.stakedAmountOfToken;
    require(withdrawingAmount > 0, "StakingContract: Invalid penalty pot");
    currentToken.safeTransfer(beneficiary, withdrawingAmount);
    return true;
  }
}
