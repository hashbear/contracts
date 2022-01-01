pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MysteryBox is Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _boxId;

    address public synTokenAddress;
    address public esynTokenAddress;
    address public paymentReceiver;

    mapping (uint256 => Box) boxes;
    mapping (uint256 => address) tokenOwners;

    event BoxCreated(uint256 boxId);
    event BoxBought(address buyer, uint256 boxId, uint256 tokenId);

    struct Box {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        uint256 synPrice;
        uint256 esyncPrice;
        uint256 fromTokenId;
        uint256 tillTokenId; //not inclusive
        uint256 curAvailableTokenId;
    }

    constructor(address _synTokenAddress, address _esynTokenAddress, address _paymentReceiver) {
        synTokenAddress = _synTokenAddress;
        esynTokenAddress = _esynTokenAddress;
        paymentReceiver = _paymentReceiver;

        _boxId.increment(); //so boxId will start from 1
    }

    function updatePaymentReceiver(address _paymentReceiver) public onlyOwner {
        paymentReceiver = _paymentReceiver;
    }

//    The assumption is that tokens are generated in advance in database, but not revealed yet. When user buy token, he gets tokenid, but does not know what items he gets.
//    After all items are sold or available time finished, we update data in database and show what assets user got.
//    For example mystery box has 100 items. Then we can generate 100 items in db, for example from 0x288eff3b977db1a75833078f8efe8a5dced20bde2887105485676b2c43f1259f till 0x288eff3b977db1a75833078f8efe8a5dced20bde2887105485676b2c43f1259f+100
    function newBox(
        uint256 _base,
        uint256 _amount,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _synPrice,
        uint256 _esyncPrice
    ) public onlyOwner {
        Box storage box = boxes[_boxId.current()];
        box.id = _boxId.current();
        box.startTime = _startTime;
        box.endTime = _endTime;
        box.synPrice = _synPrice;
        box.esyncPrice = _esyncPrice;
        box.fromTokenId = _base;
        box.tillTokenId = _base + _amount;
        box.curAvailableTokenId = _base;

        _boxId.increment();

        emit BoxCreated(box.id);
    }

    function buy(uint256 boxId, bool useSynToken) public {
        Box storage box = boxes[boxId];

        require(box.id != 0, "mystery box with such id does not exist");

        if (box.startTime != 0) {
            require(box.startTime <= block.timestamp, "give away not started yet");
        }

        if (box.endTime != 0) {
            require(block.timestamp < box.endTime, "give away not started yet");
        }

        require(box.curAvailableTokenId < box.tillTokenId, "no more available tokens left");
        require(tokenOwners[box.curAvailableTokenId] == address(0), "token already used by someone");

        tokenOwners[box.curAvailableTokenId] = msg.sender;
        box.curAvailableTokenId += 1;

        if (useSynToken && box.synPrice > 0) {
            require(IERC20(synTokenAddress).transferFrom(msg.sender, paymentReceiver, box.synPrice), "unable to transfer syn tokens");
        } else if (box.esyncPrice > 0) {
            require(IERC20(esynTokenAddress).transferFrom(msg.sender, paymentReceiver, box.synPrice), "unable to transfer esyn tokens");
        }

        emit BoxBought(msg.sender, boxId, box.curAvailableTokenId - 1);
    }
}
