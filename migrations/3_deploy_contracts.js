var Auction = artifacts.require("./Auction.sol");

module.exports = function(deployer) {
  //deployer.deploy(ConvertLib);
  //deployer.link(ConvertLib, Leilao);
  deployer.deploy(Auction);
};
