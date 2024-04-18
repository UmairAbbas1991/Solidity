// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// Contract declaration inheriting no other contract
contract TimeLockedVesting {
    using SafeMath for uint256; // Using SafeMath to prevent overflow issues

    // State variables declaration
    IERC20 public token;           // ERC20 token used for vesting
    address public payer;          // Address that will deposit the tokens (usually the employer or contract initiator)
    uint256 public startTime;      // When the vesting period starts
    uint256 public totalDuration;  // Total duration of the vesting period in seconds
    uint256 public totalAmount;    // Total amount of tokens to be vested
    uint256 public amountWithdrawn;// Tracks the amount of tokens withdrawn to prevent over-withdrawal

    // Constructor to initialize the contract with necessary parameters
    constructor(address _tokenAddress, address _payer, uint256 _totalAmount, uint256 _durationInDays) {
        token = IERC20(_tokenAddress);    // Set the token contract address
        payer = _payer;                   // Set the payer address
        totalAmount = _totalAmount;       // Set the total amount of tokens to be vested
        totalDuration = _durationInDays * 1 days; // Convert duration from days to seconds
        startTime = block.timestamp;      // Set the start time to the current block timestamp
    }

    // Function to deposit tokens into the contract by the payer
    function deposit() external {
        require(msg.sender == payer, "Only the payer can deposit tokens.");  // Ensure only the payer can deposit
        require(token.transferFrom(payer, address(this), totalAmount), "Failed to transfer tokens."); // Transfer tokens from payer to this contract
    }

    // View function to calculate the amount available for withdrawal
    function availableToWithdraw() public view returns (uint256) {
        if (block.timestamp < startTime) {
            return 0; // No tokens available if the current time is before the start time
        }
        uint256 timeElapsed = block.timestamp.sub(startTime); // Calculate elapsed time since start
        uint256 unlockedAmount = totalAmount.mul(timeElapsed).div(totalDuration); // Calculate linearly unlocked amount
        return unlockedAmount.sub(amountWithdrawn); // Subtract already withdrawn amount from unlocked amount
    }

    // Function to withdraw available tokens by the beneficiary
    function withdraw() public {
        uint256 available = availableToWithdraw(); // Determine the available amount
        require(available > 0, "No tokens are available for withdrawal yet."); // Ensure there is something to withdraw

        amountWithdrawn = amountWithdrawn.add(available); // Update the withdrawn amount
        require(token.transfer(msg.sender, available), "Failed to transfer tokens."); // Transfer the available tokens to the caller
    }

    // Function to allow recovery of tokens after the vesting period ends
    function recoverUnclaimedTokens() external {
        require(block.timestamp > startTime.add(totalDuration), "Vesting period has not yet ended."); // Check if the vesting period has ended
        uint256 remainingTokens = token.balanceOf(address(this)); // Determine how many tokens remain in the contract
        require(token.transfer(payer, remainingTokens), "Failed to recover tokens."); // Return remaining tokens to the payer
    }
}
//When you deploy the Time-Locked ERC20 Vesting contract, you need to provide specific input parameters that the contract constructor requires to properly initialize and set up the contract environment. These inputs are necessary for defining the rules and functionality of the vesting process.

//Inputs required for deployment:
//_tokenAddress: The address of the ERC20 token that will be used in the vesting schedule. This should be the contract address of the ERC20 token on the blockchain where you are deploying this vesting contract.
//_payer: The address of the entity (such as a company or individual) that will deposit the tokens into the vesting contract. This address will be authorized to deposit the specified amount of tokens.
//_totalAmount: The total amount of tokens that will be vested over the vesting period. This should be expressed in the smallest unit of the token, considering its decimals.
//_durationInDays: The total duration of the vesting period expressed in days. Over this period, the tokens will gradually become available for withdrawal by the beneficiary.

//Example deployment inputs:
//Suppose you have an ERC20 token deployed at address 0x123...abc, and you want to set up a vesting schedule for an employee:

//Token Address: 0x123abc... (the contract address of the ERC20 token)
//Payer Address: 0x456def... (the employer's address who will fund the vesting)
//Total Amount: 100000 (total tokens to be vested, assuming the token has 0 decimals for simplicity)
//Duration in Days: 365 (the tokens will vest over one year)

//What happens after deployment:
//Contract initialization: When you deploy the contract with these parameters, it sets up the internal state with the specified token address, payer, total amount of tokens for vesting, and the vesting duration. It records the deployment time as the start time of the vesting.
//Token deposit: Post-deployment, the payer (in this example, the employer) needs to approve the newly deployed vesting contract to withdraw up to 100000 tokens on their behalf. This is done by calling the approve function on the ERC20 token's contract. After approval, the payer calls the deposit function on the vesting contract to transfer the tokens into it.
//Vesting period begins: From the moment of token deposit, the vesting schedule is active. The availableToWithdraw function can be called at any time to check how many tokens are available for withdrawal based on the elapsed time since the start.
//Withdrawal by beneficiary: The beneficiary can start withdrawing their available tokens as per the vesting schedule by calling the withdraw function. They can do this repeatedly over the vesting period until all tokens are withdrawn.
//End of vesting period: After the vesting period ends, if there are any tokens left due to the beneficiary not withdrawing them, the payer can use the recoverUnclaimedTokens function to retrieve the remaining tokens.