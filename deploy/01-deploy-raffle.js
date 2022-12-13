const { network, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../helper-hardhat-config")

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId
  //const args = [BASE_FEE, GAS_PRICE_LINK]
  let vrfCoordinatorV2Address
  if (developmentChains.includes(network.name)) {
    //for development network i.e local blockchain
    const vrfCoordinatorV2Mock = await ethers.getContract(
      "VRFCoordinatorV2Mock"
    )
    vrfCoordinatorV2Address = vrfCoordinatorV2Mock.address
  } else {
    //for testnet
    vrfCoordinatorV2Address = networkConfig[chainId]["vrfCoordinatorV2"]
  }

  const entranceFee = networkConfig[chainId]["entranceFee"]
  const args = [vrfCoordinatorV2Address, entranceFee] // args for contructor in solidity smart contract
  const raffle = await deploy("Raffle", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmation: network.config.blockConfirmation || 1,
  })
}
