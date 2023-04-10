//   /$$$$$$  /$$$$$$ /$$$$$$$$/$$$$$$$  /$$$$$$  /$$$$$$ /$$   /$$
//  /$$__  $$/$$__  $|__  $$__| $$__  $$/$$__  $$/$$__  $| $$$ | $$
// | $$  \ $| $$  \__/  | $$  | $$  \ $| $$  \ $| $$  \ $| $$$$| $$
// | $$$$$$$|  $$$$$$   | $$  | $$$$$$$| $$  | $| $$  | $| $$ $$ $$
// | $$__  $$\____  $$  | $$  | $$__  $| $$  | $| $$  | $| $$  $$$$
// | $$  | $$/$$  \ $$  | $$  | $$  \ $| $$  | $| $$  | $| $$\  $$$
// | $$  | $|  $$$$$$/  | $$  | $$  | $|  $$$$$$|  $$$$$$| $$ \  $$
// |__/  |__/\______/   |__/  |__/  |__/\______/ \______/|__/  \__/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title ASTILO
 * @dev ASTILO contract is Ownable
 **/
contract ASTILO is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    IERC20Upgradeable token;
    /// @dev Merkle root for a whitelist users
    bytes32 private merkleRoot;

    uint256 private saleId;
    uint256 public initialTokens; // Initial number of tokens available
    bool public presaleM;
    bool public publicM;

    struct SaleDetail {
        uint256 rate; // Number of tokens per Ether
        uint256 cap; // Cap in Ether
        uint256 start; // Oct 17, 2022 @ 12:00 EST
        uint256 _days; // 45 Day
        uint256 cliff;
        uint256 vesting;
        uint256 thresHold;
        uint256 raisedIn;
        uint256 tokenSold;
        uint256 minBound; //min to buy
    }

    struct UserToken {
        uint256 saleRound;
        uint256 tokenspurchased;
        uint256 claimed;
        uint256 lastClaimedTime;
        uint256 createdOn;
        uint256 userCliff;
        uint256 remainingTokens;
    }

    mapping(uint256 => SaleDetail) public salesDetailMap;
    mapping(uint256 => mapping(address => UserToken)) public userTokenMap;
    mapping(uint256 => bool) internal saleIdMap;
    /**
     * BoughtTokens
     * @dev Log tokens bought onto the blockchain
     */
    event BoughtTokens(address indexed to, uint256 value, uint256 saleId);
    event SaleCreated(uint256 saleId);
    event Claimed(address indexed receiver, uint256 amount, uint256 saleId);

    uint256 private seedSaleId;
    uint256 private privateSaleId;
    uint256 private publicSaleId;

    bytes32 private privateMerkleRoot;

    /**
     * initialize
     * @dev Initialize the contract
     **/
    function initialize(
        address _tokenAddr,
        uint256 _initialTokens
    )
        external
        initializer
    {
        require(_tokenAddr != address(0));
        require(_initialTokens > 0);
        initialTokens = _initialTokens * 10**18;

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        token = IERC20Upgradeable(_tokenAddr);
    }

    /**
     * @notice startTokenSale for starting any token sale
     */

    function set_initialTokens(
        uint256 _newValue
    )
        public
        onlyOwner
    {
        initialTokens = _newValue * 10**18;
    }

    function updateSaleIdbyType(uint256 _saleType, uint256 _saleId) internal {
        if(_saleType == 0) {
            seedSaleId = _saleId;
        } else if (_saleType == 1) {
            privateSaleId = _saleId;
        } else {
            publicSaleId = _saleId;
        }
    }

    function getSaleIdbyType(uint256 _saleType) internal view returns(uint256) {
        uint256 _saleId = _saleType == 0 
            ? seedSaleId
            : _saleType == 1
            ? privateSaleId
            : publicSaleId;
        return _saleId;
    }

    function startTokenSale(
        uint256 _saleType,
        uint256 _saleId,
        uint256 _rate,
        uint256 _cap,
        uint256 _start,
        uint256 _ddays,
        uint256 _thresHold,
        uint256 _cliff,
        uint256 _vesting,
        uint256 _minBound
    )
        external
        whenNotPaused
        onlyOwner
        returns (uint256)
    {
        require(_saleType == 0 || _saleType == 1 || _saleType == 2, "Invalid sale type");
        saleId++;
        updateSaleIdbyType(_saleType, saleId);

        SaleDetail memory detail;
        detail.rate = _rate;
        detail.cap = _cap;
        detail.start = _start;
        detail._days = _ddays;
        detail.cliff = _cliff * 1 days;
        detail.vesting = _vesting;
        detail.thresHold = _thresHold;
        detail.minBound = _minBound;
        detail.tokenSold = salesDetailMap[_saleId].tokenSold;
        salesDetailMap[saleId] = detail;
        emit SaleCreated(saleId);
        return saleId;
    }

    /**
     * @notice Update Merkel Root to Whitelist users
     * @param _merkleRoot for whitelist users
     */
    function setSeedMerkleRoot(
        bytes32 _merkleRoot
    ) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPrivateSaleMerkleRoot(
        bytes32 _merkleRoot
    ) external onlyOwner {
        privateMerkleRoot = _merkleRoot;
    }

    function togglePresale()
        public
        onlyOwner
    {
        presaleM = !presaleM;
    }

    function togglePublicSale()
        public
        onlyOwner
    {
        publicM = !publicM;
    }

    function pause()
        public
        onlyOwner
    {
        _pause();
    }

    function unpause()
        public
        onlyOwner
    {
        _unpause();
    }

    function updateSaleIdStatus(
        uint256 _saleId
    )
        external
        onlyOwner
    {
        saleIdMap[_saleId] = !saleIdMap[_saleId];
    }
    /**
     * @notice get curren active merkel root
     */
    function getSeedMerkleRoot()
        external
        view
        returns (bytes32)
    {
        return merkleRoot;
    }

    /**
     * @notice get curren active merkel root
     */

    function getPrivateMerkleRoot()
        external
        view
        returns (bytes32)
    {
        return privateMerkleRoot;
    }

    /**
     * @notice check user whitelist or not
     * @param _merkleProof merkelProof generated by MerkelTree for current MerkelRoot
     */
    modifier checkWhitelist(uint256 _saleType, bytes32[] memory _merkleProof) {
        bytes32 sender = keccak256(abi.encodePacked(_msgSender()));
        bytes32 _merkleRoot = _saleType == 0 ? merkleRoot : privateMerkleRoot;
        require(
            MerkleProofUpgradeable.verify(_merkleProof, _merkleRoot, sender),
            "not whitelisted"
        );
        _;
    }

    /**
     * isActive
     * @dev Determins if the contract is still active
     **/
    function isActive(
        uint256 _saleId
    )
        public
        view
        returns (bool)
    {
        SaleDetail memory detail = salesDetailMap[_saleId];
        return (block.timestamp >= detail.start && // Must be after the start date
            block.timestamp <= detail.start + (detail._days * 1 days) && // Must be before the end date
            goalReached(_saleId) == false) && // Goal must not already be reached
            !saleIdMap[_saleId]; // Must be saleIdMap is false
    }

    /**
     * goalReached
     * @dev Function to determin is goal has been reached
     **/
    function goalReached(
        uint256 _saleId
    )
        public
        view
        returns (bool)
    {
        SaleDetail memory detail = salesDetailMap[_saleId];
        return (detail.raisedIn >= detail.cap * 1 ether);
    }

    /**
     * @dev Fallback function if ether is sent to address insted of buyTokens function
     **/
    fallback() external payable {
        buyTokens();
    }

    receive() external payable {
        buyTokens();
    }

    /**
     * buyTokens
     * @dev function that sells available tokens
     **/
    function preSaleBuy(
        uint256 _saleType,
        bytes32[] calldata _proof
    )
        public
        payable
        whenNotPaused
        nonReentrant
        checkWhitelist(_saleType, _proof)
    {
        require(
            _saleType == 0 || _saleType == 1,
            "Invalid sale type"
        );
        uint256 _saleId = getSaleIdbyType(_saleType);
        require(
            isActive(_saleId),
            "Sale is not active"
        );
        require(
            presaleM,
            "Presale is OFF"
        );
        require(
            msg.value > 0,
            "invalid amount"
        );
        SaleDetail memory detail = salesDetailMap[_saleId];
        UserToken memory userToken = userTokenMap[_saleId][_msgSender()];
        uint256 _tokens = calculateToken(msg.value, detail.rate);
        require(
            _tokens >= detail.minBound && _tokens <= detail.thresHold && _tokens <= initialTokens,
            "buying more than max allowed"
        );
        userToken.saleRound = _saleId;
        userToken.createdOn = block.timestamp;
        userToken.lastClaimedTime = block.timestamp;
        userToken.userCliff = block.timestamp + detail.cliff;
        userToken.tokenspurchased += _tokens;
        userToken.remainingTokens += _tokens;

        emit BoughtTokens(msg.sender, _tokens, _saleId); // log event onto the blockchain
        detail.tokenSold += _tokens;
        initialTokens -= _tokens;
        detail.raisedIn += msg.value; // Increment raised amount
        salesDetailMap[_saleId] = detail;
        userTokenMap[_saleId][_msgSender()] = userToken;
        payable(owner()).transfer(msg.value); // Send money to owner
    }

    function calculateToken(
        uint256 amount,
        uint256 _rate
    )
        public
        pure
        returns (uint256)
    {
        return (amount / _rate) * 10**18;
    }

    function claim(
        uint256 _saleId
    )
        external
        whenNotPaused
        nonReentrant
    {
        SaleDetail memory detail = salesDetailMap[_saleId];
        require(
            block.timestamp > detail.cliff,
            "cliff not ended"
        );
        UserToken memory utoken = userTokenMap[_saleId][_msgSender()];
        require(
            utoken.saleRound == _saleId,
            "not purchase data"
        );
        require(
            utoken.remainingTokens != 0,
            "no tokens left"
        );
        uint256 claimedOn = utoken.lastClaimedTime == utoken.createdOn ? utoken.userCliff : utoken.lastClaimedTime;

        uint256 amount = calculateReleaseToken(utoken.tokenspurchased, detail.vesting, claimedOn);
        require(
            amount > 0,
            "no rewards"
        );
        require(
            amount < tokensAvailable(),
            "insufficent token balance"
        );

        utoken.claimed += amount;
        utoken.remainingTokens = utoken.remainingTokens - amount;
        utoken.lastClaimedTime = block.timestamp;
        userTokenMap[_saleId][_msgSender()] = utoken;
        token.transfer(_msgSender(), amount);
        emit Claimed(_msgSender(), amount, _saleId);
    }

    function calculateReleaseToken(
        uint256 _token,
        uint256 vesting,
        uint256 lastClaimedTime
    )
        public
        view
        returns (uint256)
    {
        uint256 tokenperDay = _token / vesting;
        uint256 day = _getDays(lastClaimedTime);
        return tokenperDay * (day > vesting ? vesting : day);
    }

    function getReward(
        uint256 _saleId,
        address _addr
    )
        external
        view
        whenNotPaused
        returns (uint256)
    {
        SaleDetail memory detail = salesDetailMap[_saleId];
        UserToken memory utoken = userTokenMap[_saleId][_addr];
        uint256 claimedOn = utoken.lastClaimedTime == utoken.createdOn
            ? utoken.userCliff
            : utoken.lastClaimedTime;
        uint256 amount = calculateReleaseToken(utoken.tokenspurchased, detail.vesting, claimedOn);
        return amount;
    }

    function _getDays(
        uint256 _timestamp
    )
        internal
        view
        returns (uint256)
    {
        return (block.timestamp - _timestamp) / 86400;
    }

    /**
     *
     * buyTokens
     * @dev function that sells available tokens
     **/
    function buyTokens()
        public
        payable
        whenNotPaused
        nonReentrant
    {
        uint256 _saleId = getSaleIdbyType(2);
        require(
            isActive(_saleId),
            "Sale is not active"
        );
        require(
            publicM,
            "sale is OFF"
        );
        require(
            msg.value > 0,
            "value should be grater than. zero"
        );
        SaleDetail memory detail = salesDetailMap[_saleId];
        uint256 tokens = calculateToken(msg.value, detail.rate);
        require(
            tokens < detail.thresHold,
            "buying more than max allowed"
        );
        emit BoughtTokens(msg.sender, tokens, _saleId); // log event onto the blockchain
        detail.raisedIn += msg.value; // Increment raised amount
        detail.tokenSold += tokens;
        initialTokens -= tokens;
        salesDetailMap[_saleId] = detail;
        token.transfer(msg.sender, tokens); // Send tokens to buyer
        payable(owner()).transfer(msg.value); // Send money to owner
    }

    /**
     * tokensAvailable
     * @dev returns the number of tokens allocated to this contract
     **/
    function tokensAvailable()
        public
        view
        returns (uint256)
    {
        return token.balanceOf(address(this));
    }

    function withdrawETH(
        address admin
    )
        external
        onlyOwner
    {
        payable(admin).transfer(address(this).balance);
    }

    function withdrawToken(
        address admin,
        address _paymentToken
    )
        external
        onlyOwner
    {
        IERC20Upgradeable _token = IERC20Upgradeable(_paymentToken);
        uint256 amount = _token.balanceOf(address(this));
        token.transfer(admin, amount);
    }
}