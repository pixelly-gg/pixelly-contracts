// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./library/IERC20.sol";

interface IPixellyAddressRegistry {
    function tokenRegistry() external view returns (address);
}

interface IPixellyTokenRegistry {
    function enabled(address) external returns (bool);
}

interface IOracle {
    function getCurrentPrice(address token) external view returns (uint256 price);
}

contract PixellyPriceFeed is Ownable {
    /// @notice keeps track of oracles for each tokens
    mapping(address => address) public oracles;

    /// @notice Pixelly address registry contract
    address public addressRegistry;

    /// @notice wrapped ETH contract
    address public wETH;

    constructor(address _addressRegistry, address _wETH) public {
        addressRegistry = _addressRegistry;
        wETH = _wETH;
    }

    /**
     @notice Register oracle contract to token
     @dev Only owner can register oracle
     @param _token ERC20 token address
     @param _oracle Oracle address
     */
    function registerOracle(address _token, address _oracle)
        external
        onlyOwner
    {
        IPixellyTokenRegistry tokenRegistry = IPixellyTokenRegistry(
            IPixellyAddressRegistry(addressRegistry).tokenRegistry()
        );
        require(tokenRegistry.enabled(_token), "invalid token");
        require(oracles[_token] == address(0), "oracle already set");

        oracles[_token] = _oracle;
    }

    /**
     @notice Update oracle address for token
     @dev Only owner can update oracle
     @param _token ERC20 token address
     @param _oracle Oracle address
     */
    function updateOracle(address _token, address _oracle) external onlyOwner {
        require(oracles[_token] != address(0), "oracle not set");

        oracles[_token] = _oracle;
    }

    /**
     @notice Get current price for token
     @dev return current price or if oracle is not registered returns 0
     @param _token ERC20 token address
     */
    function getPrice(address _token) external view returns (uint256, uint8) {
        if (oracles[_token] == address(0)) {
            return (0, 0);
        }

        IOracle oracle = IOracle(oracles[_token]);
        IERC20 token = IERC20(_token);

        return (oracle.getCurrentPrice(_token), token.decimals());
    }

    /**
     @notice Update address registry contract
     @dev Only admin
     */
    function updateAddressRegistry(address _addressRegistry)
        external
        onlyOwner
    {
        addressRegistry = _addressRegistry;
    }
}
