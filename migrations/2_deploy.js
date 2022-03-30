// migrations/2_deploy.js
// SPDX-License-Identifier: MIT

const SS = artifacts.require("SubdomainStore.sol");

module.exports = async function(deployer) {
  await deployer.deploy(SS);
};