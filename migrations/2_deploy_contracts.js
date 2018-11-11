var Leilao = artifacts.require("./Leilao.sol");

module.exports = function(deployer) {
  //deployer.deploy(ConvertLib);
  //deployer.link(ConvertLib, Leilao);
  deployer.deploy(Leilao, 0x00c89FB22768128f06b779048ed482Bb876628D9,10);
};
