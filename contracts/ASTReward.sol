// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/IASTNftSale.sol";
import "./DateTime.sol";


contract ASTTokenRewards is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, DateTime {
    IASTNftSale public nftContract;
    IERC20Upgradeable public token;
    IASTNftSale public _astNftsale;

    enum CATEGORY {
        BRONZE,
        SILVER,
        GOLD,
        PLATINUM
    }

    struct UserTokenDetails {
        uint256 lastRewardClaimed; //last claimed rewards by user
        uint256 totalRewardsClaimed; // total rewards claimed by user
        uint256 rewardsOfSoldToken; //remaining accumulated rewards
        uint256 ClaimedRewardsDue; //claimed rewards due, due monthly claim limits
    }

    mapping(address => UserTokenDetails) public userTokenDetailsMap;
    mapping(uint256 => mapping(CATEGORY => uint256)) public RewardsMap; //year to category to rewardAmount
    mapping(uint256 => uint256) lastClaimOftoken; //tokenid to timestamp
    mapping(uint256 => uint256) WithdrawlMap; //month to withdrawl limit
    mapping(address => mapping(uint256 => uint256)) singleMonthClaims;
    // @dev ,  user => current month => claim amount

    event HoldingRewardsClaimed(uint256 tokenId, uint256 rewards, CATEGORY _category);
    event RewardsClaimedToday(
        address _user,
        uint256 totalRewards,
        uint256 SoldTokensRewards,
        uint256 ClaimedRewardsDue
    );

    function initialize(address _nftaddress, address _AstTokenAddr) public initializer {
        nftContract = IASTNftSale(_nftaddress);
        token = IERC20Upgradeable(_AstTokenAddr);
        _astNftsale = IASTNftSale(_nftaddress);
        RewardsMap[1][CATEGORY.BRONZE] = 1 * 10**18;
        RewardsMap[1][CATEGORY.SILVER] = 2 * 10**18;
        RewardsMap[1][CATEGORY.GOLD] = 3 * 10**18;
        RewardsMap[1][CATEGORY.PLATINUM] = 4 * 10**18;

        RewardsMap[2][CATEGORY.BRONZE] = (1 / 2) * 10**18;
        RewardsMap[2][CATEGORY.SILVER] = ((2 * 1) / 2) * 10**18;
        RewardsMap[2][CATEGORY.GOLD] = ((3 * 1) / 2) * 10**18;
        RewardsMap[2][CATEGORY.PLATINUM] = ((4 * 1) / 2) * 10**18;

        RewardsMap[3][CATEGORY.BRONZE] = ((1 * 1) / 4) * 10**18;
        RewardsMap[3][CATEGORY.SILVER] = ((2 * 1) / 4) * 10**18;
        RewardsMap[3][CATEGORY.GOLD] = ((3 * 1) / 4) * 10**18;
        RewardsMap[3][CATEGORY.PLATINUM] = ((4 * 1) / 4) * 10**18;

        WithdrawlMap[2] = 100 * 10**18; //as amount permitted in jan is zero
        WithdrawlMap[3] = 200 * 10**18;
        WithdrawlMap[4] = 300 * 10**18;
        WithdrawlMap[5] = 300 * 10**18;
        WithdrawlMap[6] = 750 * 10**18;
        WithdrawlMap[7] = 750 * 10**18;
        WithdrawlMap[8] = 750 * 10**18;
        WithdrawlMap[9] = 750 * 10**18;
        WithdrawlMap[10] = 1500 * 10**18;
        WithdrawlMap[11] = 1500 * 10**18;
        WithdrawlMap[12] = 2500 * 10**18;

        __Ownable_init();
        __ReentrancyGuard_init_unchained();
        __Pausable_init();
    }

    function claim() external nonReentrant whenNotPaused {
        UserTokenDetails storage userDetails = userTokenDetailsMap[_msgSender()];
        uint256 _rewardsOfSoldToken = userDetails.rewardsOfSoldToken; //if any sold token rewards

        uint256 rewards;

        uint256 currMonth = DateTime.getMonth(block.timestamp);
        uint256 nftBalance = nftContract.balanceOf(_msgSender());
        for (uint256 i; i < nftBalance; i++) {
            uint256 id = nftContract.tokenOfOwnerByIndex(_msgSender(), i);
            bool IsEligible = nftContract.checkTokenRewardEligibility(id);
            if (IsEligible) {
                uint256 amount = getRewardsCalc(id);
                uint8 x = uint8(nftContract.getCategory(id));
                lastClaimOftoken[id] = block.timestamp;
                uint256 _rewards = amount;
                rewards += amount;

                emit HoldingRewardsClaimed(id, _rewards, CATEGORY(x));
            }
        }

        uint256 _ClaimedRewardsDue = userDetails.ClaimedRewardsDue; //due to monthly limit user has not get this much rewards
        uint256 CanClaimRewards = rewards + userDetails.rewardsOfSoldToken + userDetails.ClaimedRewardsDue;

        uint256 prev = singleMonthClaims[_msgSender()][currMonth];

        if (prev + CanClaimRewards <= allowedWithdraw()) {
            singleMonthClaims[_msgSender()][currMonth] = prev + CanClaimRewards;
            userDetails.lastRewardClaimed = CanClaimRewards;
            userDetails.totalRewardsClaimed += CanClaimRewards;
            require(CanClaimRewards != 0, "No Rewards");

            token.transfer(_msgSender(), CanClaimRewards); //transferred claimedRewards
            emit RewardsClaimedToday(_msgSender(), CanClaimRewards, _rewardsOfSoldToken, _ClaimedRewardsDue);
        } else {
            uint256 canClaim = allowedWithdraw() - prev;
            singleMonthClaims[_msgSender()][currMonth] = prev + canClaim;
            userDetails.lastRewardClaimed = canClaim;
            userDetails.totalRewardsClaimed += canClaim;

            uint256 ClaimedRewardsDue = CanClaimRewards - canClaim;
            userDetails.ClaimedRewardsDue = ClaimedRewardsDue; //rewards due due to monthly limit
            require(canClaim != 0, "No Rewards");

            token.transfer(_msgSender(), canClaim); //transferred claimedRewards
            emit RewardsClaimedToday(_msgSender(), canClaim, _rewardsOfSoldToken, _ClaimedRewardsDue);
        }

        userDetails.rewardsOfSoldToken = 0; //updating sold token rewards
    }

    function getRewardsCalc(uint256 _id) public view returns (uint256 rewardAmount) {
        CATEGORY category = CATEGORY((nftContract.getCategory(_id)));

        uint256 purchaseTime = nftContract.getRevealedTime();
        uint256 timeDuration = block.timestamp - purchaseTime;
        uint256 dayCount = timeDuration / 1 days;
        if (dayCount != 0) {
            rewardAmount = dayCount <= 365 ? dayCount * RewardsMap[1][category] : (dayCount > 365 && dayCount <= 730)
                ? (365 * RewardsMap[1][category]) + ((dayCount - 365) * RewardsMap[2][category])
                : dayCount > 730 && dayCount <= 1095
                ? (365 * RewardsMap[1][category]) +
                    (365 * RewardsMap[2][category]) +
                    ((dayCount - 730) * RewardsMap[3][category])
                : (365 * RewardsMap[1][category]) + (365 * RewardsMap[2][category]) + (365 * RewardsMap[3][category]);
        }
        if (lastClaimOftoken[_id] > purchaseTime) {
            uint256 claimDays = (lastClaimOftoken[_id] - purchaseTime) / 1 days;
            uint256 claimedAmount = claimDays <= 365
                ? claimDays * RewardsMap[1][category]
                : claimDays > 365 && claimDays <= 730
                ? (365 * RewardsMap[1][category]) + (claimDays * RewardsMap[2][category])
                : claimDays > 730 && claimDays <= 1095
                ? (365 * RewardsMap[1][category]) +
                    (365 * RewardsMap[2][category]) +
                    (claimDays * RewardsMap[3][category])
                : (365 * RewardsMap[1][category]) + (365 * RewardsMap[2][category]) + (365 * RewardsMap[3][category]);
            rewardAmount -= claimedAmount;
        }
    }

    function updateData(
        uint256 _tokenId,
        uint256 _rewards,
        address _from
    ) external {
        require(address(nftContract) == msg.sender, "Invalid Caller");
        UserTokenDetails storage userDetails = userTokenDetailsMap[_from];
        userDetails.rewardsOfSoldToken += _rewards; // store unclaimed rewards

        lastClaimOftoken[_tokenId] = block.timestamp; //update last claim of sold token id
    }

    function setWithdrawalLimits(uint256 _month, uint256 _limit) external onlyOwner {
        WithdrawlMap[_month] = _limit;
    }

    function setRewardsMap(
        uint256 _rewards,
        uint256 _year,
        CATEGORY _x
    ) external onlyOwner {
        RewardsMap[_year][_x] = _rewards * 10**18;
    }

    function tokensAvailable() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateASTNFTaddress(address _nftaddress) external {
        nftContract = IASTNftSale(_nftaddress);
    }

    function allowedWithdraw() internal view returns (uint256) {
        uint256 currMonth = DateTime.getMonth(block.timestamp);
        return WithdrawlMap[currMonth];
    }

    function withdrawAmount() external onlyOwner {
        (bool success, ) = payable(_msgSender()).call{ value: address(this).balance }("");
        require(success);
    }

    function withdrawToken(address admin, address _paymentToken) external onlyOwner {
        IERC20Upgradeable _token = IERC20Upgradeable(_paymentToken);
        uint256 amount = _token.balanceOf(address(this));
        token.transfer(admin, amount);
    }
}
