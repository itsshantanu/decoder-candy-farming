//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CandyToken.sol";

contract CandyFarm {
    // userrAddress => stakingBalance
    mapping(address => uint256) public stakingBalance;

    // userAddress => isStaking boolean
    mapping(address => bool) public isStaking;

    /**
     * @dev will track the timestamp of the user's address to track the user's unrealized performance
     */
    // userAddress => timeStamp
    mapping(address => uint256) public startTime;

    /**
     * @dev will point to the return of the CandyToken (not to be confused with the actually minted CandyToken) associated with the user's address.
     */
    // userAddress => candyBalance
    mapping(address => uint256) public candyBalance;

    string public name = "Candy Farm";

    IERC20 public daiToken;
    CandyToken public candyToken;

    // declare events for the contract
    event Stake(address indexed from, uint256 amount);
    event UnStake(address indexed from, uint256 amount);
    event YieldWithdraw(address indexed from, uint256 amount);

    constructor(IERC20 _daiToken, CandyToken _candyToken) {
        daiToken = _daiToken;
        candyToken = _candyToken;
    }

    /// Core function shells

    /**
     * @dev Stake function require what the param of quantity be greater than 0, and
     * and what the user have sufficient DAI for cover the transaction.
     */
    function stake(uint256 amount) public {
        /**
         * @dev require that the user have sufficient DAI to cover the transaction
         */
        require(
            amount > 0 && daiToken.balanceOf(msg.sender) >= amount,
            "You cannot stake zero tokens."
        );

        /**
         * @dev Check if the user bet DAI
         * If so, the contract adds the unrealized return to the candyBalance.
         * This ensures that the accumulated performance does not disappear.
         */
        if (isStaking[msg.sender] == true) {
            uint256 toTransfer = calculateYieldTotal(msg.sender);
            candyBalance[msg.sender] += toTransfer;
        }

        /**
         * @dev then we call the function transferFrom to transfer the DAI from the user's
         * address to the contract's address
         */
        daiToken.transferFrom(msg.sender, address(this), amount);

        /**
         * @dev then we update the stakingBalance, startTime and eStaking of the user's address
         */
        stakingBalance[msg.sender] += amount;
        startTime[msg.sender] = block.timestamp;
        isStaking[msg.sender] = true;

        /**
         * @dev then we emit the event Stake for allow the Interface listen easily the event.
         */
        emit Stake(msg.sender, amount);
    }

    /**
     * @dev UnStake function require what the mapping isStake be equal to true.
     * (which only happens when the stake function is called) and requires that the
     * amount requested for stake is not greater than the user's staked balance
     */
    function unstake(uint256 amount) public {
        /**
         * @dev verify if user have tokens in staking
         */
        require(
            isStaking[msg.sender] == true &&
                stakingBalance[msg.sender] >= amount,
            "Nothing to unstake"
        );

        /**
         * @dev
         */
        uint256 yieldTransfer = calculateYieldTotal(msg.sender);

        /**
         * @dev
         */
        startTime[msg.sender] = block.timestamp; /// bug fix

        uint256 balanceTransfer = amount;
        amount = 0;

        stakingBalance[msg.sender] -= balanceTransfer;
        daiToken.transfer(msg.sender, balanceTransfer);

        candyBalance[msg.sender] += yieldTransfer;

        if (stakingBalance[msg.sender] == 0) {
            isStaking[msg.sender] = false;
        }

        emit UnStake(msg.sender, amount);
    }

    /**
     * @dev Withdraw requires the total return calculateYieldTotal function or candyBalance to
     * maintain a balance for the user.
     */
    function withdrawYield() public {
        uint256 toTransfer = calculateYieldTotal(msg.sender);

        /**
         * @dev check if the user have tokens in staking
         */
        require(
            toTransfer > 0 || candyBalance[msg.sender] > 0,
            "Nothing to withdraw"
        );

        /**
         * @dev This sentence check if user have candyBalance
         * If this allocation points to a balance, it means that the user
         * wagered DAI more than once. The contract logic adds the old candyBalance
         * to the current throughput total that we receive from the total throughput calculation.
         */
        if (candyBalance[msg.sender] != 0) {
            uint256 oldBalance = candyBalance[msg.sender];
            candyBalance[msg.sender] = 0;
            toTransfer += oldBalance;
        }

        startTime[msg.sender] = block.timestamp;
        candyToken.mint(msg.sender, toTransfer);
        emit YieldWithdraw(msg.sender, toTransfer);
    }

    // [AUXILIAR FUNCTIONS]

    /**
     * @dev it simply subtracts the startTime timestamp from the address of the specified
     * user by the current timestamp. This function acts more like a helper than a helper
     * function. The visibility of this function must be internal; however, I chose to give
     * public visibility for the tests.
     */
    function calculateYieldTime(address user) public view returns (uint256) {
        uint256 end = block.timestamp;
        uint256 totalTime = end - startTime[user];
        return totalTime;
    }

    /**
     * @dev allows the automated betting process to occur. First, the logic takes the return
     * value of the performance time calculation function and multiplies it by 10¹⁸.
     * This is necessary since Solidity does not handle floating point or fractional numbers. 
     * By converting the returned timestamp difference to a BigNumber , Solidity can provide
     * much more precision. The rate variable equals 86,400, which equals the number of seconds
     * in a single day. The idea is: the user receives 100% of their staked DAI every 24 hours.

     * @dev In a more traditional yield farm, the rate is determined by the percentage of the user's
     * pool rather than time.
     */
    function calculateYieldTotal(address user) public view returns (uint256) {
        uint256 time = calculateYieldTime(user) * 10**18;
        uint256 rate = 86400;
        uint256 timeRate = time / rate;
        uint256 rawYield = (stakingBalance[user] * timeRate) / 10**18;
        return rawYield;
    }
}
