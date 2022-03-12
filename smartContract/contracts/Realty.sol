// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Realty is ERC721Enumerable, Ownable {
    using Strings for uint256;

    mapping(uint256 => Door) public doors;
    mapping(uint256 => Window) public windows;
    mapping(uint256 => House) public houses;
    mapping(address => uint256[]) public ownedDoors;
    mapping(address => uint256[]) public ownedWindows;
    mapping(address => uint256[]) public ownedHouses;


    enum Size { SMALL, MEDIUM, LARGE }

    struct Door {
        uint8 level;
        string color;
        uint256 houseTokenId;
    }
    struct Window {
        Size size;
        string color;
        uint256 houseTokenId;
    }
    struct House {
        Door door;
        Window window;
        uint8 number;
        uint256 windowURI;
        uint256 doorURI;
    }

    Window public defaultWindow = Window(Size.SMALL, "white", 0);
    Door public defaultDoor = Door(1, "blue", 0);


    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
    }

    /*╔═════════════════════════════╗
      ║       PUBLIC FUNCTIONS      ║
      ╚═════════════════════════════╝*/

    function addHouse() public payable {
        uint256 supply = totalSupply();
        _safeMint(msg.sender, supply + 1);
        houses[supply+1] = House(defaultDoor, defaultWindow, 1, 0, 0);
        ownedHouses[msg.sender].push(supply+1);
    }
    // TODO: handle transferring details of house, house should have default details after selling

    function assignWindowToHouse(uint256 houseTokenId, uint256 windowTokenId) public payable {
        require(ownerOf(houseTokenId) == msg.sender, "only owner can add");
        require(ownerOf(windowTokenId) == msg.sender, "only owner can add");
        houses[houseTokenId].window = windows[windowTokenId];
        houses[houseTokenId].windowURI = windowTokenId;
        windows[windowTokenId].houseTokenId = houseTokenId;
    }

    function removeWindowFromHouse(uint256 houseTokenId, uint256 windowTokenId) public payable {
        require(ownerOf(houseTokenId) == msg.sender, "only owner can add");
        require(ownerOf(windowTokenId) == msg.sender, "only owner can add");
        houses[houseTokenId].window = defaultWindow;
        houses[houseTokenId].windowURI = 0;
        windows[windowTokenId].houseTokenId = 0;
    }

    function upgradeWindow(uint256 houseTokenId) public payable {
        require(ownerOf(houseTokenId) == msg.sender, "only owner can upgrade");
        uint256 supply = totalSupply();
        Size currentSize = houses[houseTokenId].window.size;
        if(currentSize == Size.SMALL) {
            _safeMint(msg.sender, supply + 1);
            windows[supply + 1] = Window(Size.MEDIUM, "blue", houseTokenId);
            houses[houseTokenId].window = windows[supply + 1];
            houses[houseTokenId].windowURI = supply + 1;
            ownedWindows[msg.sender].push(supply+1);
        }else if(currentSize == Size.MEDIUM){
            windows[houses[houseTokenId].windowURI] = Window(Size.LARGE, "grey", houseTokenId);
            houses[houseTokenId].window = windows[houses[houseTokenId].windowURI];
        }else if(currentSize == Size.LARGE){
            windows[houses[houseTokenId].windowURI]  = Window(Size.LARGE, "black", houseTokenId);
            houses[houseTokenId].window = windows[houses[houseTokenId].windowURI];
        }
    }

    function upgradeDoor(uint256 houseTokenId) public payable {
        uint256 supply = totalSupply();
        uint8 currentLevel = houses[houseTokenId].door.level;
        if( currentLevel == 1) {
            _safeMint(msg.sender, supply + 1);
            doors[supply + 1] = Door(2, "grey", houseTokenId);
            houses[houseTokenId].door = doors[supply + 1];
            houses[houseTokenId].doorURI = supply + 1;
            ownedDoors[msg.sender].push(supply+1);
        }else {
            doors[houses[houseTokenId].doorURI] = Door(currentLevel+1, "black", houseTokenId);
            houses[houseTokenId].door = doors[houses[houseTokenId].doorURI];
        }
    }


    /*╔═════════════════════════════╗
      ║       VIEW FUNCTIONS        ║
      ╚═════════════════════════════╝*/

    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }


    /*╔═════════════════════════════╗
      ║     ONLY OWNER FUNCTIONS    ║
      ╚═════════════════════════════╝*/

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

}