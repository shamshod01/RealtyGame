const Realty = artifacts.require("Realty");

module.exports = function(deployer) {
  deployer.deploy(Realty);
};
