pragma solidity 0.6.12;

import "@openzeppelin/contracts/introspection/IERC165.sol";

interface IERC2981RoyaltySetter is IERC165 {
    // bytes4(keccak256('setDefaultRoyalty(address,uint16)')) == 0x4331f639
    // bytes4(keccak256('setTokenRoyalty(uint256,address,uint16)')) == 0x78db6c53

    // => Interface ID = 0x4331f639 ^ 0x78db6c53 == 0x3bea9a6a

    function setDefaultRoyalty(address _receiver, uint16 _royaltyPercent)
        external;

    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint16 _royaltyPercent
    ) external;
}
