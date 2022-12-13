const { network } = require("hardhat")

module.exports = async function ({ getNamedAccounts, deployment }) {
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId
}
