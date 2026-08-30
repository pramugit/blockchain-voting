const { expect } = require("chai");
const { ethers } = require("hardhat");

async function chainNow() {
  const block = await ethers.provider.getBlock("latest");
  return block.timestamp;
}

describe("VoteChain", function () {
  let vote, organiser, alice, bob, outsider;

  beforeEach(async function () {
    [organiser, alice, bob, outsider] = await ethers.getSigners();
    const VoteChain = await ethers.getContractFactory("VoteChain");
    vote = await VoteChain.deploy();
    await vote.waitForDeployment();

    const now = await chainNow();
    await vote.createElection("Class Rep", ["Alice", "Bob"], now, now + 3600);
    await vote.registerVoter(0, alice.address);
  });

  it("lets an eligible voter cast a vote", async function () {
    await vote.connect(alice).castVote(0, 0);
    const [, counts] = await vote.getResults(0);
    expect(counts[0]).to.equal(1);
  });

  it("rejects a vote from an unregistered address", async function () {
    await expect(vote.connect(outsider).castVote(0, 0)).to.be.revertedWith(
      "not eligible"
    );
  });

  it("rejects a second castVote from the same address", async function () {
    await vote.connect(alice).castVote(0, 0);
    await expect(vote.connect(alice).castVote(0, 1)).to.be.revertedWith(
      "already voted, use changeVote"
    );
  });

  it("moves the tally correctly on changeVote", async function () {
    await vote.connect(alice).castVote(0, 0);
    await vote.connect(alice).changeVote(0, 1);
    const [, counts] = await vote.getResults(0);
    expect(counts[0]).to.equal(0);
    expect(counts[1]).to.equal(1);
  });

  it("rejects changeVote from someone who hasn't voted yet", async function () {
    await vote.registerVoter(0, bob.address);
    await expect(vote.connect(bob).changeVote(0, 0)).to.be.revertedWith(
      "no existing vote"
    );
  });

  it("blocks a non-organiser from creating an election", async function () {
    await expect(
      vote.connect(alice).createElection("Rogue", ["X", "Y"], 0, 1)
    ).to.be.revertedWith("not organiser");
  });

  it("blocks a non-organiser from registering voters", async function () {
    await expect(
      vote.connect(alice).registerVoter(0, bob.address)
    ).to.be.revertedWith("not organiser");
  });

  it("keeps two elections' tallies fully independent", async function () {
    const now = await chainNow();
    await vote.createElection("Colour Poll", ["Red", "Blue"], now, now + 3600);
    await vote.registerVoter(1, alice.address);

    await vote.connect(alice).castVote(0, 0); // votes Alice in election 0
    await vote.connect(alice).castVote(1, 1); // votes Blue in election 1

    const [, counts0] = await vote.getResults(0);
    const [, counts1] = await vote.getResults(1);
    expect(counts0[0]).to.equal(1);
    expect(counts0[1]).to.equal(0);
    expect(counts1[0]).to.equal(0);
    expect(counts1[1]).to.equal(1);
  });

  it("rejects voting after the election deadline has passed", async function () {
    const now = await chainNow();
    await vote.createElection("Quick Poll", ["Yes", "No"], now, now + 2);
    await vote.registerVoter(1, alice.address);

    await ethers.provider.send("evm_increaseTime", [10]);
    await ethers.provider.send("evm_mine");

    await expect(vote.connect(alice).castVote(1, 0)).to.be.revertedWith(
      "voting closed"
    );
  });
});
