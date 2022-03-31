// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {IERC2981} from "openzeppelin-contracts/contracts/interfaces/IERC2981.sol";

contract GOATS is ERC721 {
    // last goat id is 10003 but +1 for not-zero-indexed
    uint256 private constant threshold = 10004;

    ERC721 public immutable trolls;
    address public immutable beneficiary;
    uint256 public immutable cost; // in wei

    uint256 private nextTokenId = 1;

    event GoatEaten(uint256 id);

    error TooManyGoats();
    error TheGoatsDemandCoin();
    error TooManyGoatsTooManyGoats();

    constructor(
        address _beneficiary,
        uint256 _cost,
        ERC721 _trolls
    ) ERC721("Just Some Fuckin' Goats", "GOATS") {
        beneficiary = _beneficiary;
        cost = _cost;
        trolls = _trolls;
    }

    function herd(uint256 goats) external payable {
        if (goats > 20) revert TooManyGoats();
        if (msg.value != cost * goats) revert TheGoatsDemandCoin();
        if (nextTokenId + goats > threshold) revert TooManyGoatsTooManyGoats();

        for (uint256 i = 0; i < goats; i++) {
            // if you own trolls there's a chance one of your trolls eats your goat
            uint256 numTrolls = trolls.balanceOf(msg.sender);
            if (numTrolls > 0 && i > 0 && ate(numTrolls)) {
                _safeMint(address(trolls), nextTokenId);
                emit GoatEaten(nextTokenId);
            } else {
                _safeMint(msg.sender, nextTokenId);
            }

            // hi t11s
            unchecked {
                ++nextTokenId;
            }
        }
    }

    function tokenURI(uint256 id)
        public
        pure
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked("ipfs:///", id, ".json"));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // a 5% royalty to the fuckin' dao
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        virtual
        returns (address, uint256)
    {
        return (beneficiary, (_salePrice * 5) / 100);
    }

    // yes, this is hilariously trivial, but if you want to flashbot the goats that says more about you than it does me
    function ate(uint256 num) internal view returns (bool) {
        return block.difficulty % 500 < num;
    }
}
