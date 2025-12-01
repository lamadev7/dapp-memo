const Auth = artifacts.require("Auth");
const Voter = artifacts.require("Voter");
const Party = artifacts.require("Party");
const Candidate = artifacts.require("Candidate");
const ElectionManager = artifacts.require("ElectionManager");

module.exports = async function (deployer, network, accounts) {
  
  console.log("Deploying from account:", accounts[0]);
  
  // Step 0: Deploy Auth
  console.log("\n0. Deploying Auth...");
  await deployer.deploy(Auth);
  const authInstance = await Auth.deployed();
  console.log("✓ Auth deployed at:", authInstance.address);
  
  // Step 1: Deploy Voter
  console.log("\n1. Deploying Voter...");
  await deployer.deploy(Voter);
  const voterInstance = await Voter.deployed();
  console.log("✓ Voter deployed at:", voterInstance.address);
  
  // Step 2: Deploy Party
  console.log("\n2. Deploying Party...");
  await deployer.deploy(Party);
  const partyInstance = await Party.deployed();
  console.log("✓ Party deployed at:", partyInstance.address);
  
  // Step 3: Deploy Candidate
  console.log("\n3. Deploying Candidate...");
  await deployer.deploy(Candidate);
  const candidateInstance = await Candidate.deployed();
  console.log("✓ Candidate deployed at:", candidateInstance.address);
  
  // Step 4: Deploy ElectionManager with constructor parameters
  console.log("\n4. Deploying ElectionManager...");
  await deployer.deploy(
    ElectionManager,
    candidateInstance.address,  // _candidateContract
    voterInstance.address,      // _voterContract
    partyInstance.address       // _partyContract
  );
  const electionInstance = await ElectionManager.deployed();
  console.log("✓ ElectionManager deployed at:", electionInstance.address);
  
  // Step 5: Grant ADMIN_ROLE to ElectionManager in all contracts
  console.log("\n5. Setting up permissions...");
  
  const ADMIN_ROLE = await candidateInstance.ADMIN_ROLE();
  
  console.log("   - Granting ADMIN_ROLE to ElectionManager in Candidate...");
  await candidateInstance.grantRole(ADMIN_ROLE, electionInstance.address);
  console.log("   ✓ Done");
  
  console.log("   - Granting ADMIN_ROLE to ElectionManager in Voter...");
  await voterInstance.grantRole(ADMIN_ROLE, electionInstance.address);
  console.log("   ✓ Done");
  
  console.log("   - Granting ADMIN_ROLE to ElectionManager in Party...");
  await partyInstance.grantRole(ADMIN_ROLE, electionInstance.address);
  console.log("   ✓ Done");
  
  console.log("\n✅ All contracts deployed successfully!");
  console.log("\n📋 Contract Addresses:");
  console.log("===================");
  console.log("Auth:            ", authInstance.address);
  console.log("Voter:           ", voterInstance.address);
  console.log("Party:           ", partyInstance.address);
  console.log("Candidate:       ", candidateInstance.address);
  console.log("ElectionManager: ", electionInstance.address);
  console.log("===================\n");
  
  console.log("💡 Deployer account has ADMIN_ROLE in all contracts");
  console.log("💡 ElectionManager can call incrementVoteCount() on Voter and Candidate");
};