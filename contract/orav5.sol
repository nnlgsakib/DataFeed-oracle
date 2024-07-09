// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Oracle_v3 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    struct Data {
        string data;
        uint256 timestamp;
    }

    struct UrlElement {
        string element;
        bool exists;
    }

    mapping(string => Data) private dataStore;
    mapping(string => UrlElement) private urlElementStore;
    string[] private urlList;

    event DataUpdated(string url, string data, uint256 timestamp);
    event UrlElementUpdated(string url, string element);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) initializer public {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        transferOwnership(initialOwner);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function updateData(string memory _url, string memory _data) public onlyOwner {
        Data storage data = dataStore[_url];
        data.data = _data;
        data.timestamp = block.timestamp;
        emit DataUpdated(_url, _data, block.timestamp);
    }

    function updateDataBatch(string[] memory _urls, string[] memory _data) public onlyOwner {
        require(_urls.length == _data.length, "Mismatched array lengths");
        for (uint256 i = 0; i < _urls.length; i++) {
            dataStore[_urls[i]] = Data({
                data: _data[i],
                timestamp: block.timestamp
            });
            emit DataUpdated(_urls[i], _data[i], block.timestamp);
        }
    }

    function getData(string memory _url) public view returns (string memory, uint256) {
        Data memory data = dataStore[_url];
        return (data.data, data.timestamp);
    }

    function addUrlElement(string memory _url, string memory _element) public onlyOwner {
        if (!urlElementStore[_url].exists) {
            urlList.push(_url);
        }
        urlElementStore[_url] = UrlElement({element: _element, exists: true});
        emit UrlElementUpdated(_url, _element);
    }

    function addUrl(string memory _url) public onlyOwner {
        if (!urlElementStore[_url].exists) {
            urlList.push(_url);
        }
        urlElementStore[_url] = UrlElement({element: "", exists: true});
        emit UrlElementUpdated(_url, "");
    }

    function getUrlElement(string memory _url) public view returns (string memory) {
        UrlElement memory urlElement = urlElementStore[_url];
        require(urlElement.exists, "URL element does not exist");
        return urlElement.element;
    }

    function getAllUrls() public view returns (string[] memory) {
        return urlList;
    }

    function getAllUrlElements() public view returns (string[] memory, string[] memory) {
        uint256 count = urlList.length;
        string[] memory urls = new string[](count);
        string[] memory elements = new string[](count);

        for (uint256 i = 0; i < count; i++) {
            urls[i] = urlList[i];
            elements[i] = urlElementStore[urlList[i]].element;
        }

        return (urls, elements);
    }
}
