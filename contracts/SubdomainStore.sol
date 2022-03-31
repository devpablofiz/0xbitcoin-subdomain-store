// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./ENS.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev A basic interface for ENS resolvers.
 */
interface Resolver {
  function supportsInterface(bytes4 interfaceID) external pure returns (bool);
  function addr(bytes32 node) external view returns (address);
  function setAddr(bytes32 node, address addr) external;
}

abstract contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}

contract SubdomainStore is IERC721Receiver, Ownable, ApproveAndCallFallBack {

  struct Domain {
    string name;
    uint price;
  }

  bytes32 constant internal TLD_NODE = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;
  address internal xbtc = 0x244aA29426fb6524760bD9AcbB66ad53C5EB32CA;
  ENS internal ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
  
  mapping (bytes32 => Domain) internal domains;
  
  constructor() {
    
  }
  
  /**
   * @dev Configures a domain for sale.
   * @param name The name to configure.
   * @param price The price in wei to charge for subdomain registrations
   */
  function configureDomain(string memory name, uint price) public onlyOwner {
    bytes32 label = keccak256(bytes(name));
    Domain storage domain = domains[label];

    if (keccak256(abi.encodePacked(domain.name)) != label) {
      // New listing
      domain.name = name;
    }

    domain.price = price;
  }

  function setResolver(string memory name, address resolver) public onlyOwner {
    bytes32 label = keccak256(bytes(name));
    bytes32 node = keccak256(abi.encodePacked(TLD_NODE, label));
    ens.setResolver(node, resolver);
  }
  
  function doRegistration(bytes32 node, bytes32 label, address subdomainOwner, Resolver resolver) internal {
    ens.setSubnodeRecord(node, label, subdomainOwner, address(resolver), 0);
  }

  /**
   * @dev Registers a subdomain.
   * @param label The label hash of the domain to register a subdomain of.
   * @param subdomain The desired subdomain label.
   * @param subdomainOwner The account that should own the newly configured subdomain.
   */
  function register(bytes32 label, string memory subdomain, address subdomainOwner, address resolver) public {
    bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, label));

    bytes32 subdomainLabel = keccak256(bytes(subdomain));

    // Subdomain must not be registered already.
    require(ens.owner(keccak256(abi.encodePacked(domainNode, subdomainLabel))) == address(0), "Subdomain must not be registered already");
    Domain storage domain = domains[label];

    // Domain must be available for registration
    require(keccak256(abi.encodePacked(domain.name)) == label, "Domain must be available for registration");

    // The account that gets the subdomain also needs to pay
    require(IERC20(xbtc).transferFrom(subdomainOwner, address(this), domain.price), "User must have paid");

    doRegistration(domainNode, subdomainLabel, subdomainOwner, Resolver(resolver));
  }

  function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function receiveApproval(address from, uint256, address token, bytes memory data) public override {
    require(token == xbtc, "Must pay in 0xBTC");

    bytes32 label; 
    string memory subdomain;
    address resolver;

    (label, subdomain, resolver) = abi.decode(data, (bytes32, string, address));

    register(label, subdomain, from, resolver);
  }

  //Helper function to encode the data needed for ApproveAndCall
  function encodeData(bytes32 label, string calldata subdomain, address resolver) external pure returns (bytes memory data) {
    return abi.encode(label, subdomain, resolver);
  }

  //Helper function to get the label hash
  function encodeLabel(string calldata label) external pure returns (bytes32 encodedLabel) {
    return keccak256(bytes(label));
  }

  function getPrice (bytes32 label) external view returns (uint256 price){
    Domain storage data = domains[label];
    return data.price;
  }

}
