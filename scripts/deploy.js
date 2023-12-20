const { upgrades } = require("hardhat");
const hre = require("hardhat");
require('dotenv').config()

let walletAddress = process.env.WALLET_ADDRESS

async function main() {
    const piNFT = await hre.ethers.getContractFactory("piNFT")

    const pi = await upgrades.deployProxy(piNFT, ["Aconomy", "ACO", "0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d"], {
        initializer: "initialize",
        kind: "uups"
      })

      console.log("piNFT: ", await pi.getAddress());

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });