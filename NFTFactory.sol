pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./ProxyRegistry.sol";

contract NFTFactory is ERC1155, Ownable {

    mapping(uint256 => bool) private _minted;
    address private trustedSigner;
    address private proxyRegistryAddress;

    constructor(address _trustedSigner, address _proxyRegistryAddress) ERC1155("https://example.com/{id}") {
        trustedSigner = _trustedSigner;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function _isProxy(
        address _address,
        address _addressProxy
    ) internal view returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        return address(proxyRegistry.proxies(_address)) == _addressProxy;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()) || _isProxy(from, _msgSender()),
            "ERC1155: caller is not owner nor approved nor authenticated proxy"
        );

        if (_minted[id]) {
            _safeTransferFrom(from, to, id, amount, data);
            return;
        }
        _minted[id] = true;

        bytes memory signature = data;
        bytes32 hashedData = keccak256(
            abi.encodePacked(
                from,
                to,
                id,
                amount
            )
        );
        bytes32 hashedDataReadyToSign = ECDSA.toEthSignedMessageHash(hashedData);
        address recoveredAddress = ECDSA.recover(hashedDataReadyToSign, signature);

        require(recoveredAddress == trustedSigner, "ERC1155: invalid message signer for minting");

        _mint(to, id, amount, data);
    }
}
