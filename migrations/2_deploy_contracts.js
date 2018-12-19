var Leilao = artifacts.require("./Leilao.sol");

module.exports = function(deployer) {
  //deployer.deploy(ConvertLib);
  //deployer.link(ConvertLib, Leilao);
  deployer.deploy(Leilao, 0x00c89fb22768128f06b779048ed482bb876628d9,10);
};
