const hre = require("hardhat");

async function main() {
  const VoteChain = await hre.ethers.getContractFactory("VoteChain");
  const vote = await VoteChain.deploy();
  await vote.waitForDeployment();

  const address = await vote.getAddress();
  console.log("VoteChain deployed to:", address);
  console.log("\nNext steps:");
  console.log("1. Save this address — you'll need it for the frontend and for verification.");
  console.log(
    `2. Verify it:  npx hardhat verify --network sepolia ${address}`
  );
  console.log(
    "3. Paste the address into frontend/index.html (CONTRACT_ADDRESS constant)."
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
