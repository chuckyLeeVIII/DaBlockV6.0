const hre = require("hardhat");

async function main() {
  const MemeToken = await hre.ethers.getContractFactory("MemeToken");
  const memeToken = await MemeToken.deploy("FamilyMeme", "FMEME");
  await memeToken.deployed();
  console.log("MemeToken deployed to:", memeToken.address);

  const FamilyCryptoSystem = await hre.ethers.getContractFactory("FamilyCryptoSystem");
  const familyCryptoSystem = await FamilyCryptoSystem.deploy(memeToken.address);
  await familyCryptoSystem.deployed();
  console.log("FamilyCryptoSystem deployed to:", familyCryptoSystem.address);

  await memeToken.setFamilyCryptoSystem(familyCryptoSystem.address);
  console.log("MemeToken FamilyCryptoSystem address set");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });