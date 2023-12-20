const { upgrades } = require("hardhat");
const hre = require("hardhat");
require('dotenv').config()

const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

const { BN } = require("@openzeppelin/test-helpers");

let walletAddress = process.env.WALLET_ADDRESS

async function main() {
    const piNFT = await hre.ethers.getContractFactory("piNFT")

    const pi = await upgrades.deployProxy(piNFT, ["Aconomy", "ACO", "0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d"], {
        initializer: "initialize",
        kind: "uups"
      })

      console.log("piNFT: ", await pi.getAddress());


  const mintToken = await hre.ethers.deployContract("mintToken", ["100000000000"]);
  let token = await mintToken.waitForDeployment();

  await token.approve(pi.getAddress(), 500);
  let exp = new BN(await time.latest()).add(new BN(7500));

      let x = await pi.mintValidatedNFT("0xf69F75EB0c72171AfF58D79973819B6A3038f39f", "URI1", token.getAddress(), 500, exp.toString(), 500, [["0xf69F75EB0c72171AfF58D79973819B6A3038f39f", 500]])
      const bal = await pi.balanceOf("0xf69F75EB0c72171AfF58D79973819B6A3038f39f");
        console.log("piNFT: ", bal.toString());
    //   expect(bal).to.equal(1);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });