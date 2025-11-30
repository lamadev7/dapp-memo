// migrations/2_deploy_contracts.js

const Auth = artifacts.require("Auth");
const Voter = artifacts.require("Voter");
const Party = artifacts.require("Party");
const Candidate = artifacts.require("Candidate");

module.exports = async function (deployer, network, accounts) {
  
  console.log("Deploying from account:", accounts[0]);
  
  console.log("\n1. Deploying Auth...");
  await deployer.deploy(Auth);
  const authInstance = await Auth.deployed();
  console.log("✓ Auth deployed at:", authInstance.address);
  
  console.log("\n1. Deploying Voter...");
  await deployer.deploy(Voter);
  const voterInstance = await Voter.deployed();
  console.log("✓ Voter deployed at:", voterInstance.address);
  
  console.log("\n2. Deploying Party...");
  await deployer.deploy(Party);
  const partyInstance = await Party.deployed();
  console.log("✓ Party deployed at:", partyInstance.address);
  
  console.log("\n3. Deploying Candidate...");
  await deployer.deploy(Candidate);
  const candidateInstance = await Candidate.deployed();
  console.log("✓ Candidate deployed at:", candidateInstance.address);
  
  console.log("\n✅ All contracts deployed successfully!");
  console.log("\nContract Addresses:");
  console.log("===================");
  console.log("Voter:     ", voterInstance.address);
  console.log("Party:     ", partyInstance.address);
  console.log("Candidate: ", candidateInstance.address);
  console.log("===================\n");
};