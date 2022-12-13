const { network, ethers } = require("hardhat")
const { developmentChains } = require("../helper-hardhat-config")

const BASE_FEE = ethers.utils.parseEther("0.25") // 0.25 is the preminum. It costs 0.25 per requests
const GAS_PRICE_LINK = 1e9 //calculated value based on the price of the chain
module.exports = async function ({ getNamedAccounts, deployment }) {
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()
  const args = [BASE_FEE, GAS_PRICE_LINK]
  const chainId = network.config.chainId
  if (developmentChains.includes(network.name)) {
    log("local Network detected! Deploying mocks................")
    //deploy mock coordinator

    await deploy("VRFCoordinatorV2Mock", {
      from: deployer,
      log: true,
      args: args,
    })
    log("mock deployed..........................")
  }
}

module.exports.tags = ["all", "mocks"]
