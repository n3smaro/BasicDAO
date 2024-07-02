const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("BasicDAO", function () {
    let dao;
    let owner;
    let member1;
    let member2;
    let nonMember;
    let membershipFee;

    beforeEach(async function () {
        [owner, member1, member2, nonMember] = await ethers.getSigners();
        const BasicDAO = await ethers.getContractFactory("BasicDAO");
        membershipFee = ethers.parseEther("1"); // 1 ETH membership fee
        dao = await BasicDAO.deploy(membershipFee);
    });

    describe("Membership", function () {
        it("should allow users to join the DAO with the correct membership fee", async function () {
            await expect(() => dao.connect(member1).joinDAO({ value: membershipFee }))
                .to.changeEtherBalances([member1, dao], [-membershipFee, membershipFee]);

            expect(await dao.isMember(member1.address)).to.be.true;
            const members = await dao.getMembers();
            expect(members).to.include(member1.address);
        });

        it("should not allow users to join without paying the correct membership fee", async function () {
            await expect(dao.connect(nonMember).joinDAO({ value: ethers.parseUnits("1", "wei") })).to.be.revertedWith("Incorrect membership fee");
        });

        it("should not allow a user to join twice", async function () {
            await dao.connect(member1).joinDAO({ value: membershipFee });
            await expect(dao.connect(member1).joinDAO({ value: membershipFee })).to.be.revertedWith("Already a member");
        });
    });

    describe("Proposal Creation", function () {
        beforeEach(async function () {
            await dao.connect(member1).joinDAO({ value: membershipFee });
        });

        it("should allow members to create a proposal", async function () {
            await expect(dao.connect(member1).createProposal("Test Proposal", (await ethers.provider.getBlock("latest")).timestamp + 3600))
                .to.emit(dao, "ProposalCreated")
                .withArgs(0, "Test Proposal", (await ethers.provider.getBlock("latest")).timestamp + 3600);

            const proposals = await dao.getProposals();
            expect(proposals.length).to.equal(1);
            expect(proposals[0].description).to.equal("Test Proposal");
            expect(proposals[0].votesFor).to.equal(0);
            expect(proposals[0].votesAgainst).to.equal(0);
            expect(proposals[0].executed).to.be.false;
        });

        it("should not allow members to create proposals with past deadlines", async function () {
            await expect(dao.connect(member1).createProposal("Test Proposal", (await ethers.provider.getBlock("latest")).timestamp - 3600))
                .to.be.revertedWith("Deadline must be in the future");
        });
    });

    describe("Voting", function () {
        beforeEach(async function () {
            await dao.connect(member1).joinDAO({ value: membershipFee });
            await dao.connect(member2).joinDAO({ value: membershipFee });
            await dao.connect(member1).createProposal("Test Proposal", (await ethers.provider.getBlock("latest")).timestamp + 3600);
        });

        it("should allow members to vote on proposals", async function () {
            await expect(dao.connect(member1).vote(0, true))
                .to.emit(dao, "Voted")
                .withArgs(member1.address, 0, true);

            const proposal = (await dao.getProposals())[0];
            expect(proposal.votesFor).to.equal(1);
            expect(proposal.votesAgainst).to.equal(0);
        });

        it("should not allow members to vote multiple times on the same proposal", async function () {
            await dao.connect(member1).vote(0, true);
            await expect(dao.connect(member1).vote(0, false)).to.be.revertedWith("You have already voted on this proposal");
        });

        it("should not allow voting after the deadline has passed", async function () {
            await ethers.provider.send("evm_increaseTime", [3601]); // Increase time by 3601 seconds
            await ethers.provider.send("evm_mine");
            await expect(dao.connect(member1).vote(0, true)).to.be.revertedWith("Voting period has ended");
        });
    });

    describe("Proposal Execution", function () {
        beforeEach(async function () {
            await dao.connect(member1).joinDAO({ value: membershipFee });
            await dao.connect(member2).joinDAO({ value: membershipFee });
            await dao.connect(member1).createProposal("Test Proposal", (await ethers.provider.getBlock("latest")).timestamp + 3600);
            await dao.connect(member1).vote(0, true);
            await dao.connect(member2).vote(0, false);
            await ethers.provider.send("evm_increaseTime", [3601]); // Increase time by 3601 seconds
            await ethers.provider.send("evm_mine");
        });

        it("should allow the owner to execute a proposal", async function () {
            await expect(dao.connect(owner).executeProposal(0))
                .to.emit(dao, "ProposalExecuted")
                .withArgs(0, false);

            const proposal = (await dao.getProposals())[0];
            expect(proposal.executed).to.be.true;
        });

        it("should not allow non-owners to execute a proposal", async function () {
            await expect(dao.connect(member1).executeProposal(0)).to.be.revertedWith("Not the contract owner");
        });


        it("should not allow a proposal to be executed twice", async function () {
            await dao.connect(owner).executeProposal(0);
            await expect(dao.connect(owner).executeProposal(0)).to.be.revertedWith("Proposal already executed");
        });
    });

    describe("Getters", function () {
        beforeEach(async function () {
            await dao.connect(member1).joinDAO({ value: membershipFee });
            await dao.connect(member2).joinDAO({ value: membershipFee });
            await dao.connect(member1).createProposal("Test Proposal", (await ethers.provider.getBlock("latest")).timestamp + 3600);
        });

        it("should return the correct membership fee", async function () {
            expect(await dao.getMembershipFee()).to.equal(membershipFee);
        });

        it("should return the correct members list", async function () {
            const members = await dao.getMembers();
            expect(members).to.include(member1.address);
            expect(members).to.include(member2.address);
        });

        it("should return the correct proposals list", async function () {
            const proposals = await dao.getProposals();
            expect(proposals.length).to.equal(1);
            expect(proposals[0].description).to.equal("Test Proposal");
        });
    });
});
